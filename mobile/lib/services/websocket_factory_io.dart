// ABOUTME: IO platform WebSocket factory implementation
// ABOUTME: Creates WebSocket adapters for mobile/desktop platforms

import 'package:openvine/services/web_socket_io.dart';
import 'package:openvine/services/websocket_connection_manager.dart';

class PlatformWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) => IoWebSocketFactory().create(url);
}
