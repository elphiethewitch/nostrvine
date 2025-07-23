// ABOUTME: WebSocket reconnection strategy with exponential backoff
// ABOUTME: Implements proper retry logic without Future.delayed

import 'dart:async';
import 'dart:math';
import 'package:openvine/core/websocket/websocket_connection_state.dart';

/// Types of reconnection events
enum ReconnectionEventType {
  attemptStarted,
  scheduled,
  cancelled,
  succeeded,
  failed,
  exhausted,
  circuitOpened,
  circuitClosed,
}

/// Represents a reconnection event
class ReconnectionEvent {
  ReconnectionEvent({
    required this.type,
    this.attempt,
    this.delay,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final ReconnectionEventType type;
  final int? attempt;
  final Duration? delay;
  final String? error;
  final DateTime timestamp;
}

/// Tracks reconnection statistics
class ReconnectionStatistics {
  int _totalAttempts = 0;
  int _successfulReconnections = 0;
  int _failedReconnections = 0;
  final List<Duration> _reconnectionTimes = [];
  DateTime? _lastAttemptTime;

  int get totalAttempts => _totalAttempts;
  int get successfulReconnections => _successfulReconnections;
  int get failedReconnections => _failedReconnections;
  DateTime? get lastAttemptTime => _lastAttemptTime;

  Duration? get averageReconnectionTime {
    if (_reconnectionTimes.isEmpty) return null;
    final totalMs = _reconnectionTimes.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    return Duration(milliseconds: totalMs ~/ _reconnectionTimes.length);
  }

  double get successRate {
    if (_totalAttempts == 0) return 0;
    return _successfulReconnections / _totalAttempts;
  }

  void recordAttempt() {
    _totalAttempts++;
    _lastAttemptTime = DateTime.now();
  }

  void recordSuccess(Duration reconnectionTime) {
    _successfulReconnections++;
    _reconnectionTimes.add(reconnectionTime);
  }

  void recordFailure() {
    _failedReconnections++;
  }

  void reset() {
    _totalAttempts = 0;
    _successfulReconnections = 0;
    _failedReconnections = 0;
    _reconnectionTimes.clear();
    _lastAttemptTime = null;
  }
}

/// Defines when reconnection should be attempted
class ReconnectionPolicy {
  ReconnectionPolicy({
    this.enableReconnection = true,
    this.reconnectOnError = true,
    this.reconnectOnClose = false,
    this.conditions = const [],
  });
  final bool enableReconnection;
  final bool reconnectOnError;
  final bool reconnectOnClose;
  final List<bool Function(WebSocketConnectionState state, String? error)>
      conditions;

  bool shouldReconnect(WebSocketConnectionState state, String? error) {
    if (!enableReconnection) return false;

    if (state == WebSocketConnectionState.error && !reconnectOnError) {
      return false;
    }

    if (state == WebSocketConnectionState.closed && !reconnectOnClose) {
      return false;
    }

    // Check custom conditions
    for (final condition in conditions) {
      if (!condition(state, error)) {
        return false;
      }
    }

    return true;
  }
}

/// Manages reconnection attempts with exponential backoff
class ReconnectionStrategy {
  ReconnectionStrategy({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(minutes: 5),
    this.maxRetries = 10,
    this.backoffFactor = 2.0,
    this.jitterFactor = 0.1,
    this.circuitBreakerThreshold,
    this.circuitBreakerDuration,
    this.retryCondition,
  });
  final Duration initialDelay;
  final Duration maxDelay;
  final int maxRetries;
  final double backoffFactor;
  final double jitterFactor;
  final int? circuitBreakerThreshold;
  final Duration? circuitBreakerDuration;
  final bool Function(int attempt, String? error)? retryCondition;

  final ReconnectionStatistics _statistics = ReconnectionStatistics();
  final StreamController<ReconnectionEvent> _eventController =
      StreamController<ReconnectionEvent>.broadcast();

  final Random _random = Random();
  int _currentAttempt = 0;
  int _consecutiveFailures = 0;
  DateTime? _circuitOpenTime;

  /// Current retry attempt number
  int get currentAttempt => _currentAttempt;

  /// Reconnection statistics
  ReconnectionStatistics get statistics => _statistics;

  /// Stream of reconnection events
  Stream<ReconnectionEvent> get events => _eventController.stream;

  /// Whether retries should continue
  bool get shouldRetry => _currentAttempt < maxRetries && !isCircuitOpen;

  /// Whether the circuit breaker is open
  bool get isCircuitOpen {
    if (circuitBreakerThreshold == null || _circuitOpenTime == null) {
      return false;
    }

    if (circuitBreakerDuration != null) {
      final elapsed = DateTime.now().difference(_circuitOpenTime!);
      if (elapsed >= circuitBreakerDuration!) {
        _closeCircuit();
        return false;
      }
    }

    return _consecutiveFailures >= circuitBreakerThreshold!;
  }

  /// Calculate the next delay with exponential backoff and jitter
  Duration getNextDelay(int attempt) {
    // Calculate base delay with exponential backoff
    final baseDelayMs =
        initialDelay.inMilliseconds * pow(backoffFactor, attempt).toDouble();

    // Cap at maximum delay
    final cappedDelayMs = min(baseDelayMs, maxDelay.inMilliseconds.toDouble());

    // Add jitter
    final jitterRange = cappedDelayMs * jitterFactor;
    final jitter = (_random.nextDouble() * 2 - 1) * jitterRange;
    final finalDelayMs = cappedDelayMs + jitter;

    return Duration(milliseconds: finalDelayMs.round());
  }

  /// Schedule a reconnection attempt
  Timer scheduleReconnection(void Function() callback) {
    final delay = getNextDelay(_currentAttempt);

    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.scheduled,
        attempt: _currentAttempt + 1,
        delay: delay,
      ),
    );

    return Timer(delay, callback);
  }

