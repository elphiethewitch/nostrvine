// ABOUTME: Tests for RateLimiter service implementing API rate limiting
// ABOUTME: Validates rate limit enforcement, window management, and error handling

import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/services/api_service.dart';
import 'package:openvine/services/network/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter rateLimiter;

    setUp(() {
      rateLimiter = RateLimiter();
    });

    tearDown(() {
      rateLimiter.dispose();
    });

    group('Basic Rate Limiting', () {
      test('should allow requests within rate limit', () async {
        // Should allow first request
        await expectLater(
          rateLimiter.checkLimit('/v1/media/ready-events'),
          completes,
        );

        // Should allow second request (limit is 100/min)
        await expectLater(
          rateLimiter.checkLimit('/v1/media/ready-events'),
          completes,
        );
      });

      test('should enforce rate limit for specific endpoint', () async {
        // Configure a test endpoint with low limit
        rateLimiter.configureEndpoint(
          '/test/endpoint',
          const RateLimitConfig(2, Duration(minutes: 1)),
        );

        // First two requests should succeed
        await rateLimiter.checkLimit('/test/endpoint');
        await rateLimiter.checkLimit('/test/endpoint');

        // Third request should fail
        await expectLater(
          rateLimiter.checkLimit('/test/endpoint'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.message, 'message',
                    contains('Rate limit exceeded'))
                .having((e) => e.statusCode, 'statusCode', 429),
          ),
        );
      });

      test('should use default config for unknown endpoints', () async {
        // Unknown endpoint should use default (200/min)
        for (var i = 0; i < 200; i++) {
          await rateLimiter.checkLimit('/unknown/endpoint');
        }

        // 201st request should fail
        await expectLater(
          rateLimiter.checkLimit('/unknown/endpoint'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Time Window Management', () {
      test('should reset limit after time window expires', () async {
        // Configure short window for testing
        rateLimiter.configureEndpoint(
          '/test/reset',
          const RateLimitConfig(1, Duration(milliseconds: 100)),
        );

        // First request succeeds
        await rateLimiter.checkLimit('/test/reset');

        // Second request fails immediately
        await expectLater(
          rateLimiter.checkLimit('/test/reset'),
          throwsA(isA<ApiException>()),
        );

        // Wait for window to expire
        await Future.delayed(const Duration(milliseconds: 150));

        // Request should succeed again
        await expectLater(
          rateLimiter.checkLimit('/test/reset'),
          completes,
        );
      });

      test('should track requests per endpoint independently', () async {
        rateLimiter.configureEndpoint(
            '/endpoint1', const RateLimitConfig(1, Duration(minutes: 1)));
        rateLimiter.configureEndpoint(
            '/endpoint2', const RateLimitConfig(1, Duration(minutes: 1)));

        // Use limit on endpoint1
        await rateLimiter.checkLimit('/endpoint1');

        // endpoint2 should still be available
        await expectLater(
          rateLimiter.checkLimit('/endpoint2'),
          completes,
        );

        // endpoint1 should be rate limited
        await expectLater(
          rateLimiter.checkLimit('/endpoint1'),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Configuration', () {
      test('should have correct default configurations', () {
        // Test defaults by checking status
        final readyEventsStatus =
            rateLimiter.getStatus('/v1/media/ready-events');
        expect(readyEventsStatus.limit, 100);

        final uploadStatus = rateLimiter.getStatus('/v1/media/request-upload');
        expect(uploadStatus.limit, 10);

        final cleanupStatus = rateLimiter.getStatus('/v1/media/cleanup');
        expect(cleanupStatus.limit, 50);
      });

      test('should allow updating configurations', () {
        rateLimiter.configureEndpoint(
          '/v1/media/ready-events',
          const RateLimitConfig(200, Duration(minutes: 2)),
        );

        final status = rateLimiter.getStatus('/v1/media/ready-events');
        expect(status.limit, 200);
      });
    });

    group('Error Messages', () {
      test('should provide helpful error message with retry time', () async {
        rateLimiter.configureEndpoint(
          '/test/error',
          const RateLimitConfig(1, Duration(minutes: 5)),
        );

        await rateLimiter.checkLimit('/test/error');

        try {
          await rateLimiter.checkLimit('/test/error');
          fail('Should have thrown ApiException');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiError = e as ApiException;
          expect(apiError.message, contains('Try again in 5 minutes'));
        }
      });
    });

    group('Memory Management', () {
      test('should clean up old request records', () async {
        // Configure with short window
        rateLimiter.configureEndpoint(
          '/test/cleanup',
          const RateLimitConfig(1000, Duration(milliseconds: 50)),
        );

        // Make many requests
        for (var i = 0; i < 10; i++) {
          await rateLimiter.checkLimit('/test/cleanup');
        }

        // Wait for window to expire
        await Future.delayed(const Duration(milliseconds: 100));

        // Make another request to trigger cleanup
        await rateLimiter.checkLimit('/test/cleanup');

        // Verify old records are cleaned (indirectly by checking status)
        final status = rateLimiter.getStatus('/test/cleanup');
        expect(status.used, lessThanOrEqualTo(1));
      });
    });

    group('Statistics', () {
      test('should track request counts per endpoint', () async {
        await rateLimiter.checkLimit('/endpoint1');
        await rateLimiter.checkLimit('/endpoint1');
        await rateLimiter.checkLimit('/endpoint2');

        final status1 = rateLimiter.getStatus('/endpoint1');
        final status2 = rateLimiter.getStatus('/endpoint2');
        expect(status1.used, 2);
        expect(status2.used, 1);
      });

      test('should provide rate limit status', () async {
        rateLimiter.configureEndpoint(
          '/test/status',
          const RateLimitConfig(5, Duration(minutes: 1)),
        );

        // Make 3 requests
        for (var i = 0; i < 3; i++) {
          await rateLimiter.checkLimit('/test/status');
        }

        final status = rateLimiter.getStatus('/test/status');
        expect(status.used, 3);
        expect(status.limit, 5);
        expect(status.remaining, 2);
        expect(status.resetTime, isNotNull);
      });
    });

    group('Integration Helpers', () {
      test('should provide middleware function for easy integration', () async {
        // Test the middleware wrapper
        var requestCount = 0;

        Future<String> makeRequest() async {
          await rateLimiter.checkLimit('/test/middleware');
          requestCount++;
          return 'success';
        }

        // Configure tight limit
        rateLimiter.configureEndpoint(
          '/test/middleware',
          const RateLimitConfig(2, Duration(minutes: 1)),
        );

        // First two should succeed
        expect(await makeRequest(), 'success');
        expect(await makeRequest(), 'success');
        expect(requestCount, 2);

        // Third should fail
        await expectLater(makeRequest(), throwsA(isA<ApiException>()));
        expect(requestCount, 2); // Should not increment
      });
    });
  });
}
