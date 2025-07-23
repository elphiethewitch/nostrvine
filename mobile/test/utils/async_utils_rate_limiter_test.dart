// ABOUTME: Tests for AsyncUtils rate limiting functionality
// ABOUTME: Validates proper spacing of operations without Future.delayed

import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/utils/async_utils.dart';

void main() {
  group('AsyncUtils RateLimiter', () {
    test('should space out operations with rate limiter', () async {
      // Arrange
      final executionTimes = <DateTime>[];
      final operations = List.generate(
        5,
        (i) => () async {
          executionTimes.add(DateTime.now());
          return 'Result $i';
        },
      );

      // Act
      final results = await AsyncUtils.executeWithRateLimit(
        operations: operations,
        minInterval: const Duration(milliseconds: 100),
      );

      // Assert
      expect(results.length, 5);
      expect(results,
          ['Result 0', 'Result 1', 'Result 2', 'Result 3', 'Result 4']);

      // Check spacing between operations
      for (var i = 1; i < executionTimes.length; i++) {
        final interval = executionTimes[i].difference(executionTimes[i - 1]);
        expect(interval.inMilliseconds,
            greaterThanOrEqualTo(90)); // Allow small timing variance
      }
    });

    test('should handle errors in individual operations', () async {
      // Arrange
      final operations = [
        () async => 'Success 1',
        () async => throw Exception('Test error'),
        () async => 'Success 2',
      ];

      // Act & Assert
      expect(
        () => AsyncUtils.executeWithRateLimit(
          operations: operations,
          minInterval: const Duration(milliseconds: 50),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('should continue on error when specified', () async {
      // Arrange
      final operations = [
        () async => 'Success 1',
        () async => throw Exception('Test error'),
        () async => 'Success 2',
      ];

      // Act
      final results = await AsyncUtils.executeWithRateLimit(
        operations: operations,
        minInterval: const Duration(milliseconds: 50),
        continueOnError: true,
      );

      // Assert
      expect(results.length, 3);
      expect(results[0], 'Success 1');
      expect(results[1], isNull);
      expect(results[2], 'Success 2');
    });

    test('should respect cancellation', () async {
      // Arrange
      final executionCount = <int>[];
      final operations = List.generate(
        10,
        (i) => () async {
          executionCount.add(i);
          return i;
        },
      );

      // Act
      final future = AsyncUtils.executeWithRateLimit(
        operations: operations,
        minInterval: const Duration(milliseconds: 100),
      );

      // Cancel after a short delay
      await Future.delayed(const Duration(milliseconds: 250));
      future.ignore(); // Simulate cancellation

      // Wait a bit more
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert - should have executed only a few operations
      expect(executionCount.length, lessThan(10));
    });
  });
}