  /// Schedule an immediate reconnection
  Timer scheduleImmediateReconnection(void Function() callback) {
    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.scheduled,
        attempt: _currentAttempt + 1,
        delay: Duration.zero,
      ),
    );

    // Use microtask to ensure it's truly immediate but still async
    return Timer(Duration.zero, callback);
  }

  /// Record a reconnection attempt
  void recordAttempt() {
    _currentAttempt++;
    _statistics.recordAttempt();

    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.attemptStarted,
        attempt: _currentAttempt,
      ),
    );
  }

  /// Record a successful reconnection
  void recordSuccess(Duration reconnectionTime) {
    _statistics.recordSuccess(reconnectionTime);
    _consecutiveFailures = 0;

    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.succeeded,
        attempt: _currentAttempt,
      ),
    );

    reset();
  }

  /// Record a failed reconnection
  void recordFailure() {
    _statistics.recordFailure();
    _consecutiveFailures++;

    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.failed,
        attempt: _currentAttempt,
      ),
    );

    // Check circuit breaker
    if (circuitBreakerThreshold != null &&
        _consecutiveFailures >= circuitBreakerThreshold!) {
      _openCircuit();
    }

    // Check if retries exhausted
    if (!shouldRetry) {
      _eventController.add(
        ReconnectionEvent(
          type: ReconnectionEventType.exhausted,
          attempt: _currentAttempt,
        ),
      );
    }
  }

  /// Check if retry should be attempted with given error
  bool shouldRetryWithError(int attempt, String? error) {
    if (retryCondition != null) {
      return retryCondition!(attempt, error);
    }
    return true;
  }

  /// Reset the retry counter
  void reset() {
    _currentAttempt = 0;
  }

  /// Reset all statistics
  void resetStatistics() {
    _statistics.reset();
    _consecutiveFailures = 0;
    _circuitOpenTime = null;
  }

  /// Dispose of resources
  void dispose() {
    _eventController.close();
  }

  void _openCircuit() {
    _circuitOpenTime = DateTime.now();
    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.circuitOpened,
      ),
    );
  }

  void _closeCircuit() {
    _circuitOpenTime = null;
    _consecutiveFailures = 0;
    _eventController.add(
      ReconnectionEvent(
        type: ReconnectionEventType.circuitClosed,
      ),
    );
  }
}
