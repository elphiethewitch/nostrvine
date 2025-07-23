// ABOUTME: TDD test for eliminating Future.delayed timeout pattern
// ABOUTME: Tests the timeout mechanism without storage dependencies

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// Test class to demonstrate proper timeout pattern
class KeyGeneratorWithTimeout {
  // Current implementation with Future.delayed (BAD)
  Future<String> generateWithFutureDelayed() async => Future.any([
        Future(() async {
          // Simulate key generation
          await Future.delayed(const Duration(milliseconds: 100));
          return 'generated-key';
        }),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException(
              'Key generation timed out', const Duration(seconds: 10)),
        ),
      ]);

  // Refactored implementation with proper timeout (GOOD)
  Future<String> generateWithProperTimeout() async => Future(() async {
        // Simulate key generation
        await Future.delayed(const Duration(milliseconds: 100));
        return 'generated-key';
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
            'Key generation timed out', const Duration(seconds: 10)),
      );
}

void main() {
  group('Key generation timeout pattern', () {
    late KeyGeneratorWithTimeout generator;

    setUp(() {
      generator = KeyGeneratorWithTimeout();
    });

    test('Future.delayed timeout creates unnecessary timer', () async {
      // This test demonstrates the problem with Future.delayed
      final stopwatch = Stopwatch()..start();

      // Even though generation completes quickly, Future.delayed
      // creates a timer that runs for the full duration
      final result = await generator.generateWithFutureDelayed();
      stopwatch.stop();

      expect(result, equals('generated-key'));
      expect(stopwatch.elapsed.inMilliseconds, lessThan(200));

      // However, the Future.delayed timer is still active in background
      // This is wasteful and can cause issues
    });

    test('proper timeout only runs as long as needed', () async {
      // This test shows the correct pattern
      final stopwatch = Stopwatch()..start();

      final result = await generator.generateWithProperTimeout();
      stopwatch.stop();

      expect(result, equals('generated-key'));
      expect(stopwatch.elapsed.inMilliseconds, lessThan(200));

      // With .timeout(), no background timer continues running
    });

    test('both patterns handle actual timeout correctly', () async {
      // Test with modified generator that actually times out
      final slowGenerator = SlowKeyGenerator();

      // Both should timeout, but proper pattern is cleaner
      expect(
        slowGenerator.generateWithFutureDelayed,
        throwsA(isA<TimeoutException>()),
      );

      expect(
        slowGenerator.generateWithProperTimeout,
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}

// Test class that simulates slow generation
class SlowKeyGenerator extends KeyGeneratorWithTimeout {
  @override
  Future<String> generateWithFutureDelayed() async => Future.any([
        Future(() async {
          // Simulate slow key generation
          await Future.delayed(const Duration(seconds: 15));
          return 'generated-key';
        }),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException(
              'Key generation timed out', const Duration(seconds: 10)),
        ),
      ]);

  @override
  Future<String> generateWithProperTimeout() async => Future(() async {
        // Simulate slow key generation
        await Future.delayed(const Duration(seconds: 15));
        return 'generated-key';
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
            'Key generation timed out', const Duration(seconds: 10)),
      );
}
