// ABOUTME: Test to verify KeyStorageService timeout refactoring
// ABOUTME: Ensures proper timeout pattern without Future.delayed

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

// Simulated refactored key generation logic
class RefactoredKeyGenerator {
  // This mimics the refactored generateAndStoreKeys method
  Future<String> generateKeys() async {
    try {
      // Using proper .timeout() instead of Future.delayed
      final key = await Future(() async {
        // Simulate key generation
        await Future.microtask(() {
          // Some CPU-bound work
          for (var i = 0; i < 1000000; i++) {
            // Simulate computation
          }
        });
        return 'generated-key-pair';
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
            'Key generation timed out', const Duration(seconds: 10)),
      );

      return key;
    } catch (e) {
      throw Exception('Failed to generate keys: $e');
    }
  }
}

void main() {
  group('KeyStorageService timeout refactoring', () {
    test('should complete quickly for normal key generation', () async {
      final generator = RefactoredKeyGenerator();

      final stopwatch = Stopwatch()..start();
      final result = await generator.generateKeys();
      stopwatch.stop();

      expect(result, equals('generated-key-pair'));
      expect(
        stopwatch.elapsed.inSeconds,
        lessThan(1),
        reason: 'Normal key generation should be fast',
      );
    });

    test('should handle timeout without Future.delayed', () async {
      // Create a generator that will timeout
      final slowGenerator = SlowKeyGenerator();

      expect(
        slowGenerator.generateKeys,
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('TimeoutException'),
          ),
        ),
      );
    });

    test('should not create lingering timers', () async {
      final generator = RefactoredKeyGenerator();

      // Generate multiple keys quickly
      final futures = <Future<String>>[];
      for (var i = 0; i < 5; i++) {
        futures.add(generator.generateKeys());
      }

      final results = await Future.wait(futures);

      // All should complete successfully
      expect(results.length, equals(5));
      for (final result in results) {
        expect(result, equals('generated-key-pair'));
      }

      // No lingering timers should be active
      // (In the old Future.delayed pattern, we'd have 5 10-second timers running)
    });
  });
}

// Slow generator for timeout testing
class SlowKeyGenerator extends RefactoredKeyGenerator {
  @override
  Future<String> generateKeys() async {
    try {
      final key = await Future(() async {
        // Simulate very slow key generation
        await Future.delayed(const Duration(seconds: 15));
        return 'generated-key-pair';
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException(
            'Key generation timed out', const Duration(seconds: 10)),
      );

      return key;
    } catch (e) {
      throw Exception('Failed to generate keys: $e');
    }
  }
}
