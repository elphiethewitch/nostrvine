// ABOUTME: Main orchestrator provider that coordinates video feed state
// ABOUTME: Replaces VideoEventBridge with reactive provider-based architecture

import 'dart:async';

import 'package:openvine/constants/app_constants.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/app_providers.dart';
import 'package:openvine/providers/curation_providers.dart';
import 'package:openvine/providers/feed_mode_providers.dart';
import 'package:openvine/providers/social_providers.dart' as social;
import 'package:openvine/providers/user_profile_providers.dart';
import 'package:openvine/providers/video_events_providers.dart';
import 'package:openvine/state/video_feed_state.dart';
import 'package:openvine/utils/unified_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_feed_provider.g.dart';

/// Main video feed provider that orchestrates all video-related state
@riverpod
class VideoFeed extends _$VideoFeed {
  Timer? _profileFetchTimer;

  @override
  Future<VideoFeedState> build() async {
    // Clean up timer on dispose
    ref.onDispose(() {
      _profileFetchTimer?.cancel();
    });

    // Watch dependencies - auto-updates when they change
    final feedMode = ref.watch(feedModeNotifierProvider);
    final feedContext = ref.watch(feedContextProvider);
    final socialData = ref.watch(social.socialNotifierProvider);

    // Get videos based on feed mode
    List<VideoEvent> sourceVideos;
    if (feedMode == FeedMode.curated) {
      // For curated mode, get videos from curation provider (includes editor's picks fallback)
      final curationState = ref.watch(curationProvider);
      sourceVideos = curationState.editorsPicks;
      Log.info(
        'VideoFeed: Using curated videos (${sourceVideos.length} editor picks)',
        name: 'VideoFeedProvider',
        category: LogCategory.video,
      );
    } else {
      // For other modes, use video events from Nostr
      sourceVideos = await ref.watch(videoEventsProvider.future);
      Log.info(
        'VideoFeed: Building with mode=$feedMode, context=$feedContext, videos=${sourceVideos.length}',
        name: 'VideoFeedProvider',
        category: LogCategory.video,
      );
    }

    // Determine primary content source
    final primaryPubkeys =
        _getPrimaryPubkeys(feedMode, socialData.followingPubkeys, feedContext);

    // Filter and sort videos
    final filteredVideos =
        _filterVideos(sourceVideos, feedMode, primaryPubkeys, feedContext);
    final sortedVideos = _sortVideos(filteredVideos, feedMode);

    // Auto-fetch profiles for new videos
    _scheduleBatchProfileFetch(sortedVideos);

    // Calculate metrics
    final primaryVideoCount = _countPrimaryVideos(sortedVideos, primaryPubkeys);
    final hasMoreContent = _hasMoreContent(sortedVideos);

    return VideoFeedState(
      videos: sortedVideos,
      feedMode: feedMode,
      isFollowingFeed: feedMode == FeedMode.following,
      hasMoreContent: hasMoreContent,
      primaryVideoCount: primaryVideoCount,
      isLoadingMore: false,
      feedContext: feedContext,
      error: null, // Error handling will be done by AsyncNotifier
      lastUpdated: DateTime.now(),
    );
  }

  Set<String> _getPrimaryPubkeys(
          FeedMode mode, List<String> followingList, String? context) =>
      switch (mode) {
        FeedMode.following => followingList.toSet(),
        FeedMode.curated => {AppConstants.classicVinesPubkey},
        FeedMode.profile => context != null ? {context} : {},
        _ => {}, // Discovery and hashtag modes have no primary pubkeys
      };

  List<VideoEvent> _filterVideos(
    List<VideoEvent> videos,
    FeedMode mode,
    Set<String> primaryPubkeys,
    String? context,
  ) {
    switch (mode) {
      case FeedMode.following:
        // Filter by primary pubkeys
        return videos.where((v) => primaryPubkeys.contains(v.pubkey)).toList();

      case FeedMode.curated:
        // Videos are already curated, no additional filtering needed
        return videos;

      case FeedMode.profile:
        // Filter by specific author
        return context != null
            ? videos.where((v) => v.pubkey == context).toList()
            : [];

      case FeedMode.hashtag:
        // Filter by hashtag
        return context != null
            ? videos.where((v) => v.hashtags.contains(context)).toList()
            : [];

      case FeedMode.discovery:
        // Include all videos
        return videos;
    }
  }

  List<VideoEvent> _sortVideos(List<VideoEvent> videos, FeedMode mode) {
    // Always sort by creation time (newest first)
    final sorted = List<VideoEvent>.from(videos);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Additional sorting logic could be added here based on mode
    // For example, trending videos could be sorted by engagement

    return sorted;
  }

