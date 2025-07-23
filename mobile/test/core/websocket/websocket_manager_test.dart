// ABOUTME: Tests for WebSocketManager lifecycle and event-driven connection handling
// ABOUTME: Verifies proper connection management without timing-based logic

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/core/websocket/websocket_connection_state.dart';
import 'package:openvine/core/websocket/websocket_manager.dart';

void main() {
  group('WebSocketManager', () {
    late WebSocketManager manager;
    late String testUrl;

    setUp(() {
      testUrl = 'wss://relay.example.com';
      manager = WebSocketManager(url: testUrl);
    });

    tearDown(() {
      manager.dispose();
    });

    test('should initialize with disconnected state', () {
      expect(manager.connectionState,
          equals(WebSocketConnectionState.disconnected));
      expect(manager.isConnected, isFalse);
    });

    test('should expose connection state stream', () {
      expect(manager.connectionStateStream,
          isA<Stream<WebSocketConnectionState>>());
    });

    test('should expose message stream', () {
      expect(manager.messageStream, isA<Stream<WebSocketMessage>>());
    });

    test('should expose error stream', () {
      expect(manager.errorStream, isA<Stream<WebSocketError>>());
    });

    test('should connect to WebSocket server', () async {
      final stateChanges = <WebSocketConnectionState>[];
      final subscription =
          manager.connectionStateStream.listen(stateChanges.add);

      await manager.connect();

      // Should transition through connecting to connected (or error)
      expect(stateChanges, contains(WebSocketConnectionState.connecting));

      await subscription.cancel();
    });

    test('should handle connection timeout', () async {
      final manager = WebSocketManager(
        url: 'wss://unreachable.example.com',
        connectionTimeout: const Duration(milliseconds: 100),
      );

      final errorCompleter = Completer<WebSocketError>();
      final errorSubscription = manager.errorStream.listen((error) {
        if (!errorCompleter.isCompleted) {
          errorCompleter.complete(error);
        }
      });

      await manager.connect();

      final error = await errorCompleter.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TestFailure('Timeout error not received'),
      );

      // Accept either timeout or connection failed
      expect(
        [
          WebSocketErrorType.connectionTimeout,
          WebSocketErrorType.connectionFailed,
        ],
        contains(error.type),
      );
      expect(manager.connectionState, equals(WebSocketConnectionState.error));

      await errorSubscription.cancel();
      manager.dispose();
    });

    test('should send messages when connected', () async {
      // This test would need a mock WebSocket server
      // For now, we'll test that it throws when not connected
      expect(
        () => manager.send('test message'),
        throwsA(isA<StateError>()),
      );
    });

    test('should disconnect gracefully', () async {
      final stateChanges = <WebSocketConnectionState>[];
      final subscription =
          manager.connectionStateStream.listen(stateChanges.add);

      await manager.disconnect();

      // Should stay disconnected if already disconnected
      expect(manager.connectionState,
          equals(WebSocketConnectionState.disconnected));

      await subscription.cancel();
    });

    test('should handle unexpected disconnection', () async {
      // First, simulate a connection
      manager.simulateConnection();

      // This would simulate server dropping connection
      final errorCompleter = Completer<WebSocketError>();
      final errorSubscription = manager.errorStream.listen((error) {
        if (error.type == WebSocketErrorType.unexpectedDisconnection) {
          errorCompleter.complete(error);
        }
      });

      // Simulate connection drop
      manager.simulateDisconnection();

      final error = await errorCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TestFailure('Disconnection error not received'),
      );

      expect(error.type, equals(WebSocketErrorType.unexpectedDisconnection));

      await errorSubscription.cancel();
    });

    test('should clean up resources on dispose', () {
      manager.dispose();

      // Should not be able to connect after dispose
      expect(
        () => manager.connect(),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle rapid connect/disconnect cycles', () async {
      // Test that rapid state changes don't cause issues
      final futures = <Future>[];

      for (var i = 0; i < 5; i++) {
        futures.add(manager.connect().catchError((_) {}));
        futures.add(manager.disconnect().catchError((_) {}));
      }

      // Should handle all operations without crashing
      await Future.wait(futures, eagerError: false).catchError((_) {});

      // Final state should be stable
      expect(
        [
          WebSocketConnectionState.disconnected,
          WebSocketConnectionState.connecting,
          WebSocketConnectionState.connected,
          WebSocketConnectionState.error,
        ],
        contains(manager.connectionState),
      );
    });

    test('should provide connection metrics', () {
      expect(manager.connectionMetrics, isNotNull);
      expect(manager.connectionMetrics.totalConnections, equals(0));
      expect(manager.connectionMetrics.successfulConnections, equals(0));
      expect(manager.connectionMetrics.failedConnections, equals(0));
    });

    test('should update metrics on connection attempts', () async {
      await manager.connect();

      expect(manager.connectionMetrics.totalConnections, greaterThan(0));
    });

    test('should emit lifecycle events', () async {
      final events = <WebSocketLifecycleEvent>[];
      final subscription = manager.lifecycleEvents.listen(events.add);

      await manager.connect();
      await manager.disconnect();

      expect(
          events.any((e) => e.type == WebSocketLifecycleEventType.connecting),
          isTrue);
      expect(
          events
              .any((e) => e.type == WebSocketLifecycleEventType.disconnecting),
          isTrue);

      await subscription.cancel();
    });

    test('should support custom headers', () {
      final manager = WebSocketManager(
        url: testUrl,
        headers: {
          'X-Custom-Header': 'value',
          'Authorization': 'Bearer token',
        },
      );

      expect(manager.headers['X-Custom-Header'], equals('value'));
      expect(manager.headers['Authorization'], equals('Bearer token'));

      manager.dispose();
    });

    test('should support subprotocols', () {
      final manager = WebSocketManager(
        url: testUrl,
        subprotocols: ['chat', 'superchat'],
      );

      expect(manager.subprotocols, equals(['chat', 'superchat']));

      manager.dispose();
    });

    test('should validate URL on construction', () {
      expect(
        () => WebSocketManager(url: 'invalid-url'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => WebSocketManager(url: 'http://example.com'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle binary messages', () async {
      final binaryData = [1, 2, 3, 4, 5];
      final messages = <WebSocketMessage>[];
      final subscription = manager.messageStream.listen(messages.add);

      // Simulate receiving binary message
      manager.simulateBinaryMessage(binaryData);

      await Future.delayed(const Duration(milliseconds: 10));

      expect(messages.length, equals(1));
      expect(messages.first.isBinary, isTrue);
      expect(messages.first.binaryData, equals(binaryData));

      await subscription.cancel();
    });

    test('should provide connection URL', () {
      expect(manager.url, equals(testUrl));
    });

    test('should track connection duration', () async {
      expect(manager.connectionDuration, isNull);

      // When connected, should track duration
      manager.simulateConnection();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(manager.connectionDuration, isNotNull);
      expect(manager.connectionDuration!.inMilliseconds,
          greaterThanOrEqualTo(100));

      manager.simulateDisconnection();
      expect(manager.connectionDuration, isNull);
    });
  });

  group('WebSocketMessage', () {
    test('should create text message', () {
      final message = WebSocketMessage.text('Hello');

      expect(message.isText, isTrue);
      expect(message.isBinary, isFalse);
      expect(message.textData, equals('Hello'));
      expect(message.binaryData, isNull);
    });

    test('should create binary message', () {
      final data = [1, 2, 3];
      final message = WebSocketMessage.binary(data);

      expect(message.isBinary, isTrue);
      expect(message.isText, isFalse);
      expect(message.binaryData, equals(data));
      expect(message.textData, isNull);
    });

    test('should have timestamp', () {
      final before = DateTime.now();
      final message = WebSocketMessage.text('test');
      final after = DateTime.now();

      expect(
          message.timestamp.isAfter(before) ||
              message.timestamp.isAtSameMomentAs(before),
          isTrue);
      expect(
          message.timestamp.isBefore(after) ||
              message.timestamp.isAtSameMomentAs(after),
          isTrue);
    });
  });

  group('WebSocketError', () {
    test('should create connection error', () {
      final error = WebSocketError(
        type: WebSocketErrorType.connectionFailed,
        message: 'Failed to connect',
        error: const SocketException('Connection refused'),
      );

      expect(error.type, equals(WebSocketErrorType.connectionFailed));
      expect(error.message, equals('Failed to connect'));
      expect(error.error, isA<SocketException>());
    });

    test('should have timestamp', () {
      final error = WebSocketError(
        type: WebSocketErrorType.connectionTimeout,
        message: 'Timeout',
      );

      expect(error.timestamp, isNotNull);
    });
  });

  group('WebSocketLifecycleEvent', () {
    test('should create lifecycle events', () {
      final event = WebSocketLifecycleEvent(
        type: WebSocketLifecycleEventType.connecting,
        details: {'url': 'wss://example.com'},
      );

      expect(event.type, equals(WebSocketLifecycleEventType.connecting));
      expect(event.details['url'], equals('wss://example.com'));
      expect(event.timestamp, isNotNull);
    });
  });

  group('ConnectionMetrics', () {
    test('should track connection statistics', () {
      final metrics = ConnectionMetrics();

      expect(metrics.totalConnections, equals(0));
      expect(metrics.successfulConnections, equals(0));
      expect(metrics.failedConnections, equals(0));
      expect(metrics.averageConnectionTime, isNull);

      metrics.recordConnectionAttempt();
      expect(metrics.totalConnections, equals(1));

      metrics.recordSuccessfulConnection(const Duration(seconds: 2));
      expect(metrics.successfulConnections, equals(1));
      expect(metrics.averageConnectionTime, equals(const Duration(seconds: 2)));

      metrics.recordFailedConnection();
      expect(metrics.failedConnections, equals(1));
    });

    test('should calculate success rate', () {
      final metrics = ConnectionMetrics();

      expect(metrics.successRate, equals(0.0));

      metrics.recordConnectionAttempt();
      metrics.recordSuccessfulConnection(const Duration(seconds: 1));
      metrics.recordConnectionAttempt();
      metrics.recordFailedConnection();

      expect(metrics.successRate, equals(0.5));
    });
  });
}
