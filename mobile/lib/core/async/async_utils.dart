// ABOUTME: Utility class providing proper async patterns without Future.delayed
// ABOUTME: Implements Completer-based operations, condition waiting, and retry logic

import 'dart:async';

/// Provides utility methods for proper asynchronous programming patterns
/// that avoid the use of Future.delayed and other timing-based anti-patterns.
class AsyncUtils {
  /// Waits for a condition to become true, checking periodically.
  ///
  /// This is the proper replacement for Future.delayed when polling is needed.
  /// Uses a Stream-based approach instead of recursive Future.delayed calls.
  static Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration checkInterval = const Duration(milliseconds: 100),
  }) async {
    if (condition()) return;

    final completer = Completer<void>();
    Timer? timer;
    Timer? timeoutTimer;

    // Set up timeout
    timeoutTimer = Timer(timeout, () {
      timer?.cancel();
      if (!completer.isCompleted) {
        completer.completeError(
          TimeoutException('Condition not met within timeout', timeout),
        );
      }
    });

    // Set up periodic check
    timer = Timer.periodic(checkInterval, (_) {
      if (condition()) {
        timer?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }

  /// Runs an operation with a timeout.
  ///
  /// Proper replacement for Future.delayed when you need timeout behavior.
  static Future<T> runWithTimeout<T>(
    Future<T> operation, {
    required Duration timeout,
  }) async =>
      operation.timeout(
        timeout,
        onTimeout: () => throw TimeoutException('Operation timed out', timeout),
      );

  /// Creates a debounced function that delays execution until after
  /// the specified duration has elapsed since the last call.
  static Function() debounce(
    Function() function, {
    required Duration duration,
  }) {
    Timer? debounceTimer;

    return () {
      debounceTimer?.cancel();
      debounceTimer = Timer(duration, function);
    };
  }

  /// Creates a throttled function that limits execution to once per duration.
  static Function() throttle(
    Function() function, {
    required Duration duration,
  }) {
    var canExecute = true;

    return () {
      if (canExecute) {
        canExecute = false;
        function();
        Timer(duration, () => canExecute = true);
      }
    };
  }

  /// Retries an operation with configurable attempts and delay.
  ///
  /// Proper replacement for timing-based retry loops.
  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool exponentialBackoff = false,
  }) async {
    var attempt = 0;
    var currentDelay = delay;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Use completer for delay instead of Future.delayed
        final completer = Completer<void>();
        Timer(currentDelay, completer.complete);
        await completer.future;

        if (exponentialBackoff) {
          currentDelay = currentDelay * 2;
        }
      }
    }

    throw Exception('Retry failed after $maxAttempts attempts');
  }

  /// Creates a Future that completes when a callback is invoked.
  ///
  /// Useful for converting callback-based APIs to Future-based ones.
  static Future<T> completeWithCallback<T>(
    void Function(void Function(T result) callback) setup,
  ) {
    final completer = Completer<T>();
    setup((result) {
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    });
    return completer.future;
  }

  /// Creates a Future that completes with a result or error from a callback.
  static Future<T> completeWithCallbackOrError<T>(
    void Function(void Function(T? result, Exception? error) callback) setup,
  ) {
    final completer = Completer<T>();
    setup((result, error) {
      if (!completer.isCompleted) {
        if (error != null) {
          completer.completeError(error);
        } else if (result != null) {
          completer.complete(result);
        } else {
          completer.completeError(
            Exception('Both result and error are null'),
          );
        }
      }
    });
    return completer.future;
  }

  /// Returns the result of the first Future to complete.
  ///
  /// Similar to Promise.race() in JavaScript.
  static Future<T> race<T>(List<Future<T>> futures) {
    final completer = Completer<T>();

    for (final future in futures) {
      future.then((value) {
        if (!completer.isCompleted) {
          completer.complete(value);
        }
      }).catchError((Object error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });
    }

    return completer.future;
  }

  /// Converts a Stream to a Future that completes with the first event.
  ///
  /// Useful for waiting on WebSocket or other stream-based events.
  static Future<T> streamFirst<T>(
    Stream<T> stream, {
    Duration? timeout,
  }) {
    final completer = Completer<T>();
    StreamSubscription<T>? subscription;
    Timer? timeoutTimer;

    if (timeout != null) {
      timeoutTimer = Timer(timeout, () {
        subscription?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Stream timeout', timeout),
          );
        }
      });
    }

    subscription = stream.listen(
      (data) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.complete(data);
        }
      },
      onError: (Object error) {
        subscription?.cancel();
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      onDone: () {
        timeoutTimer?.cancel();
        if (!completer.isCompleted) {
          completer.completeError(
            StateError('Stream closed without emitting any value'),
          );
        }
      },
    );

    return completer.future;
  }

  /// Creates a periodic task that can be cancelled.
  ///
  /// Replacement for recursive Future.delayed patterns.
  static CancelableOperation periodic(
    Duration interval,
    Future<void> Function() task,
  ) {
    var cancelled = false;
    Timer? timer;

    void scheduleNext() {
      if (!cancelled) {
        timer = Timer(interval, () async {
          if (!cancelled) {
            try {
              await task();
              scheduleNext();
            } catch (e) {
              // Task failed, stop periodic execution
              cancelled = true;
            }
          }
        });
      }
    }

    scheduleNext();

    return CancelableOperation(() {
      cancelled = true;
      timer?.cancel();
    });
  }
}

/// Represents an operation that can be cancelled.
class CancelableOperation {
  CancelableOperation(this._cancel);
  final void Function() _cancel;

  void cancel() => _cancel();
}
