// ABOUTME: Stub file for WebSocket when neither io nor html libraries are available
// ABOUTME: Provides empty implementations to avoid compilation errors

import 'package:openvine/services/websocket_connection_manager.dart';

class IoWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) {
    throw UnsupportedError('WebSocket not available on this platform');
  }
}

class HtmlWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) {
    throw UnsupportedError('WebSocket not available on this platform');
  }
}
