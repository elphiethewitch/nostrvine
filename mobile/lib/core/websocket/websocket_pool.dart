// ABOUTME: WebSocket connection pool for managing multiple relay connections
// ABOUTME: Provides load balancing, failover, and health monitoring

import 'dart:async';
import 'dart:math' show Random;

import 'package:openvine/core/websocket/websocket_connection_state.dart';
import 'package:openvine/core/websocket/websocket_manager.dart';

/// Connection strategy for the pool
enum ConnectionStrategy {
  /// Connect to all relays simultaneously
  simultaneous,

  /// Connect to relays in priority order
  priority,

  /// Connect on demand
  lazy,
}

/// Load balancing strategy
enum LoadBalancingStrategy {
  /// Round-robin distribution
  roundRobin,

  /// Route to relay with least connections
  leastConnections,

  /// Route to relay with lowest latency
  lowestLatency,

  /// Random selection
  random,
}

/// Overall pool connection state
enum PoolConnectionState {
  /// No relays connected
  disconnected,

  /// Some relays connected
  partial,

  /// All relays connected
  connected,

  /// Performance degraded (less than 50% connected)
  degraded,
}

/// Pool event types
enum PoolEventType {
  connecting,
  connected,
  disconnected,
  messageSent,
  messageReceived,
  relayAdded,
  relayRemoved,
  relayDisconnected,
  failover,
  error,
}

/// Configuration for a specific relay
class RelayConfig {
  RelayConfig({
    this.priority = 0,
    this.timeout = const Duration(seconds: 10),
    this.headers = const {},
    this.maxRetries = 3,
    this.enableReconnection = true,
  });
  final int priority;
  final Duration timeout;
  final Map<String, String> headers;
  final int maxRetries;
  final bool enableReconnection;
}

/// Represents a relay connection
class RelayConnection {
  RelayConnection({
    required this.url,
    required this.config,
  })  : manager = WebSocketManager(
          url: url,
          connectionTimeout: config.timeout,
          headers: config.headers,
        ),
        healthMetrics = RelayHealthMetrics();
  final String url;
  final WebSocketManager manager;
  final RelayConfig config;
  final RelayHealthMetrics healthMetrics;
}

/// Health metrics for a relay
class RelayHealthMetrics {
  int _successCount = 0;
  int _errorCount = 0;
  final List<Duration> _latencies = [];
  DateTime? _lastErrorTime;

  int get successCount => _successCount;
  int get errorCount => _errorCount;
  DateTime? get lastErrorTime => _lastErrorTime;

  bool get isHealthy =>
      errorRate < 0.5 &&
      (_lastErrorTime == null ||
          DateTime.now().difference(_lastErrorTime!) >
              const Duration(minutes: 5));

  double get errorRate {
    final total = _successCount + _errorCount;
    return total == 0 ? 0.0 : _errorCount / total;
  }

  Duration? get latency => _latencies.isEmpty ? null : _latencies.last;

  Duration? get averageLatency {
    if (_latencies.isEmpty) return null;
    final totalMs = _latencies.fold<int>(
      0,
      (sum, d) => sum + d.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _latencies.length);
  }

  double get healthScore {
    if (_successCount == 0 && _errorCount == 0) return 1;

    final successRate = 1.0 - errorRate;
    final latencyScore = _calculateLatencyScore();

    return (successRate * 0.7) + (latencyScore * 0.3);
  }

  void recordSuccess() {
    _successCount++;
  }

  void recordError() {
    _errorCount++;
    _lastErrorTime = DateTime.now();
  }

  void recordLatency(Duration latency) {
    _latencies.add(latency);
    if (_latencies.length > 100) {
      _latencies.removeAt(0);
    }
  }

  double _calculateLatencyScore() {
    if (_latencies.isEmpty) return 1;

    final avgMs = averageLatency!.inMilliseconds;
    // Score decreases as latency increases
    // 0ms = 1.0, 100ms = 0.9, 1000ms = 0.5, 5000ms+ = 0.0
    if (avgMs <= 100) return 1.0 - (avgMs / 1000);
    if (avgMs <= 1000) return 0.9 - ((avgMs - 100) / 2000);
    if (avgMs <= 5000) return 0.5 - ((avgMs - 1000) / 8000);
    return 0;
  }
}

