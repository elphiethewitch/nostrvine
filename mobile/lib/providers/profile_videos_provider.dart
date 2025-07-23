// ABOUTME: Riverpod provider for managing user-specific video fetching and grid display
// ABOUTME: Fetches Kind 34550 video events by author with pagination and caching

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/app_providers.dart';
import 'package:openvine/utils/unified_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_videos_provider.g.dart';

/// State for profile videos provider
class ProfileVideosState {
  const ProfileVideosState({
    required this.videos,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.error,
    required this.lastTimestamp,
  });

  final List<VideoEvent> videos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final int? lastTimestamp;

  ProfileVideosState copyWith({
    List<VideoEvent>? videos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    int? lastTimestamp,
  }) =>
      ProfileVideosState(
        videos: videos ?? this.videos,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
        lastTimestamp: lastTimestamp ?? this.lastTimestamp,
      );

  static const initial = ProfileVideosState(
    videos: [],
    isLoading: false,
    isLoadingMore: false,
    hasMore: true,
    error: null,
    lastTimestamp: null,
  );

  bool get hasVideos => videos.isNotEmpty;
  bool get hasError => error != null;
  int get videoCount => videos.length;
}

// Cache for different users' videos
final Map<String, List<VideoEvent>> _profileVideosCache = {};
final Map<String, DateTime> _profileVideosCacheTimestamps = {};
final Map<String, bool> _profileVideosHasMoreCache = {};
const Duration _profileVideosCacheExpiry = Duration(minutes: 10);

// Pagination settings
const int _profileVideosPageSize = 200;

/// Get cached videos if available and not expired
List<VideoEvent>? _getCachedProfileVideos(String pubkey) {
  final videos = _profileVideosCache[pubkey];
  final timestamp = _profileVideosCacheTimestamps[pubkey];

  if (videos != null && timestamp != null) {
    final age = DateTime.now().difference(timestamp);
    if (age < _profileVideosCacheExpiry) {
      Log.debug(
          '📱 Using cached videos for ${pubkey.substring(0, 8)} (age: ${age.inMinutes}min)',
          name: 'ProfileVideosProvider',
          category: LogCategory.ui);
      return videos;
    } else {
      Log.debug(
          '⏰ Video cache expired for ${pubkey.substring(0, 8)} (age: ${age.inMinutes}min)',
          name: 'ProfileVideosProvider',
          category: LogCategory.ui);
      _clearProfileVideosCache(pubkey);
    }
  }

  return null;
}

/// Cache videos for a user
void _cacheProfileVideos(String pubkey, List<VideoEvent> videos, bool hasMore) {
  _profileVideosCache[pubkey] = videos;
  _profileVideosCacheTimestamps[pubkey] = DateTime.now();
  _profileVideosHasMoreCache[pubkey] = hasMore;
  Log.debug('📱 Cached ${videos.length} videos for ${pubkey.substring(0, 8)}',
      name: 'ProfileVideosProvider', category: LogCategory.ui);
}

/// Clear cache for a specific user
void _clearProfileVideosCache(String pubkey) {
  _profileVideosCache.remove(pubkey);
  _profileVideosCacheTimestamps.remove(pubkey);
  _profileVideosHasMoreCache.remove(pubkey);
}

/// Clear all cached videos
void clearAllProfileVideosCache() {
  _profileVideosCache.clear();
  _profileVideosCacheTimestamps.clear();
  _profileVideosHasMoreCache.clear();
  Log.debug('📱 Cleared all profile videos cache',
      name: 'ProfileVideosProvider', category: LogCategory.ui);
}

