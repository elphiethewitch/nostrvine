// ABOUTME: Manages Nostr relay connections with proper async patterns
// ABOUTME: Replaces Future.delayed with event-driven connection handling

import 'dart:async';
import 'package:nostr_sdk/nostr_sdk.dart';
import 'package:openvine/utils/async_utils.dart';
import 'package:openvine/utils/unified_logger.dart';

// TODO: Fix NostrClient type - this appears to be from a newer/different version of nostr_sdk
// For now, using dynamic to allow compilation while this experimental feature is developed
typedef NostrClient = dynamic;

// TODO: Fix ClientConnected enum - typo and missing import
enum ClientConnected {
  connected,
  connecting,
  error,
  disconnected,
}

/// Connection state for a relay
enum RelayConnectionState {
  disconnected,
  connecting,
  authenticating,
  connected,
  error,
}

/// Manages relay connections without timing hacks
class NostrConnectionManager {
  final Map<String, RelayConnectionState> _relayStates = {};
  final StreamController<Map<String, RelayConnectionState>> _stateController =
      StreamController<Map<String, RelayConnectionState>>.broadcast();

  /// Stream of relay connection states
  Stream<Map<String, RelayConnectionState>> get stateChanges =>
      _stateController.stream;

  /// Current relay states
  Map<String, RelayConnectionState> get relayStates =>
      Map.unmodifiable(_relayStates);

  /// Connect to relays and wait for authentication
  Future<void> connectToRelays({
    required NostrClient client,
    required List<String> relayUrls,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    Log.info(
      'Connecting to ${relayUrls.length} relays with event-driven pattern',
      name: 'NostrConnectionManager',
      category: LogCategory.relay,
    );

    // Initialize relay states
    for (final url in relayUrls) {
      _updateRelayState(url, RelayConnectionState.disconnected);
    }

    // Connect to each relay
    for (final url in relayUrls) {
      _connectToRelay(client, url);
    }

    // Wait for all relays to complete authentication
    final allAuthenticated = await AsyncUtils.waitForCondition(
      condition: () => _areAllRelaysReady(relayUrls),
      timeout: timeout,
      checkInterval: const Duration(milliseconds: 100),
      debugName: 'all-relays-authenticated',
    );

    if (!allAuthenticated) {
      final failedRelays = _relayStates.entries
          .where((e) => e.value != RelayConnectionState.connected)
          .map((e) => e.key)
          .toList();

      Log.warning(
        'Some relays failed to authenticate: $failedRelays',
        name: 'NostrConnectionManager',
        category: LogCategory.relay,
      );
    }

    // Log final states
    _logRelayStates();
  }

  /// Connect to a single relay
  void _connectToRelay(NostrClient client, String url) {
    _updateRelayState(url, RelayConnectionState.connecting);

    try {
      final relay = client.relayByUrl(url);
      if (relay == null) {
        throw Exception('Relay not found: $url');
      }

      // Monitor relay status changes
      _monitorRelayStatus(relay);
    } catch (error) {
      Log.error(
        'Failed to connect to relay $url: $error',
        name: 'NostrConnectionManager',
        category: LogCategory.relay,
      );
      _updateRelayState(url, RelayConnectionState.error);
    }
  }

  /// Monitor relay status and update states accordingly
  void _monitorRelayStatus(Relay relay) {
    // Check current status
    if (relay.relayStatus.connected == ClientConnected.connected) {
      if (relay.relayStatus.authed == true ||
          relay.relayStatus.readAccess == true) {
        _updateRelayState(relay.url, RelayConnectionState.connected);
      } else if (relay.relayStatus.alwaysAuth == true) {
        _updateRelayState(relay.url, RelayConnectionState.authenticating);
        // Set up periodic check for auth completion
        _waitForAuthentication(relay);
      } else {
        _updateRelayState(relay.url, RelayConnectionState.connected);
      }
    } else if (relay.relayStatus.connected == ClientConnected.connecting) {
      _updateRelayState(relay.url, RelayConnectionState.connecting);
      // Set up periodic check for connection
      _waitForConnection(relay);
    }
  }

  /// Wait for relay to complete authentication
  void _waitForAuthentication(Relay relay) {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (relay.relayStatus.authed == true ||
          relay.relayStatus.readAccess == true ||
          relay.relayStatus.writeAccess == true) {
        timer.cancel();
        _updateRelayState(relay.url, RelayConnectionState.connected);
        Log.debug(
          'Relay ${relay.url} authenticated successfully',
          name: 'NostrConnectionManager',
          category: LogCategory.relay,
        );
      } else if (_relayStates[relay.url] == RelayConnectionState.error) {
        timer.cancel();
      }
    });
  }

  /// Wait for relay to connect
  void _waitForConnection(Relay relay) {
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (relay.relayStatus.connected == ClientConnected.connected) {
        timer.cancel();
        _monitorRelayStatus(relay); // Re-check status after connection
      } else if (relay.relayStatus.connected == ClientConnected.error ||
          _relayStates[relay.url] == RelayConnectionState.error) {
        timer.cancel();
        _updateRelayState(relay.url, RelayConnectionState.error);
      }
    });
  }

  /// Update relay state and notify listeners
  void _updateRelayState(String url, RelayConnectionState state) {
    _relayStates[url] = state;
    _stateController.add(Map.from(_relayStates));

    Log.debug(
      'Relay $url state: $state',
      name: 'NostrConnectionManager',
      category: LogCategory.relay,
    );
  }

  /// Check if all relays are ready (connected or failed)
  bool _areAllRelaysReady(List<String> relayUrls) {
    for (final url in relayUrls) {
      final state = _relayStates[url];
      if (state == null ||
          state == RelayConnectionState.disconnected ||
          state == RelayConnectionState.connecting ||
          state == RelayConnectionState.authenticating) {
        return false;
      }
    }
    return true;
  }

  /// Log final relay states
  void _logRelayStates() {
    Log.info(
      'Final relay connection states:',
      name: 'NostrConnectionManager',
      category: LogCategory.relay,
    );

    for (final entry in _relayStates.entries) {
      Log.info(
        '  ${entry.key}: ${entry.value}',
        name: 'NostrConnectionManager',
        category: LogCategory.relay,
      );
    }
  }

  /// Clean up resources
  void dispose() {
    _stateController.close();
  }
}
