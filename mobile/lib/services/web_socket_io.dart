// ABOUTME: IO platform WebSocket implementation
// ABOUTME: Provides WebSocket for mobile/desktop platforms using dart:io

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:openvine/services/websocket_connection_manager.dart';
import 'package:openvine/utils/unified_logger.dart';

/// IO platform WebSocket adapter
class IoWebSocketAdapter implements WebSocketInterface {
  IoWebSocketAdapter(this.url);
  final String url;
  io.WebSocket? _socket;

  final _openController = StreamController<void>.broadcast();
  final _closeController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  bool _isOpen = false;
  StreamSubscription<dynamic>? _subscription;

  @override
  Stream<void> get onOpen => _openController.stream;

  @override
  Stream<void> get onClose => _closeController.stream;

  @override
  Stream<String> get onError => _errorController.stream;

  @override
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  @override
  bool get isOpen => _isOpen;

  /// Connect to the WebSocket
  @override
  Future<void> connect() async {
    try {
      _socket = await io.WebSocket.connect(url);
      _isOpen = true;

      // Notify open
      scheduleMicrotask(() {
        if (!_openController.isClosed) {
          _openController.add(null);
        }
      });

      // Setup listeners
      _subscription = _socket!.listen(
        (data) {
          try {
            if (data is String) {
              final decoded = jsonDecode(data);
              if (decoded is Map<String, dynamic>) {
                if (!_messageController.isClosed) {
                  _messageController.add(decoded);
                }
              }
            }
          } catch (e) {
            Log.error(
              'Error decoding WebSocket message: $e',
              name: 'IoWebSocketAdapter',
              category: LogCategory.system,
            );
          }
        },
        onError: (error) {
          final errorStr = error.toString();
          Log.error(
            'WebSocket error: $errorStr',
            name: 'IoWebSocketAdapter',
            category: LogCategory.system,
          );
          if (!_errorController.isClosed) {
            _errorController.add(errorStr);
          }
        },
        onDone: () {
          _isOpen = false;
          if (!_closeController.isClosed) {
            _closeController.add(null);
          }
        },
      );
    } catch (e) {
      Log.error(
        'Failed to connect WebSocket to $url: $e',
        name: 'IoWebSocketAdapter',
        category: LogCategory.system,
      );
      if (!_errorController.isClosed) {
        _errorController.add(e.toString());
      }
    }
  }

  @override
  void send(Map<String, dynamic> data) {
    if (!_isOpen || _socket == null) {
      throw StateError('WebSocket is not open');
    }

    try {
      final encoded = jsonEncode(data);
      _socket!.add(encoded);
    } catch (e) {
      Log.error(
        'Error sending WebSocket message: $e',
        name: 'IoWebSocketAdapter',
        category: LogCategory.system,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _isOpen = false;
    _subscription?.cancel();
    _socket?.close();

    _openController.close();
    _closeController.close();
    _errorController.close();
    _messageController.close();
  }
}

/// Factory for creating IO WebSocket adapters
class IoWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) {
    final adapter = IoWebSocketAdapter(url);
    // Don't start connection here - let the manager control it
    return adapter;
  }
}
