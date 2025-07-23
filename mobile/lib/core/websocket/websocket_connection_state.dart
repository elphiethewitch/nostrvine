// ABOUTME: WebSocket connection state machine for event-driven connection management
// ABOUTME: Replaces timing-based reconnection with proper state transitions

import 'dart:async';

/// Represents the possible states of a WebSocket connection
enum WebSocketConnectionState {
  /// Not connected and not attempting to connect
  disconnected,

  /// Actively attempting to establish a connection
  connecting,

  /// Successfully connected and ready for communication
  connected,

  /// Connection lost, attempting to reconnect
  reconnecting,

  /// Connection failed with an error
  error,

  /// Connection permanently closed
  closed,
}

/// Exception thrown when an invalid state transition is attempted
class InvalidStateTransitionException implements Exception {
  InvalidStateTransitionException({
    required this.from,
    required this.to,
    this.reason,
  });
  final WebSocketConnectionState from;
  final WebSocketConnectionState to;
  final String? reason;

  @override
  String toString() {
    final message = 'Invalid state transition from $from to $to';
    return reason != null ? '$message: $reason' : message;
  }
}

/// Manages WebSocket connection state transitions with validation
class WebSocketStateMachine {
  WebSocketConnectionState _currentState =
      WebSocketConnectionState.disconnected;
  final List<WebSocketConnectionState> _stateHistory = [
    WebSocketConnectionState.disconnected
  ];
  final StreamController<WebSocketConnectionState> _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  DateTime _lastTransitionTime = DateTime.now();
  String? _lastTransitionReason;
  bool _isDisposed = false;

  /// Current connection state
  WebSocketConnectionState get currentState => _currentState;

  /// Stream of state changes
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  /// History of all state transitions
  List<WebSocketConnectionState> get stateHistory =>
      List.unmodifiable(_stateHistory);

  /// Reason for the last state transition
  String? get lastTransitionReason => _lastTransitionReason;

  /// Time spent in the current state
  Duration get timeInCurrentState =>
      DateTime.now().difference(_lastTransitionTime);

  /// Valid state transitions map
  static final Map<WebSocketConnectionState, Set<WebSocketConnectionState>>
      _validTransitions = {
    WebSocketConnectionState.disconnected: {
      WebSocketConnectionState.connecting,
      WebSocketConnectionState.closed,
    },
    WebSocketConnectionState.connecting: {
      WebSocketConnectionState.connected,
      WebSocketConnectionState.error,
      WebSocketConnectionState.disconnected,
      WebSocketConnectionState.closed,
    },
    WebSocketConnectionState.connected: {
      WebSocketConnectionState.disconnected,
      WebSocketConnectionState.error,
      WebSocketConnectionState.closed,
    },
    WebSocketConnectionState.error: {
      WebSocketConnectionState.reconnecting,
      WebSocketConnectionState.disconnected,
      WebSocketConnectionState.connecting,
      WebSocketConnectionState.closed,
    },
    WebSocketConnectionState.reconnecting: {
      WebSocketConnectionState.connected,
      WebSocketConnectionState.error,
      WebSocketConnectionState.disconnected,
      WebSocketConnectionState.closed,
    },
    WebSocketConnectionState.closed: {
      WebSocketConnectionState.disconnected,
    },
  };

  /// Check if a transition to the given state is valid
  bool canTransition(WebSocketConnectionState to) {
    final validStates = _validTransitions[_currentState] ?? {};
    return validStates.contains(to);
  }

  /// Transition to a new state
  void transitionTo(WebSocketConnectionState newState, {String? reason}) {
    if (_isDisposed) {
      throw StateError('Cannot transition on a disposed state machine');
    }

    if (!canTransition(newState)) {
      throw InvalidStateTransitionException(
        from: _currentState,
        to: newState,
        reason: 'Transition not allowed',
      );
    }

    _currentState = newState;
    _stateHistory.add(newState);
    _lastTransitionTime = DateTime.now();
    _lastTransitionReason = reason;

    // Emit state change
    _stateController.add(newState);
  }

  /// Reset the state machine to initial state
  void reset() {
    _currentState = WebSocketConnectionState.disconnected;
    _stateHistory.clear();
    _stateHistory.add(WebSocketConnectionState.disconnected);
    _lastTransitionTime = DateTime.now();
    _lastTransitionReason = null;
  }

  /// Dispose of resources
  void dispose() {
    _isDisposed = true;
    _stateController.close();
  }
}