/// Async provider for loading profile videos
@riverpod
Future<List<VideoEvent>> profileVideos(Ref ref, String pubkey) async {
  // Check cache first
  final cached = _getCachedProfileVideos(pubkey);
  if (cached != null) {
    return cached;
  }

  // Get services from app providers
  final nostrService = ref.watch(nostrServiceProvider);
  final videoEventService = ref.watch(videoEventServiceProvider);

  Log.info('📱 Loading videos for user: ${pubkey.substring(0, 8)}... (full: ${pubkey.substring(0, 16)})',
      name: 'ProfileVideosProvider', category: LogCategory.ui);

  try {
    // First check if we have videos in the VideoEventService cache
    final cachedVideos = videoEventService.getVideosByAuthor(pubkey);
    final allVideos = videoEventService.videoEvents;
    
    Log.info('📱 VideoEventService has ${allVideos.length} total videos in cache',
        name: 'ProfileVideosProvider', category: LogCategory.ui);
    
    if (allVideos.isNotEmpty) {
      Log.info('📱 Sample video authors from cache: ${allVideos.take(3).map((v) => v.pubkey.substring(0, 16)).join(", ")}',
          name: 'ProfileVideosProvider', category: LogCategory.ui);
    }
    
    if (cachedVideos.isNotEmpty) {
      Log.info(
          '📱 Found ${cachedVideos.length} cached videos for ${pubkey.substring(0, 8)}',
          name: 'ProfileVideosProvider',
          category: LogCategory.ui);
      
      final sortedVideos = List<VideoEvent>.from(cachedVideos)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _cacheProfileVideos(pubkey, sortedVideos, true);
      return sortedVideos;
    } else {
      Log.info('📱 No cached videos found for ${pubkey.substring(0, 8)} in VideoEventService',
          name: 'ProfileVideosProvider', category: LogCategory.ui);
    }

    // If no cached videos, fetch from network
    final filter = Filter(
      authors: [pubkey],
      kinds: [22], // NIP-71 short videos (corrected from 34550)
      h: ['vine'], // Required vine tag for vine.hol.is relay
      limit: _profileVideosPageSize,
    );
    
    Log.info('📱 Querying for videos: authors=[${pubkey.substring(0, 16)}], kinds=[22], h=[vine], limit=$_profileVideosPageSize',
        name: 'ProfileVideosProvider', category: LogCategory.ui);

    final completer = Completer<List<VideoEvent>>();
    final events = <Event>[];

    final subscription = nostrService.subscribeToEvents(
      filters: [filter],
    );

    subscription.listen(
      (event) {
        events.add(event);
      },
      onError: (error) {
        Log.error('Error fetching profile videos: $error',
            name: 'ProfileVideosProvider', category: LogCategory.ui);
        if (!completer.isCompleted) {
          completer.complete([]);
        }
      },
      onDone: () {
        Log.info('📱 Query completed: received ${events.length} events for ${pubkey.substring(0, 8)}',
            name: 'ProfileVideosProvider', category: LogCategory.ui);
        
        final videos = events
            .map((event) => VideoEvent.fromNostrEvent(event))
            .toList();
        
        Log.info('📱 Successfully parsed ${videos.length} videos for ${pubkey.substring(0, 8)}',
            name: 'ProfileVideosProvider', category: LogCategory.ui);
        
        if (!completer.isCompleted) {
          completer.complete(videos);
        }
      },
    );

    // Timeout for fetching
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        final videos = events
            .map((event) => VideoEvent.fromNostrEvent(event))
            .toList();
        completer.complete(videos);
      }
    });

    final videos = await completer.future;

    // Sort by creation time (newest first)
    videos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Cache the results
    _cacheProfileVideos(pubkey, videos, videos.length >= _profileVideosPageSize);

    Log.info('📱 Loaded ${videos.length} videos for ${pubkey.substring(0, 8)}',
        name: 'ProfileVideosProvider', category: LogCategory.ui);

    return videos;
  } catch (e) {
    Log.error('Error loading profile videos: $e',
        name: 'ProfileVideosProvider', category: LogCategory.ui);
    rethrow;
  }
}

/// Notifier for managing profile videos state
@riverpod
class ProfileVideosNotifier extends _$ProfileVideosNotifier {
  String? _currentPubkey;
  Completer<void>? _loadingCompleter;

  @override
  ProfileVideosState build() {
    return ProfileVideosState.initial;
  }

