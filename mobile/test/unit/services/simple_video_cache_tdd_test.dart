// ABOUTME: Simplified TDD test for extracting video caching logic
// ABOUTME: Focuses on core caching functionality without complex dependencies

import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/services/video_cache_service.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('VideoCacheService TDD', () {
    late VideoCacheService cache;

    setUp(() {
      cache = VideoCacheService();
    });

    test('should start with empty cache', () {
      expect(cache.cacheSize, equals(0));
      expect(cache.cachedVideos, isEmpty);
    });

    test('should add video to cache', () {
      final video = TestHelpers.createVideoEvent(
        id: 'test-1',
        title: 'Test Video',
        pubkey: 'user123',
      );

      cache.addVideo(video);

      expect(cache.cacheSize, equals(1));
      expect(cache.containsVideo('test-1'), isTrue);
    });

    test('should prevent duplicate videos', () {
      final video = TestHelpers.createVideoEvent(
        id: 'test-1',
        title: 'Test Video',
        pubkey: 'user123',
      );

      cache.addVideo(video);
      cache.addVideo(video); // Add same video again

      expect(cache.cacheSize, equals(1)); // Should still be 1
      expect(cache.duplicateCount, equals(1)); // One duplicate attempt
    });

    test('should clear cache', () {
      final video = TestHelpers.createVideoEvent(
        id: 'test-1',
        title: 'Test Video',
        pubkey: 'user123',
      );

      cache.addVideo(video);
      expect(cache.cacheSize, equals(1));

      cache.clearCache();

      expect(cache.cacheSize, equals(0));
      expect(cache.cachedVideos, isEmpty);
    });
  });
}