  void _scheduleBatchProfileFetch(List<VideoEvent> videos) {
    // Cancel any existing timer
    _profileFetchTimer?.cancel();

    // Schedule profile fetch after a short delay to batch requests
    _profileFetchTimer = Timer(const Duration(milliseconds: 100), () {
      final profilesProvider = ref.read(userProfileNotifierProvider.notifier);

      final newPubkeys = videos
          .map((v) => v.pubkey)
          .where((pubkey) => !profilesProvider.hasProfile(pubkey))
          .toSet()
          .toList();

      if (newPubkeys.isNotEmpty) {
        Log.debug(
          'VideoFeed: Fetching ${newPubkeys.length} new profiles',
          name: 'VideoFeedProvider',
          category: LogCategory.video,
        );

        // Profile provider handles deduplication internally
        profilesProvider.fetchMultipleProfiles(newPubkeys);
      }
    });
  }

  int _countPrimaryVideos(List<VideoEvent> videos, Set<String> primaryPubkeys) {
    if (primaryPubkeys.isEmpty) return 0;
    return videos.where((v) => primaryPubkeys.contains(v.pubkey)).length;
  }

  bool _hasMoreContent(List<VideoEvent> videos) {
    // If we have very few videos, likely more content is available
    if (videos.length < 20) return true;
    
    // For larger lists, we assume more content is available
    // The actual end-of-content detection happens in loadMore() 
    // when no new events are returned
    return true;
  }

  /// Load more historical events
  Future<void> loadMore() async {
    final currentState = await future;
    
    Log.info(
      'VideoFeed: loadMore() called - isLoadingMore: ${currentState.isLoadingMore}, isRefreshing: ${currentState.isRefreshing}',
      name: 'VideoFeedProvider',
      category: LogCategory.video,
    );
    
    if (currentState.isLoadingMore || currentState.isRefreshing) {
      Log.info(
        'VideoFeed: Skipping loadMore() - already loading or refreshing',
        name: 'VideoFeedProvider',
        category: LogCategory.video,
      );
      return;
    }

    // Update state to show loading
    state = AsyncData(currentState.copyWith(isLoadingMore: true));

    try {
      final feedMode = ref.read(feedModeNotifierProvider);
      
      Log.info(
        'VideoFeed: Starting to load more events for mode: $feedMode',
        name: 'VideoFeedProvider',
        category: LogCategory.video,
      );
      
      // Use VideoEventService for pagination in all modes
      final videoEventService = ref.read(videoEventServiceProvider);
      final eventCountBefore = videoEventService.eventCount;
      
      await videoEventService.loadMoreEvents(limit: 50);
      
      final eventCountAfter = videoEventService.eventCount;
      final newEventsLoaded = eventCountAfter - eventCountBefore;

      Log.info(
        'VideoFeed: Loaded $newEventsLoaded new events (total: $eventCountAfter)',
        name: 'VideoFeedProvider',
        category: LogCategory.video,
      );

      // If no new events were loaded, we've reached the end
      if (newEventsLoaded == 0) {
        Log.info(
          'VideoFeed: No new events loaded - reached end of content',
          name: 'VideoFeedProvider',
          category: LogCategory.video,
        );
      }
      
      // Reset loading state - state will auto-update via dependencies
      final newState = await future;
      state = AsyncData(newState.copyWith(isLoadingMore: false));
    } catch (e) {
      Log.error(
        'VideoFeed: Error loading more: $e',
        name: 'VideoFeedProvider',
        category: LogCategory.video,
      );

      // Update state with error
      final currentState = await future;
      state = AsyncData(
        currentState.copyWith(
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  /// Refresh the feed
  Future<void> refresh() async {
    Log.info(
      'VideoFeed: Refreshing feed',
      name: 'VideoFeedProvider',
      category: LogCategory.video,
    );

    // Invalidate video events to force refresh
    ref.invalidate(videoEventsProvider);

    // Invalidate self to rebuild
    ref.invalidateSelf();
  }

  /// Update feed mode (convenience method)
  void setFeedMode(FeedMode mode) {
    ref.read(feedModeNotifierProvider.notifier).setMode(mode);
  }

  /// Set hashtag mode with context
  void setHashtagMode(String hashtag) {
    ref.read(feedModeNotifierProvider.notifier).setHashtagMode(hashtag);
  }

  /// Set profile mode with context
  void setProfileMode(String pubkey) {
    ref.read(feedModeNotifierProvider.notifier).setProfileMode(pubkey);
  }
}

/// Provider to check if video feed is loading
@riverpod
bool videoFeedLoading(Ref ref) {
  final asyncState = ref.watch(videoFeedProvider);
  if (asyncState.isLoading) return true;

  final state = asyncState.valueOrNull;
  if (state == null) return false;

  return state.isLoadingMore || state.isRefreshing;
}

/// Provider to get current video count
@riverpod
int videoFeedCount(Ref ref) =>
    ref.watch(videoFeedProvider).valueOrNull?.videos.length ?? 0;

/// Provider to get current feed mode
@riverpod
FeedMode currentFeedMode(Ref ref) =>
    ref.watch(feedModeNotifierProvider);

/// Provider to check if we have videos
@riverpod
bool hasVideos(Ref ref) {
  final count = ref.watch(videoFeedCountProvider);
  return count > 0;
}
