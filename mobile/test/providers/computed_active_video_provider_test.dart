// ABOUTME: Tests for computed active video provider (reactive architecture)
// ABOUTME: Verifies active video is computed from page context and app state, not set imperatively

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/app_foreground_provider.dart';
import 'package:openvine/providers/computed_active_video_provider.dart';
import 'package:openvine/services/video_event_service.dart';
import 'package:openvine/services/nostr_service_interface.dart';
import 'package:openvine/services/subscription_manager.dart';
import 'package:openvine/providers/app_providers.dart';

void main() {
  group('Computed Active Video Provider', () {
    late ProviderContainer container;
    late VideoEventService videoService;

    setUp(() {
      // Create REAL VideoEventService with minimal fake dependencies
      final fakeNostrService = FakeNostrService();
      final fakeSubscriptionManager = FakeSubscriptionManager();

      videoService = VideoEventService(fakeNostrService, subscriptionManager: fakeSubscriptionManager);

      // Inject test videos directly into the service's discovery list
      // Use realistic 64-character hex IDs like Nostr
      final testVideos = [
        VideoEvent(
          id: '1111111111111111111111111111111111111111111111111111111111111111',
          pubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          content: 'Video 1',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          timestamp: DateTime.now(),
          videoUrl: 'https://example.com/v1.mp4',
        ),
        VideoEvent(
          id: '2222222222222222222222222222222222222222222222222222222222222222',
          pubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          content: 'Video 2',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          timestamp: DateTime.now(),
          videoUrl: 'https://example.com/v2.mp4',
        ),
        VideoEvent(
          id: '3333333333333333333333333333333333333333333333333333333333333333',
          pubkey: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          content: 'Video 3',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          timestamp: DateTime.now(),
          videoUrl: 'https://example.com/v3.mp4',
        ),
      ];

      // Use the service's test helper to inject videos
      videoService.injectTestVideos(testVideos);

      container = ProviderContainer(
        overrides: [
          videoEventServiceProvider.overrideWith((ref) => videoService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('activeVideoProvider returns null when app backgrounded', () {
      // SETUP: Set page context to explore screen, page 0
      container.read(currentPageContextProvider.notifier).setContext('explore', 0);

      // VERIFY: Initially returns video 1 (app is foreground by default)
      expect(container.read(activeVideoProvider), equals('1111111111111111111111111111111111111111111111111111111111111111'));

      // ACT: Background the app
      container.read(appForegroundProvider.notifier).setForeground(false);

      // VERIFY: Active video becomes null
      expect(container.read(activeVideoProvider), isNull,
          reason: 'Active video should be null when app is backgrounded');
    });

    test('activeVideoProvider returns correct video ID from context', () {
      // SETUP: No context set initially
      expect(container.read(activeVideoProvider), isNull,
          reason: 'Should be null with no context');

      // ACT: Set context to explore screen, page 0
      container.read(currentPageContextProvider.notifier).setContext('explore', 0);

      // VERIFY: Returns video 1
      expect(container.read(activeVideoProvider), equals('1111111111111111111111111111111111111111111111111111111111111111'));

      // ACT: Change to page 1
      container.read(currentPageContextProvider.notifier).setContext('explore', 1);

      // VERIFY: Returns video 2
      expect(container.read(activeVideoProvider), equals('2222222222222222222222222222222222222222222222222222222222222222'));

      // ACT: Change to page 2
      container.read(currentPageContextProvider.notifier).setContext('explore', 2);

      // VERIFY: Returns video 3
      expect(container.read(activeVideoProvider), equals('3333333333333333333333333333333333333333333333333333333333333333'));
    });

    test('activeVideoProvider returns null when page index out of bounds', () {
      // ACT: Set context with negative page index
      container.read(currentPageContextProvider.notifier).setContext('explore', -1);

      // VERIFY: Returns null
      expect(container.read(activeVideoProvider), isNull,
          reason: 'Should return null for negative page index');

      // ACT: Set context with page index beyond list length
      container.read(currentPageContextProvider.notifier).setContext('explore', 999);

      // VERIFY: Returns null
      expect(container.read(activeVideoProvider), isNull,
          reason: 'Should return null for page index beyond list length');
    });

    test('activeVideoProvider returns null when context is cleared', () {
      // SETUP: Set context
      container.read(currentPageContextProvider.notifier).setContext('explore', 0);
      expect(container.read(activeVideoProvider), equals('1111111111111111111111111111111111111111111111111111111111111111'));

      // ACT: Clear context
      container.read(currentPageContextProvider.notifier).clear();

      // VERIFY: Returns null
      expect(container.read(activeVideoProvider), isNull,
          reason: 'Should return null when context is cleared');
    });

    test('isVideoActiveProvider only true for active video', () {
      // SETUP: Set context to page 1 (video 2)
      container.read(currentPageContextProvider.notifier).setContext('explore', 1);

      // VERIFY: Only video 2 is active
      expect(container.read(isVideoActiveProvider('1111111111111111111111111111111111111111111111111111111111111111')), isFalse);
      expect(container.read(isVideoActiveProvider('2222222222222222222222222222222222222222222222222222222222222222')), isTrue);
      expect(container.read(isVideoActiveProvider('3333333333333333333333333333333333333333333333333333333333333333')), isFalse);

      // ACT: Change to page 0
      container.read(currentPageContextProvider.notifier).setContext('explore', 0);

      // VERIFY: Only video 1 is active
      expect(container.read(isVideoActiveProvider('1111111111111111111111111111111111111111111111111111111111111111')), isTrue);
      expect(container.read(isVideoActiveProvider('2222222222222222222222222222222222222222222222222222222222222222')), isFalse);
      expect(container.read(isVideoActiveProvider('3333333333333333333333333333333333333333333333333333333333333333')), isFalse);
    });

    test('activeVideoProvider handles unknown screenId gracefully', () {
      // ACT: Set context with unknown screenId
      container.read(currentPageContextProvider.notifier).setContext('unknown_screen', 0);

      // VERIFY: Returns null (no videos for unknown screen)
      expect(container.read(activeVideoProvider), isNull,
          reason: 'Should return null for unknown screenId');
    });

    test('activeVideoProvider notifies listeners when context changes', () {
      final states = <String?>[];

      // SETUP: Listen to provider changes BEFORE making changes
      final sub = container.listen(
        activeVideoProvider,
        (previous, next) {
          states.add(next);
        },
        fireImmediately: false,
      );

      // ACT: Set context to page 0
      container.read(currentPageContextProvider.notifier).setContext('explore', 0);

      // Force provider to rebuild
      container.read(activeVideoProvider);

      // ACT: Change to page 1
      container.read(currentPageContextProvider.notifier).setContext('explore', 1);

      // Force provider to rebuild
      container.read(activeVideoProvider);

      // ACT: Background app
      container.read(appForegroundProvider.notifier).setForeground(false);

      // Force provider to rebuild
      container.read(activeVideoProvider);

      // VERIFY: Listener was notified for each change
      expect(states, equals(['1111111111111111111111111111111111111111111111111111111111111111', '2222222222222222222222222222222222222222222222222222222222222222', null]),
          reason: 'Should notify listeners for each state change');

      sub.close();
    });
  });
}

// Minimal fake implementations for testing - just enough to construct VideoEventService
class FakeNostrService implements INostrService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class FakeSubscriptionManager implements SubscriptionManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
