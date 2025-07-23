// ABOUTME: Web platform WebSocket implementation
// ABOUTME: Provides WebSocket for web platform using dart:html

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

import 'package:openvine/services/websocket_connection_manager.dart';
import 'package:openvine/utils/unified_logger.dart';

/// Web platform WebSocket adapter
class HtmlWebSocketAdapter implements WebSocketInterface {
  HtmlWebSocketAdapter(this.url);
  final String url;
  html.WebSocket? _socket;

  final _openController = StreamController<void>.broadcast();
  final _closeController = StreamController<void>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  bool _isOpen = false;
  StreamSubscription? _openSub;
  StreamSubscription? _closeSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _messageSub;

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
      _socket = html.WebSocket(url);

      // Setup listeners
      _openSub = _socket!.onOpen.listen((_) {
        _isOpen = true;
        if (!_openController.isClosed) {
          _openController.add(null);
        }
      });

      _messageSub = _socket!.onMessage.listen((event) {
        try {
          final data = event.data;
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
            name: 'HtmlWebSocketAdapter',
            category: LogCategory.system,
          );
        }
      });

      _errorSub = _socket!.onError.listen((event) {
        final error = event.toString();
        Log.error(
          'WebSocket error: $error',
          name: 'HtmlWebSocketAdapter',
          category: LogCategory.system,
        );
        if (!_errorController.isClosed) {
          _errorController.add(error);
        }
      });

      _closeSub = _socket!.onClose.listen((_) {
        _isOpen = false;
        if (!_closeController.isClosed) {
          _closeController.add(null);
        }
      });
    } catch (e) {
      Log.error(
        'Failed to connect WebSocket to $url: $e',
        name: 'HtmlWebSocketAdapter',
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
      _socket!.send(encoded);
    } catch (e) {
      Log.error(
        'Error sending WebSocket message: $e',
        name: 'HtmlWebSocketAdapter',
        category: LogCategory.system,
      );
      rethrow;
    }
  }

  @override
  void close() {
    _isOpen = false;

    _openSub?.cancel();
    _closeSub?.cancel();
    _errorSub?.cancel();
    _messageSub?.cancel();

    _socket?.close();

    _openController.close();
    _closeController.close();
    _errorController.close();
    _messageController.close();
  }
}

/// Factory for creating HTML WebSocket adapters
class HtmlWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) {
    final adapter = HtmlWebSocketAdapter(url);
    // Don't start connection here - let the manager control it
    return adapter;
  }
}
