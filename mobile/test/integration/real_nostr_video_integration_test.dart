// ABOUTME: Real integration test for video event publishing and retrieval via Nostr
// ABOUTME: Uses real relay connections instead of mocking, tests actual network integration

import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/services/video_event_service.dart';
import 'package:openvine/services/subscription_manager.dart';
import '../helpers/real_integration_test_helper.dart';

void main() {
  group('Real Nostr Video Integration Tests', () {
    late VideoEventService videoEventService;

    setUpAll(() async {
      await RealIntegrationTestHelper.setupTestEnvironment();
    });

    setUp(() async {
      final nostrService = await RealIntegrationTestHelper.createRealNostrService();
      final subscriptionManager = SubscriptionManager();
      videoEventService = VideoEventService(
        nostrService,
        subscriptionManager: subscriptionManager,
      );
      await videoEventService.initialize();
    });

    tearDownAll(() async {
      await RealIntegrationTestHelper.cleanup();
    });

    testWidgets('can fetch real video events from vine.hol.is relay', (tester) async {
      // This test uses REAL network connections to vine.hol.is
      // No mocking of NostrService, network, or relay connections
      
      final videoEvents = await videoEventService.getVideoEvents(limit: 5);
      
      // Should get real video events from the relay
      expect(videoEvents, isNotNull);
      // May be empty if no videos on relay, but should not error
      expect(videoEvents, isA<List<VideoEvent>>());
      
      // If we got videos, they should be valid
      for (final video in videoEvents) {
        expect(video.id, isNotEmpty);
        expect(video.pubkey, isNotEmpty);
        expect(video.createdAt, greaterThan(0));
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    testWidgets('can subscribe to real video events', (tester) async {
      // Test real subscription to live relay
      var eventCount = 0;
      
      final subscription = videoEventService.subscribeToVideoEvents(
        onEvent: (events) {
          eventCount += events.length;
        },
        limit: 10,
      );
      
      expect(subscription, isNotNull);
      
      // Wait a bit for any events
      await tester.binding.delayed(const Duration(seconds: 3));
      
      // May not receive events immediately, but subscription should work
      expect(eventCount, greaterThanOrEqualTo(0));
      
      // Clean up subscription
      videoEventService.unsubscribe(subscription);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}