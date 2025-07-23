// ABOUTME: Platform-specific WebSocket adapter for WebSocketConnectionManager
// ABOUTME: Provides unified interface for dart:io and dart:html WebSockets

// Export the factory that will be used
export 'websocket_factory_stub.dart'
    if (dart.library.html) 'websocket_factory_html.dart'
    if (dart.library.io) 'websocket_factory_io.dart';
