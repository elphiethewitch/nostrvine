// ABOUTME: Stub factory for platforms without WebSocket support
// ABOUTME: Throws error if used

import 'package:openvine/services/websocket_connection_manager.dart';

class PlatformWebSocketFactory implements WebSocketFactory {
  @override
  WebSocketInterface create(String url) {
    throw UnsupportedError('WebSocket not available on this platform');
  }
}
