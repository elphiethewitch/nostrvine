// ABOUTME: Tests for AsyncUtils helper class for proper async patterns
// ABOUTME: Verifies Completer-based operations and condition waiting without Future.delayed

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/core/async/async_utils.dart';

void main() {
  group('AsyncUtils', () {
    group('waitForCondition', () {
      test('should complete when condition becomes true', () async {
        var condition = false;

        // Set condition to true after a short time
        Timer(const Duration(milliseconds: 100), () {
          condition = true;
        });

        await expectLater(
          AsyncUtils.waitForCondition(
            () => condition,
            timeout: const Duration(seconds: 1),
            checkInterval: const Duration(milliseconds: 50),
          ),
          completes,
        );

        expect(condition, isTrue);
      });

      test('should timeout when condition never becomes true', () async {
        const condition = false;

        await expectLater(
          AsyncUtils.waitForCondition(
            () => condition,
            timeout: const Duration(milliseconds: 200),
            checkInterval: const Duration(milliseconds: 50),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should complete immediately if condition is already true',
          () async {
        const condition = true;

        final stopwatch = Stopwatch()..start();
        await AsyncUtils.waitForCondition(() => condition);
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });

    group('runWithTimeout', () {
      test('should complete successfully within timeout', () async {
        final result = await AsyncUtils.runWithTimeout(
          Future.value(42),
          timeout: const Duration(seconds: 1),
        );

        expect(result, equals(42));
      });

      test('should throw TimeoutException when operation exceeds timeout',
          () async {
        await expectLater(
          AsyncUtils.runWithTimeout(
            Future.delayed(const Duration(seconds: 2)),
            timeout: const Duration(milliseconds: 100),
          ),
          throwsA(isA<TimeoutException>()),
        );
      });
    });

    group('debounce', () {
      test('should only execute function once for rapid calls', () async {
        var callCount = 0;
        final debouncedFunction = AsyncUtils.debounce(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        // Call multiple times rapidly
        debouncedFunction();
        debouncedFunction();
        debouncedFunction();
        debouncedFunction();

        // Wait for debounce duration
        await Future.delayed(const Duration(milliseconds: 150));

        expect(callCount, equals(1));
      });

      test('should execute multiple times with sufficient delay', () async {
        var callCount = 0;
        final debouncedFunction = AsyncUtils.debounce(
          () => callCount++,
          duration: const Duration(milliseconds: 50),
        );

        debouncedFunction();
        await Future.delayed(const Duration(milliseconds: 100));

        debouncedFunction();
        await Future.delayed(const Duration(milliseconds: 100));

        expect(callCount, equals(2));
      });
    });

    group('throttle', () {
      test('should limit execution rate', () async {
        var callCount = 0;
        final throttledFunction = AsyncUtils.throttle(
          () => callCount++,
          duration: const Duration(milliseconds: 100),
        );

        // Call multiple times rapidly
        for (var i = 0; i < 10; i++) {
          throttledFunction();
          await Future.delayed(const Duration(milliseconds: 20));
        }

        // Should have executed roughly every 100ms
        expect(callCount, greaterThanOrEqualTo(2));
        expect(callCount, lessThanOrEqualTo(3));
      });
    });

    group('retry', () {
      test('should succeed on first attempt', () async {
        var attempts = 0;
        final result = await AsyncUtils.retry(
          () async {
            attempts++;
            return 'success';
          },
        );

        expect(result, equals('success'));
        expect(attempts, equals(1));
      });

      test('should retry on failure and eventually succeed', () async {
        var attempts = 0;
        final result = await AsyncUtils.retry(
          () async {
            attempts++;
            if (attempts < 3) {
              throw Exception('Temporary failure');
            }
            return 'success';
          },
          maxAttempts: 5,
          delay: const Duration(milliseconds: 10),
        );

        expect(result, equals('success'));
        expect(attempts, equals(3));
      });

      test('should fail after max attempts', () async {
        var attempts = 0;

        await expectLater(
          AsyncUtils.retry(
            () async {
              attempts++;
              throw Exception('Persistent failure');
            },
            maxAttempts: 3,
            delay: const Duration(milliseconds: 10),
          ),
          throwsException,
        );

        expect(attempts, equals(3));
      });

      test('should use exponential backoff', () async {
        final delays = <Duration>[];
        var attempts = 0;
        DateTime? lastAttemptTime;

        try {
          await AsyncUtils.retry(
            () async {
              attempts++;
              if (lastAttemptTime != null) {
                delays.add(DateTime.now().difference(lastAttemptTime!));
              }
              lastAttemptTime = DateTime.now();
              throw Exception('Force retry');
            },
            maxAttempts: 4,
            delay: const Duration(milliseconds: 10),
            exponentialBackoff: true,
          );
        } catch (_) {
          // Expected to fail
        }

        expect(attempts, equals(4));
        expect(delays.length, equals(3));

        // Each delay should be roughly double the previous
        for (var i = 1; i < delays.length; i++) {
          expect(
            delays[i].inMilliseconds,
            greaterThan(delays[i - 1].inMilliseconds * 1.5),
          );
        }
      });
    });

    group('completeWithCallback', () {
      test('should complete future when callback is invoked', () async {
        late void Function(String) callback;

        final future = AsyncUtils.completeWithCallback<String>((cb) {
          callback = cb;
        });

        // Simulate async operation
        Timer(const Duration(milliseconds: 100), () {
          callback('result');
        });

        final result = await future;
        expect(result, equals('result'));
      });

      test('should handle errors through callback', () async {
        late void Function(String?, Exception?) callback;

        final future = AsyncUtils.completeWithCallbackOrError<String>((cb) {
          callback = cb;
        });

        // Simulate error
        Timer(const Duration(milliseconds: 100), () {
          callback(null, Exception('Test error'));
        });

        await expectLater(future, throwsException);
      });
    });

    group('race', () {
      test('should return result of first completed future', () async {
        final result = await AsyncUtils.race([
          Future.delayed(const Duration(milliseconds: 200), () => 'slow'),
          Future.delayed(const Duration(milliseconds: 50), () => 'fast'),
          Future.delayed(const Duration(milliseconds: 100), () => 'medium'),
        ]);

        expect(result, equals('fast'));
      });

      test('should propagate error if first to complete fails', () async {
        await expectLater(
          AsyncUtils.race([
            Future.delayed(const Duration(milliseconds: 200), () => 'slow'),
            Future.delayed(
              const Duration(milliseconds: 50),
              () => throw Exception('Fast failure'),
            ),
          ]),
          throwsException,
        );
      });
    });
  });
}
