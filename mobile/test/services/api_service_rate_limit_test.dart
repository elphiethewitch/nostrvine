// ABOUTME: Tests for ApiService with rate limiting integration
// ABOUTME: Ensures API calls are properly rate limited

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openvine/services/api_service.dart';
import 'package:openvine/services/network/rate_limiter.dart';

void main() {
  group('ApiService with RateLimiter', () {
    late ApiService apiService;
    late RateLimiter rateLimiter;
    late http.Client mockClient;

    setUp(() {
      rateLimiter = RateLimiter();
    });

    tearDown(() {
      rateLimiter.dispose();
    });

    test('should rate limit getReadyEvents calls', () async {
      // Arrange
      var callCount = 0;
      mockClient = MockClient((request) async {
        callCount++;
        return http.Response(
          jsonEncode({'events': []}),
          200,
        );
      });

      apiService = ApiService(
        client: mockClient,
        rateLimiter: rateLimiter,
      );

      // Configure aggressive rate limit for testing
      rateLimiter.configureEndpoint(
        '/v1/media/ready-events',
        const RateLimitConfig(3, Duration(seconds: 10)),
      );

      // Act - Make 3 requests (should succeed)
      for (var i = 0; i < 3; i++) {
        await apiService.getReadyEvents();
      }
      expect(callCount, 3);

      // Assert - 4th request should be rate limited
      expect(
        () => apiService.getReadyEvents(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having(
                  (e) => e.message, 'message', contains('Rate limit exceeded')),
        ),
      );
      expect(callCount, 3); // No additional HTTP call made
    });

    test('should rate limit cleanupRemoteEvent calls', () async {
      // Arrange
      var callCount = 0;
      mockClient = MockClient((request) async {
        callCount++;
        return http.Response('', 204);
      });

      apiService = ApiService(
        client: mockClient,
        rateLimiter: rateLimiter,
      );

      // Configure rate limit for cleanup endpoint
      rateLimiter.configureEndpoint(
        '/v1/media/cleanup',
        const RateLimitConfig(2, Duration(seconds: 10)),
      );

      // Act - Make 2 requests (should succeed)
      await apiService.cleanupRemoteEvent('test-id-1');
      await apiService.cleanupRemoteEvent('test-id-2');
      expect(callCount, 2);

      // Assert - 3rd request should be rate limited
      expect(
        () => apiService.cleanupRemoteEvent('test-id-3'),
        throwsA(isA<ApiException>()),
      );
      expect(callCount, 2);
    });

    test('should handle rate limit status check', () {
      // Arrange
      mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'events': []}),
          200,
        ),
      );

      apiService = ApiService(
        client: mockClient,
        rateLimiter: rateLimiter,
      );

      // Act
      final status = apiService.getRateLimitStatus('/v1/media/ready-events');

      // Assert
      expect(status, isNotNull);
      expect(status!.limit, 100);
      expect(status.remaining, 100);
      expect(status.used, 0);
    });

    test('should work without rate limiter (backward compatibility)', () async {
      // Arrange
      mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'events': []}),
          200,
        ),
      );

      // Create ApiService without rate limiter
      apiService = ApiService(
        client: mockClient,
      );

      // Act & Assert - Should work normally
      await expectLater(
        apiService.getReadyEvents(),
        completes,
      );
    });

    test('should emit rate limit violations for monitoring', () async {
      // Arrange
      mockClient = MockClient(
        (request) async => http.Response(
          jsonEncode({'events': []}),
          200,
        ),
      );

      apiService = ApiService(
        client: mockClient,
        rateLimiter: rateLimiter,
      );

      // Configure very low limit
      rateLimiter.configureEndpoint(
        '/v1/media/ready-events',
        const RateLimitConfig(1, Duration(minutes: 1)),
      );

      // Listen for violations
      final violations = <RateLimitViolation>[];
      rateLimiter.violations.listen(violations.add);

      // Act
      await apiService.getReadyEvents(); // First request OK
      try {
        await apiService.getReadyEvents(); // Should violate
      } catch (_) {
        // Expected
      }

      // Assert
      expect(violations.length, 1);
      expect(violations.first.endpoint, '/v1/media/ready-events');
    });
  });
}
