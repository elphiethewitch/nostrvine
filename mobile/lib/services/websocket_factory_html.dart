// ABOUTME: HTML platform WebSocket factory implementation
// ABOUTME: Creates WebSocket adapters for web platform

import 'package:openvine/services/web_socket_html.dart';
import 'package:openvine/services/websocket_connection_manager.dart';

class PlatformWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) => HtmlWebSocketFactory().create(url);
}