  /// Load videos for a specific user
  Future<void> loadVideosForUser(String pubkey) async {
    if (_currentPubkey == pubkey && state.hasVideos && !state.hasError) {
      // Already loaded for this user
      return;
    }

    // Prevent concurrent loads for the same user
    if (_loadingCompleter != null && _currentPubkey == pubkey) {
      return _loadingCompleter!.future;
    }

    _loadingCompleter = Completer<void>();
    _currentPubkey = pubkey;

    // Check cache first
    final cached = _getCachedProfileVideos(pubkey);
    if (cached != null) {
      state = state.copyWith(
        videos: cached,
        isLoading: false,
        hasMore: _profileVideosHasMoreCache[pubkey] ?? true,
        error: null,
      );
      _loadingCompleter!.complete();
      _loadingCompleter = null;
      return;
    }

    state = state.copyWith(
      isLoading: true,
      videos: [],
      error: null,
      hasMore: true,
      lastTimestamp: null,
    );

    try {
      final videos = await ref.read(profileVideosProvider(pubkey).future);
      state = state.copyWith(
        videos: videos,
        isLoading: false,
        hasMore: videos.length >= _profileVideosPageSize,
        lastTimestamp: videos.isNotEmpty ? videos.last.createdAt : null,
      );
      _loadingCompleter!.complete();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      _loadingCompleter!.completeError(e);
    } finally {
      _loadingCompleter = null;
    }
  }

  /// Load more videos (pagination)
  Future<void> loadMoreVideos() async {
    if (_currentPubkey == null || 
        state.isLoadingMore || 
        !state.hasMore || 
        state.lastTimestamp == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final nostrService = ref.read(nostrServiceProvider);
      
      final filter = Filter(
        authors: [_currentPubkey!],
        kinds: [22], // Corrected from 34550
        h: ['vine'],
        until: state.lastTimestamp! - 1, // Load older videos
        limit: _profileVideosPageSize,
      );

      final completer = Completer<List<VideoEvent>>();
      final events = <Event>[];

      final subscription = nostrService.subscribeToEvents(
        filters: [filter],
      );

      subscription.listen(
        (event) {
          events.add(event);
        },
        onError: (error) {
          Log.error('Error loading more videos: $error',
              name: 'ProfileVideosProvider', category: LogCategory.ui);
          if (!completer.isCompleted) {
            completer.complete([]);
          }
        },
        onDone: () {
          final videos = events
              .map((event) => VideoEvent.fromNostrEvent(event))
              .toList();
          
          if (!completer.isCompleted) {
            completer.complete(videos);
          }
        },
      );

      // Timeout for fetching
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          final videos = events
              .map((event) => VideoEvent.fromNostrEvent(event))
              .toList();
          completer.complete(videos);
        }
      });

      final newVideos = await completer.future;

      // Sort new videos
      newVideos.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Combine with existing videos
      final allVideos = <VideoEvent>[...state.videos, ...newVideos];
      final hasMore = newVideos.length >= _profileVideosPageSize;

      // Update cache
      _cacheProfileVideos(_currentPubkey!, allVideos, hasMore);

      state = state.copyWith(
        videos: allVideos,
        isLoadingMore: false,
        hasMore: hasMore,
        lastTimestamp: allVideos.isNotEmpty ? allVideos.last.createdAt : null,
      );

      Log.info('📱 Loaded ${newVideos.length} more videos (total: ${allVideos.length})',
          name: 'ProfileVideosProvider', category: LogCategory.ui);
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
      Log.error('Error loading more videos: $e',
          name: 'ProfileVideosProvider', category: LogCategory.ui);
    }
  }

  /// Refresh videos by clearing cache and reloading
  Future<void> refreshVideos() async {
    if (_currentPubkey != null) {
      _clearProfileVideosCache(_currentPubkey!);
      ref.invalidate(profileVideosProvider(_currentPubkey!));
      await loadVideosForUser(_currentPubkey!);
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Add a new video to the current list (for optimistic updates)
  void addVideo(VideoEvent video) {
    if (_currentPubkey != null && video.pubkey == _currentPubkey) {
      final updatedVideos = [video, ...state.videos];
      state = state.copyWith(videos: updatedVideos);
      
      // Update cache
      _cacheProfileVideos(_currentPubkey!, updatedVideos, state.hasMore);
    }
  }

  /// Remove a video from the current list
  void removeVideo(String videoId) {
    final updatedVideos = state.videos.where((v) => v.id != videoId).toList();
    state = state.copyWith(videos: updatedVideos);
    
    // Update cache if we have a current pubkey
    if (_currentPubkey != null) {
      _cacheProfileVideos(_currentPubkey!, updatedVideos, state.hasMore);
    }
  }
}