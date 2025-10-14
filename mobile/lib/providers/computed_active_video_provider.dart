// ABOUTME: Computed active video provider using reactive architecture
// ABOUTME: Active video is derived from page context and app state, never set imperatively

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/app_foreground_provider.dart';
import 'package:openvine/providers/app_providers.dart';
import 'package:openvine/services/video_event_service.dart';

/// Page context - which screen and page are currently showing
class PageContext {
  final String screenId; // 'home', 'explore', 'profile:npub123', 'hashtag:funny'
  final int pageIndex;

  const PageContext({
    required this.screenId,
    required this.pageIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PageContext &&
          runtimeType == other.runtimeType &&
          screenId == other.screenId &&
          pageIndex == other.pageIndex;

  @override
  int get hashCode => screenId.hashCode ^ pageIndex.hashCode;
}

/// Current page context notifier using Riverpod 2.0+ Notifier
class CurrentPageContextNotifier extends Notifier<PageContext?> {
  @override
  PageContext? build() => null;

  void setContext(String screenId, int pageIndex) {
    state = PageContext(screenId: screenId, pageIndex: pageIndex);
  }

  void clear() {
    state = null;
  }
}

/// Current page context provider
final currentPageContextProvider =
    NotifierProvider<CurrentPageContextNotifier, PageContext?>(
  CurrentPageContextNotifier.new,
);

/// Helper: Get videos for a given screen ID
List<VideoEvent> _getVideosForScreen(Ref ref, String screenId) {
  final videoEventService = ref.watch(videoEventServiceProvider);

  if (screenId == 'home') {
    return videoEventService.homeFeedVideos;
  } else if (screenId == 'explore') {
    return videoEventService.discoveryVideos;
  } else if (screenId.startsWith('profile:')) {
    final pubkey = screenId.substring(8);
    return videoEventService.getVideosByAuthor(pubkey);
  } else if (screenId.startsWith('hashtag:')) {
    final tag = screenId.substring(8);
    // For hashtags, filter discovery videos by the tag
    return videoEventService.discoveryVideos
        .where((v) => v.hashtags.contains(tag))
        .toList();
  }

  return [];
}

/// Computed active video ID based on page context and app state
final activeVideoProvider = Provider<String?>((ref) {
  // Check app foreground state
  final isAppForeground = ref.watch(appForegroundProvider);
  if (!isAppForeground) return null;

  // Get current page context
  final pageContext = ref.watch(currentPageContextProvider);
  if (pageContext == null) return null;

  // Look up videos for this screen
  final videos = _getVideosForScreen(ref, pageContext.screenId);

  // Return video ID at current page index
  if (pageContext.pageIndex >= 0 && pageContext.pageIndex < videos.length) {
    return videos[pageContext.pageIndex].id;
  }

  return null;
});

/// Per-video active state (for efficient VideoFeedItem updates)
final isVideoActiveProvider = Provider.family<bool, String>((ref, videoId) {
  final activeVideoId = ref.watch(activeVideoProvider);
  return activeVideoId == videoId;
});