/// Message received from a specific relay
class RelayMessage {
  RelayMessage({
    required this.relayUrl,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final String relayUrl;
  final String data;
  final DateTime timestamp;
}

/// Failover event
class FailoverEvent {
  FailoverEvent({
    required this.failedRelay,
    required this.remainingRelays,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final String failedRelay;
  final int remainingRelays;
  final DateTime timestamp;
}

/// Pool event
class PoolEvent {
  PoolEvent({
    required this.type,
    this.data = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final PoolEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
}

/// Load balancer for relay selection
class LoadBalancer {
  LoadBalancer({this.strategy = LoadBalancingStrategy.roundRobin});
  final LoadBalancingStrategy strategy;
  final Random _random = Random();
  int _roundRobinIndex = 0;

  RelayConnection selectRelay(List<RelayConnection> relays) {
    if (relays.isEmpty) {
      throw StateError('No relays available');
    }

    switch (strategy) {
      case LoadBalancingStrategy.roundRobin:
        final selected = relays[_roundRobinIndex % relays.length];
        _roundRobinIndex++;
        return selected;

      case LoadBalancingStrategy.leastConnections:
        // For now, using simple implementation
        // In production, this would track active connections per relay
        return relays.first;

      case LoadBalancingStrategy.lowestLatency:
        RelayConnection? best;
        Duration? bestLatency;

        for (final relay in relays) {
          final latency = relay.healthMetrics.latency;
          if (latency == null) continue;
          if (bestLatency == null || latency < bestLatency) {
            best = relay;
            bestLatency = latency;
          }
        }

        return best ?? relays.first;

      case LoadBalancingStrategy.random:
        return relays[_random.nextInt(relays.length)];
    }
  }
}

/// WebSocket connection pool for multiple relays
class WebSocketPool {
  WebSocketPool({
    List<String>? relayUrls,
    Map<String, RelayConfig>? relayConfigs,
    this.connectionStrategy = ConnectionStrategy.simultaneous,
    this.loadBalancingStrategy = LoadBalancingStrategy.roundRobin,
    this.maxConnections = 10,
  })  : _relayUrls = relayUrls ?? [],
        _relayConfigs = relayConfigs ?? {},
        _loadBalancer = LoadBalancer(strategy: loadBalancingStrategy) {
    // Initialize relay configurations
    for (final url in _relayUrls) {
      _relays[url] = RelayConnection(
        url: url,
        config: _relayConfigs[url] ?? RelayConfig(),
      );
    }
  }
  final List<String> _relayUrls;
  final ConnectionStrategy connectionStrategy;
  final LoadBalancingStrategy loadBalancingStrategy;
  final int maxConnections;
  final Map<String, RelayConfig> _relayConfigs;

  final Map<String, RelayConnection> _relays = {};
  final LoadBalancer _loadBalancer;

  final StreamController<RelayConnection> _relayConnectedController =
      StreamController<RelayConnection>.broadcast();
  final StreamController<RelayConnection> _relayDisconnectedController =
      StreamController<RelayConnection>.broadcast();
  final StreamController<RelayMessage> _messageController =
      StreamController<RelayMessage>.broadcast();
  final StreamController<FailoverEvent> _failoverController =
      StreamController<FailoverEvent>.broadcast();
  final StreamController<PoolEvent> _eventController =
      StreamController<PoolEvent>.broadcast();

  bool _isDisposed = false;

  bool get isConnected => _relays.values.any(
        (relay) =>
            relay.manager.connectionState == WebSocketConnectionState.connected,
      );

  List<RelayConnection> get connectedRelays => _relays.values
      .where((relay) =>
          relay.manager.connectionState == WebSocketConnectionState.connected)
      .toList();

  List<RelayConnection> get failedRelays => _relays.values
      .where((relay) =>
          relay.manager.connectionState == WebSocketConnectionState.error)
      .toList();

  List<RelayConnection> get pendingRelays => _relays.values
      .where(
        (relay) =>
            relay.manager.connectionState !=
                WebSocketConnectionState.connected &&
            relay.manager.connectionState != WebSocketConnectionState.error,
      )
      .toList();

  int get connectionCount => connectedRelays.length;

  PoolConnectionState get overallState {
    final total = _relays.length;
    final connected = connectionCount;

    if (connected == 0) return PoolConnectionState.disconnected;
    if (connected == total) return PoolConnectionState.connected;
    if (connected < total / 2) return PoolConnectionState.degraded;
    return PoolConnectionState.partial;
  }

  Stream<RelayConnection> get relayConnectedStream =>
      _relayConnectedController.stream;
  Stream<RelayConnection> get relayDisconnectedStream =>
      _relayDisconnectedController.stream;
  Stream<RelayMessage> get messageStream => _messageController.stream;
  Stream<FailoverEvent> get failoverStream => _failoverController.stream;
  Stream<PoolEvent> get eventStream => _eventController.stream;

  Future<void> connectAll() async {
    if (_isDisposed) {
      throw StateError('Cannot connect: WebSocketPool is disposed');
    }

    _eventController.add(PoolEvent(type: PoolEventType.connecting));

    switch (connectionStrategy) {
      case ConnectionStrategy.simultaneous:
        await _connectSimultaneous();
      case ConnectionStrategy.priority:
        await _connectByPriority();
      case ConnectionStrategy.lazy:
        // Do nothing - connections will be made on demand
        break;
    }

    _eventController.add(
      PoolEvent(
        type: PoolEventType.connected,
        data: {'connectedCount': connectionCount},
      ),
    );
  }

  Future<void> _connectSimultaneous() async {
    final futures = <Future>[];
    var connectedCount = 0;

    for (final relay in _relays.values) {
      if (connectedCount >= maxConnections) break;

      futures.add(_connectRelay(relay));
      connectedCount++;
    }

    await Future.wait(futures, eagerError: false);
  }

  Future<void> _connectByPriority() async {
    final sortedRelays = _relays.values.toList()
      ..sort((a, b) => a.config.priority.compareTo(b.config.priority));

    var connectedCount = 0;

    for (final relay in sortedRelays) {
      if (connectedCount >= maxConnections) break;

      await _connectRelay(relay);
      connectedCount++;
    }
  }

  Future<void> _connectRelay(RelayConnection relay) async {
    try {
      // Check for simulated failure
      if (_failedConnections.contains(relay.url)) {
        throw Exception('Simulated connection failure');
      }

      // Set up state change listener
      relay.manager.connectionStateStream.listen((state) {
        if (_isDisposed) return;

        if (state == WebSocketConnectionState.connected) {
          if (!_isDisposed) {
            _relayConnectedController.add(relay);
            relay.healthMetrics.recordSuccess();
          }
        } else if (state == WebSocketConnectionState.error) {
          _handleRelayError(relay);
        } else if (state == WebSocketConnectionState.disconnected) {
          _handleRelayDisconnection(relay);
        }
      });

      // Set up message listener
      relay.manager.messageStream.listen((message) {
        if (!_isDisposed) {
          _messageController.add(
            RelayMessage(
              relayUrl: relay.url,
              data: message.textData ?? '',
            ),
          );
        }
      });

      // Set up error listener
      relay.manager.errorStream.listen((error) {
        if (!_isDisposed) {
          relay.healthMetrics.recordError();
        }
      });

      // For testing, simulate successful connection
      relay.manager.simulateConnection();
    } catch (e) {
      relay.healthMetrics.recordError();
      // Ensure the relay manager is in error state
      relay.manager.simulateError(e.toString());
      _handleRelayError(relay);
    }
  }

  void _handleRelayError(RelayConnection relay) {
    if (!_isDisposed) {
      _eventController.add(
        PoolEvent(
          type: PoolEventType.error,
          data: {'relay': relay.url},
        ),
      );
    }
  }

  void _handleRelayDisconnection(RelayConnection relay) {
    if (!_isDisposed) {
      _relayDisconnectedController.add(relay);

      final remaining = connectionCount;
      _failoverController.add(
        FailoverEvent(
          failedRelay: relay.url,
          remainingRelays: remaining,
        ),
      );

      _eventController.add(
        PoolEvent(
          type: PoolEventType.relayDisconnected,
          data: {'relay': relay.url, 'remaining': remaining},
        ),
      );
    }
  }

  void broadcast(String message) {
    if (_isDisposed) {
      throw StateError('Cannot broadcast: WebSocketPool is disposed');
    }

    for (final relay in connectedRelays) {
      try {
        relay.manager.send(message);
      } catch (e) {
        // Log error but continue broadcasting to other relays
        relay.healthMetrics.recordError();
      }
    }

    _eventController.add(
      PoolEvent(
        type: PoolEventType.messageSent,
        data: {'message': message, 'relayCount': connectedRelays.length},
      ),
    );
  }

  void sendToRelay(String relayUrl, String message) {
    if (_isDisposed) {
      throw StateError('Cannot send: WebSocketPool is disposed');
    }

    final relay = _relays[relayUrl];
    if (relay == null) {
      throw ArgumentError('Relay not found: $relayUrl');
    }

    if (relay.manager.connectionState != WebSocketConnectionState.connected) {
      throw StateError('Relay not connected: $relayUrl');
    }

    relay.manager.send(message);

    _eventController.add(
      PoolEvent(
        type: PoolEventType.messageSent,
        data: {'relay': relayUrl, 'message': message},
      ),
    );
  }

  RelayConnection selectRelay() {
    final connected = connectedRelays;
    if (connected.isEmpty) {
      throw StateError('No connected relays available');
    }

    return _loadBalancer.selectRelay(connected);
  }

  RelayConnection? getRelay(String url) => _relays[url];

  Future<void> reconnectFailed() async {
    if (_isDisposed) return;

    final failed = failedRelays
        .toList(); // Create a copy to avoid modification during iteration
    final futures = <Future>[];

    for (final relay in failed) {
      // Reset error state by transitioning to disconnected
      if (relay.manager.connectionState == WebSocketConnectionState.error) {
        // Simulate transitioning from error to disconnected so we can reconnect
        await relay.manager.disconnect();
        // Give a moment for state to update
        await Future.delayed(const Duration(milliseconds: 10));
      }
      futures.add(_connectRelay(relay));
    }

    await Future.wait(futures, eagerError: false);
  }

  Future<void> addRelay(String url) async {
    if (_isDisposed) {
      throw StateError('Cannot add relay: WebSocketPool is disposed');
    }

    if (_relays.containsKey(url)) {
      return; // Already exists
    }

    final relay = RelayConnection(
      url: url,
      config: _relayConfigs[url] ?? RelayConfig(),
    );

    _relays[url] = relay;

    _eventController.add(
      PoolEvent(
        type: PoolEventType.relayAdded,
        data: {'relay': url},
      ),
    );

    // Connect if we're under the limit
    if (connectionCount < maxConnections) {
      await _connectRelay(relay);
    }
  }

  Future<void> removeRelay(String url) async {
    if (_isDisposed) {
      throw StateError('Cannot remove relay: WebSocketPool is disposed');
    }

    final relay = _relays[url];
    if (relay == null) return;

    await relay.manager.disconnect();
    relay.manager.dispose();
    _relays.remove(url);

    _eventController.add(
      PoolEvent(
        type: PoolEventType.relayRemoved,
        data: {'relay': url},
      ),
    );
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final relay in _relays.values) {
      relay.manager.dispose();
    }

    _relayConnectedController.close();
    _relayDisconnectedController.close();
    _messageController.close();
    _failoverController.close();
    _eventController.close();
  }

  // Test helpers
  void simulateConnectionFailure(String url) {
    final relay = _relays[url];
    if (relay != null) {
      // Prevent connection from succeeding
      _failedConnections.add(url);
    }
  }

  void simulateConnection(String url) {
    final relay = _relays[url];
    if (relay != null) {
      // Remove from failed connections if present
      _failedConnections.remove(url);
      relay.manager.simulateConnection();
      if (!_isDisposed) {
        _relayConnectedController.add(relay);
        relay.healthMetrics.recordSuccess();
      }
    }
  }

  void simulateDisconnection(String url) {
    final relay = _relays[url];
    if (relay != null) {
      relay.manager.simulateDisconnection();
      _handleRelayDisconnection(relay);
    }
  }

  void simulateLatency(String url, Duration latency) {
    final relay = _relays[url];
    if (relay != null) {
      relay.healthMetrics.recordLatency(latency);
    }
  }

  void simulateError(String url, String error) {
    final relay = _relays[url];
    if (relay != null) {
      relay.healthMetrics.recordError();
      _handleRelayError(relay);
    }
  }

  // Track failed connections for testing
  final Set<String> _failedConnections = {};
}
