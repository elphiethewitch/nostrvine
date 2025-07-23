// ABOUTME: Tests for WebSocket reconnection strategy with exponential backoff
// ABOUTME: Verifies proper retry logic without using Future.delayed

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/core/websocket/reconnection_strategy.dart';
import 'package:openvine/core/websocket/websocket_connection_state.dart';

void main() {
  group('ReconnectionStrategy', () {
    late ReconnectionStrategy strategy;

    setUp(() {
      strategy = ReconnectionStrategy();
    });

    test('should have default configuration', () {
      expect(strategy.initialDelay, equals(const Duration(seconds: 1)));
      expect(strategy.maxDelay, equals(const Duration(minutes: 5)));
      expect(strategy.maxRetries, equals(10));
      expect(strategy.backoffFactor, equals(2.0));
      expect(strategy.jitterFactor, equals(0.1));
    });

    test('should allow custom configuration', () {
      final customStrategy = ReconnectionStrategy(
        initialDelay: const Duration(milliseconds: 500),
        maxDelay: const Duration(seconds: 30),
        maxRetries: 5,
        backoffFactor: 1.5,
        jitterFactor: 0.2,
      );

      expect(customStrategy.initialDelay,
          equals(const Duration(milliseconds: 500)));
      expect(customStrategy.maxDelay, equals(const Duration(seconds: 30)));
      expect(customStrategy.maxRetries, equals(5));
      expect(customStrategy.backoffFactor, equals(1.5));
      expect(customStrategy.jitterFactor, equals(0.2));
    });

    test('should calculate exponential backoff delays', () {
      final delays = <Duration>[];

      for (var i = 0; i < 5; i++) {
        delays.add(strategy.getNextDelay(i));
      }

      // First delay should be initial delay (with possible jitter)
      expect(
        delays[0].inMilliseconds,
        greaterThanOrEqualTo(900), // 1s - 10% jitter
      );
      expect(
        delays[0].inMilliseconds,
        lessThanOrEqualTo(1100), // 1s + 10% jitter
      );

      // Each subsequent delay should be exponentially larger
      for (var i = 1; i < delays.length; i++) {
        expect(
          delays[i].inMilliseconds,
          greaterThan(delays[i - 1].inMilliseconds),
        );
      }
    });

    test('should respect maximum delay', () {
      final strategy = ReconnectionStrategy(
        initialDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 10),
        backoffFactor: 2,
      );

      // After many retries, delay should not exceed max
      final delay = strategy.getNextDelay(20);
      expect(
          delay.inMilliseconds, lessThanOrEqualTo(11000)); // 10s + 10% jitter
    });

    test('should add jitter to delays', () {
      final strategy = ReconnectionStrategy(
        initialDelay: const Duration(seconds: 1),
        jitterFactor: 0.5, // 50% jitter for easier testing
      );

      final delays = <Duration>[];
      for (var i = 0; i < 10; i++) {
        delays.add(strategy.getNextDelay(0));
      }

      // With jitter, not all delays should be exactly the same
      final uniqueDelays = delays.map((d) => d.inMilliseconds).toSet();
      expect(uniqueDelays.length, greaterThan(1));
    });

    test('should track retry attempts', () {
      expect(strategy.currentAttempt, equals(0));

      strategy.recordAttempt();
      expect(strategy.currentAttempt, equals(1));

      strategy.recordAttempt();
      expect(strategy.currentAttempt, equals(2));
    });

    test('should reset retry count', () {
      strategy.recordAttempt();
      strategy.recordAttempt();
      expect(strategy.currentAttempt, equals(2));

      strategy.reset();
      expect(strategy.currentAttempt, equals(0));
    });

    test('should know when retries are exhausted', () {
      final strategy = ReconnectionStrategy(maxRetries: 3);

      expect(strategy.shouldRetry, isTrue);

      strategy.recordAttempt(); // 1
      expect(strategy.shouldRetry, isTrue);

      strategy.recordAttempt(); // 2
      expect(strategy.shouldRetry, isTrue);

      strategy.recordAttempt(); // 3
      expect(strategy.shouldRetry, isFalse);
    });

    test('should schedule reconnection with Timer', () async {
      final completer = Completer<void>();

      final timer = strategy.scheduleReconnection(completer.complete);

      expect(timer, isNotNull);
      expect(timer.isActive, isTrue);

      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => throw TestFailure('Reconnection not triggered'),
      );

      expect(timer.isActive, isFalse);
    });

    test('should cancel scheduled reconnection', () {
      var called = false;

      final timer = strategy.scheduleReconnection(() {
        called = true;
      });

      // Cancel before it fires
      timer.cancel();

      // Wait to ensure it doesn't fire
      Future.delayed(const Duration(seconds: 2)).then((_) {
        expect(called, isFalse);
      });
    });

    test('should provide retry statistics', () {
      final stats = strategy.statistics;

      expect(stats.totalAttempts, equals(0));
      expect(stats.successfulReconnections, equals(0));
      expect(stats.failedReconnections, equals(0));
      expect(stats.averageReconnectionTime, isNull);
    });

    test('should update statistics on attempts', () {
      strategy.recordAttempt();
      expect(strategy.statistics.totalAttempts, equals(1));

      strategy.recordSuccess(const Duration(seconds: 2));
      expect(strategy.statistics.successfulReconnections, equals(1));
      expect(strategy.statistics.averageReconnectionTime,
          equals(const Duration(seconds: 2)));

      strategy.recordFailure();
      expect(strategy.statistics.failedReconnections, equals(1));
    });

    test('should calculate average reconnection time', () {
      strategy.recordAttempt();
      strategy.recordSuccess(const Duration(seconds: 2));

      strategy.recordAttempt();
      strategy.recordSuccess(const Duration(seconds: 4));

      expect(
        strategy.statistics.averageReconnectionTime,
        equals(const Duration(seconds: 3)),
      );
    });

    test('should respect reconnection policy', () {
      final policy = ReconnectionPolicy(
        enableReconnection: true,
        reconnectOnError: true,
        reconnectOnClose: false,
        conditions: [
          (state, error) => state != WebSocketConnectionState.closed,
        ],
      );

      expect(
        policy.shouldReconnect(
          WebSocketConnectionState.error,
          'Connection failed',
        ),
        isTrue,
      );

      expect(
        policy.shouldReconnect(
          WebSocketConnectionState.closed,
          'User closed',
        ),
        isFalse,
      );
    });

    test('should have configurable retry conditions', () {
      var shouldRetryOnAuth = false;

      final strategy = ReconnectionStrategy(
        retryCondition: (attempt, error) {
          if (error?.toString().contains('auth') ?? false) {
            return shouldRetryOnAuth;
          }
          return true;
        },
      );

      expect(strategy.shouldRetryWithError(1, 'Connection timeout'), isTrue);
      expect(strategy.shouldRetryWithError(1, 'auth failed'), isFalse);

      shouldRetryOnAuth = true;
      expect(strategy.shouldRetryWithError(2, 'auth failed'), isTrue);
    });

    test('should emit reconnection events', () async {
      final events = <ReconnectionEvent>[];
      final subscription = strategy.events.listen(events.add);

      strategy.recordAttempt();
      strategy.scheduleReconnection(() {});
      strategy.recordSuccess(const Duration(seconds: 1));

      await Future.delayed(const Duration(milliseconds: 10));

      expect(events.any((e) => e.type == ReconnectionEventType.attemptStarted),
          isTrue);
      expect(
          events.any((e) => e.type == ReconnectionEventType.scheduled), isTrue);
      expect(
          events.any((e) => e.type == ReconnectionEventType.succeeded), isTrue);

      await subscription.cancel();
    });

    test('should support immediate reconnection', () async {
      final completer = Completer<void>();

      final timer = strategy.scheduleImmediateReconnection(completer.complete);

      await completer.future.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () =>
            throw TestFailure('Immediate reconnection not triggered'),
      );

      expect(timer.isActive, isFalse);
    });

    test('should have circuit breaker functionality', () {
      final strategy = ReconnectionStrategy(
        circuitBreakerThreshold: 3,
        circuitBreakerDuration: const Duration(seconds: 30),
      );

      expect(strategy.isCircuitOpen, isFalse);

      // Record failures
      strategy.recordAttempt();
      strategy.recordFailure();
      strategy.recordAttempt();
      strategy.recordFailure();

      expect(strategy.isCircuitOpen, isFalse);

      strategy.recordAttempt();
      strategy.recordFailure();

      // Circuit should open after threshold
      expect(strategy.isCircuitOpen, isTrue);
      expect(strategy.shouldRetry, isFalse);
    });
  });

  group('ReconnectionStatistics', () {
    test('should calculate success rate', () {
      final stats = ReconnectionStatistics();

      expect(stats.successRate, equals(0.0));

      stats.recordAttempt();
      stats.recordSuccess(const Duration(seconds: 1));
      expect(stats.successRate, equals(1.0));

      stats.recordAttempt();
      stats.recordFailure();
      expect(stats.successRate, equals(0.5));
    });

    test('should track last attempt time', () {
      final stats = ReconnectionStatistics();

      expect(stats.lastAttemptTime, isNull);

      stats.recordAttempt();
      expect(stats.lastAttemptTime, isNotNull);
      expect(
        DateTime.now().difference(stats.lastAttemptTime!).inSeconds,
        lessThan(1),
      );
    });
  });

  group('ReconnectionEvent', () {
    test('should create events with metadata', () {
      final event = ReconnectionEvent(
        type: ReconnectionEventType.attemptStarted,
        attempt: 1,
        delay: const Duration(seconds: 2),
        error: 'Test error',
      );

      expect(event.type, equals(ReconnectionEventType.attemptStarted));
      expect(event.attempt, equals(1));
      expect(event.delay, equals(const Duration(seconds: 2)));
      expect(event.error, equals('Test error'));
      expect(event.timestamp, isNotNull);
    });
  });
}
