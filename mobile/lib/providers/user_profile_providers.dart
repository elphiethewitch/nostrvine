// ABOUTME: Riverpod providers for user profile service with reactive state management
// ABOUTME: Pure @riverpod functions for user profile management and caching

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nostr_sdk/event.dart';
import 'package:nostr_sdk/filter.dart';
import 'package:openvine/models/user_profile.dart';
import 'package:openvine/providers/app_providers.dart';
import 'package:openvine/state/user_profile_state.dart';
import 'package:openvine/utils/unified_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_profile_providers.g.dart';

// Helper function for safe pubkey truncation in logs
String _safePubkeyTrunc(String pubkey) => pubkey.length > 8 ? pubkey.substring(0, 8) : pubkey;

// Cache for user profiles
final Map<String, UserProfile> _userProfileCache = {};
final Map<String, DateTime> _userProfileCacheTimestamps = {};
final Set<String> _knownMissingProfiles = {};
final Map<String, DateTime> _missingProfileRetryAfter = {};
const Duration _userProfileCacheExpiry = Duration(minutes: 10);

/// Get cached profile if available and not expired
UserProfile? _getCachedUserProfile(String pubkey) {
  final profile = _userProfileCache[pubkey];
  final timestamp = _userProfileCacheTimestamps[pubkey];

  if (profile != null && timestamp != null) {
    final age = DateTime.now().difference(timestamp);
    if (age < _userProfileCacheExpiry) {
      Log.debug(
          '👤 Using cached profile for ${_safePubkeyTrunc(pubkey)} (age: ${age.inMinutes}min)',
          name: 'UserProfileProvider',
          category: LogCategory.ui);
      return profile;
    } else {
      Log.debug(
          '⏰ Profile cache expired for ${_safePubkeyTrunc(pubkey)} (age: ${age.inMinutes}min)',
          name: 'UserProfileProvider',
          category: LogCategory.ui);
      _clearUserProfileCache(pubkey);
    }
  }

  return null;
}

/// Cache profile for a user
void _cacheUserProfile(String pubkey, UserProfile profile) {
  _userProfileCache[pubkey] = profile;
  _userProfileCacheTimestamps[pubkey] = DateTime.now();
  Log.debug('👤 Cached profile for ${_safePubkeyTrunc(pubkey)}: ${profile.bestDisplayName}',
      name: 'UserProfileProvider', category: LogCategory.ui);
}

/// Clear cache for a specific user
void _clearUserProfileCache(String pubkey) {
  _userProfileCache.remove(pubkey);
  _userProfileCacheTimestamps.remove(pubkey);
}


/// Mark a profile as missing to avoid spam
void _markProfileAsMissing(String pubkey) {
  final retryAfter = DateTime.now().add(const Duration(hours: 1));
  _knownMissingProfiles.add(pubkey);
  _missingProfileRetryAfter[pubkey] = retryAfter;
  
  Log.debug(
    'Marked profile as missing: ${_safePubkeyTrunc(pubkey)}... (retry after 1 hour)',
    name: 'UserProfileProvider',
    category: LogCategory.ui,
  );
}

/// Check if we should skip fetching (known missing)
bool _shouldSkipFetch(String pubkey) {
  if (!_knownMissingProfiles.contains(pubkey)) return false;

  final retryAfter = _missingProfileRetryAfter[pubkey];
  if (retryAfter == null) return false;

  return DateTime.now().isBefore(retryAfter);
}

/// Async provider for loading a single user profile
@riverpod
Future<UserProfile?> userProfile(Ref ref, String pubkey) async {
  // Check cache first
  final cached = _getCachedUserProfile(pubkey);
  if (cached != null) {
    return cached;
  }

  // Check if should skip (known missing)
  if (_shouldSkipFetch(pubkey)) {
    Log.debug(
      'Skipping fetch for known missing profile: ${_safePubkeyTrunc(pubkey)}...',
      name: 'UserProfileProvider',
      category: LogCategory.ui,
    );
    return null;
  }

  // Get services from app providers
  final nostrService = ref.watch(nostrServiceProvider);

  Log.debug('🔍 Loading profile for: ${_safePubkeyTrunc(pubkey)}...',
      name: 'UserProfileProvider', category: LogCategory.ui);

  try {
    // Create filter for Kind 0 profile event
    final filter = Filter(
      kinds: const [0],
      authors: [pubkey],
      limit: 1,
    );

    // Subscribe and wait for profile
    final completer = Completer<UserProfile?>();
    final stream = nostrService.subscribeToEvents(filters: [filter]);
    StreamSubscription<Event>? subscription;

    // Timeout after 5 seconds
    final timer = Timer(const Duration(seconds: 5), () {
      subscription?.cancel();
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    subscription = stream.listen(
      (event) {
        timer.cancel();
        subscription?.cancel();

        try {
          final profile = UserProfile.fromNostrEvent(event);

          // Cache the profile
          _cacheUserProfile(pubkey, profile);

          Log.info(
            '✅ Fetched profile for ${_safePubkeyTrunc(pubkey)}: ${profile.bestDisplayName}',
            name: 'UserProfileProvider',
            category: LogCategory.ui,
          );

          if (!completer.isCompleted) {
            completer.complete(profile);
          }
        } catch (e) {
          Log.error('Error parsing profile event: $e',
              name: 'UserProfileProvider', category: LogCategory.ui);
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        }
      },
      onError: (error) {
        timer.cancel();
        subscription?.cancel();
        Log.error('Error fetching profile: $error',
            name: 'UserProfileProvider', category: LogCategory.ui);

        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
      onDone: () {
        timer.cancel();
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    );

    final profile = await completer.future;

    // If no profile found, mark as missing
    if (profile == null) {
      _markProfileAsMissing(pubkey);
    }

    return profile;
  } catch (e) {
    Log.error('Error loading profile: $e',
        name: 'UserProfileProvider', category: LogCategory.ui);
    _markProfileAsMissing(pubkey);
    return null;
  }
}

// User profile state notifier with reactive state management
@riverpod
class UserProfileNotifier extends _$UserProfileNotifier {
  // Active subscription tracking
  final Map<String, String> _activeSubscriptionIds =
      {}; // pubkey -> subscription ID
  String? _batchSubscriptionId;
  Timer? _batchTimer;
  Timer? _batchDebounceTimer;

  @override
  UserProfileState build() {
    ref.onDispose(() {
      _cleanupAllSubscriptions();
      _batchTimer?.cancel();
      _batchDebounceTimer?.cancel();
    });

    return UserProfileState.initial;
  }

  /// Initialize the profile service
  Future<void> initialize() async {
    if (state.isInitialized) return;

    Log.verbose('Initializing user profile notifier...',
        name: 'UserProfileNotifier', category: LogCategory.system);

    final nostrService = ref.read(nostrServiceProvider);

    if (!nostrService.isInitialized) {
      Log.warning('Nostr service not initialized, profile notifier will wait',
          name: 'UserProfileNotifier', category: LogCategory.system);
      return;
    }

    state = state.copyWith(isInitialized: true);
    Log.info('User profile notifier initialized',
        name: 'UserProfileNotifier', category: LogCategory.system);
  }

  /// Get cached profile for a user
  UserProfile? getCachedProfile(String pubkey) {
    // Check memory cache first
    final cached = _getCachedUserProfile(pubkey);
    if (cached != null) return cached;
    
    // Check state cache
    return state.getCachedProfile(pubkey);
  }

  /// Update a cached profile
  void updateCachedProfile(UserProfile profile) {
    // Update both memory cache and state
    _cacheUserProfile(profile.pubkey, profile);
    
    final newCache = {...state.profileCache, profile.pubkey: profile};
    state = state.copyWith(
      profileCache: newCache,
      totalProfilesCached: newCache.length,
    );

    Log.debug(
      'Updated cached profile for ${_safePubkeyTrunc(profile.pubkey)}: ${profile.bestDisplayName}',
      name: 'UserProfileNotifier',
      category: LogCategory.system,
    );
  }

  /// Fetch profile for a specific user (uses async provider under the hood)
  Future<UserProfile?> fetchProfile(String pubkey,
      {bool forceRefresh = false}) async {
    if (!state.isInitialized) {
      await initialize();
    }

    // If forcing refresh, clear cache first
    if (forceRefresh) {
      Log.debug(
        '🔄 Force refresh requested for ${_safePubkeyTrunc(pubkey)}... - clearing cache',
        name: 'UserProfileNotifier',
        category: LogCategory.system,
      );

      _clearUserProfileCache(pubkey);
      ref.invalidate(userProfileProvider(pubkey));
      
      final newCache = {...state.profileCache}..remove(pubkey);
      state = state.copyWith(profileCache: newCache);

      // Cancel any existing subscriptions
      await _cleanupProfileRequest(pubkey);
    }

    // Check if already requesting
    if (state.isRequestPending(pubkey)) {
      Log.warning(
        '⏳ Profile request already pending for ${_safePubkeyTrunc(pubkey)}...',
        name: 'UserProfileNotifier',
        category: LogCategory.system,
      );
      return null;
    }

    try {
      // Mark as pending
      state = state.copyWith(
        pendingRequests: {...state.pendingRequests, pubkey},
        isLoading: true,
        totalProfilesRequested: state.totalProfilesRequested + 1,
      );

      // Use the async provider to fetch profile
      final profile = await ref.read(userProfileProvider(pubkey).future);

      if (profile != null) {
        // Update state cache
        final newCache = {...state.profileCache, pubkey: profile};
        state = state.copyWith(
          profileCache: newCache,
          totalProfilesCached: newCache.length,
        );
      }

      return profile;
    } finally {
      // Remove from pending
      final newPending = {...state.pendingRequests}..remove(pubkey);
      state = state.copyWith(
        pendingRequests: newPending,
        isLoading: newPending.isEmpty && state.pendingBatchPubkeys.isEmpty,
      );
    }
  }

  /// Fetch multiple profiles with batching
  Future<void> fetchMultipleProfiles(List<String> pubkeys,
      {bool forceRefresh = false}) async {
    if (!state.isInitialized) {
      await initialize();
    }

    // Filter out already cached profiles (unless forcing refresh)
    final pubkeysToFetch = forceRefresh
        ? pubkeys
        : pubkeys
            .where((p) => !state.hasProfile(p) && !_shouldSkipFetch(p))
            .toList();

    if (pubkeysToFetch.isEmpty) {
      Log.debug('All requested profiles already cached',
          name: 'UserProfileNotifier', category: LogCategory.system);
      return;
    }

    Log.info('📋 Batch fetching ${pubkeysToFetch.length} profiles',
        name: 'UserProfileNotifier', category: LogCategory.system);

    // Add to pending batch
    state = state.copyWith(
      pendingBatchPubkeys: {...state.pendingBatchPubkeys, ...pubkeysToFetch},
      isLoading: true,
    );

    // Debounce batch execution
    _batchDebounceTimer?.cancel();
    _batchDebounceTimer =
        Timer(const Duration(milliseconds: 100), executeBatchFetch);
  }

  /// Mark a profile as missing to avoid spam
  void markProfileAsMissing(String pubkey) {
    // Update memory cache
    _markProfileAsMissing(pubkey);
    
    // Update state
    final retryAfter = DateTime.now().add(const Duration(hours: 1));
    state = state.copyWith(
      knownMissingProfiles: {...state.knownMissingProfiles, pubkey},
      missingProfileRetryAfter: {
        ...state.missingProfileRetryAfter,
        pubkey: retryAfter
      },
    );

    Log.debug(
      'Marked profile as missing: ${_safePubkeyTrunc(pubkey)}... (retry after 1 hour)',
      name: 'UserProfileNotifier',
      category: LogCategory.system,
    );
  }

  // Private helper methods

  // Made package-private for testing
  @visibleForTesting
  Future<void> executeBatchFetch() async {
    if (state.pendingBatchPubkeys.isEmpty) return;

    final pubkeysToFetch = state.pendingBatchPubkeys.toList();
    Log.debug(
      '_executeBatchFetch called with ${pubkeysToFetch.length} pubkeys',
      name: 'UserProfileNotifier',
      category: LogCategory.system,
    );

    try {
      // Create filter for multiple authors
      final filter = Filter(
        kinds: const [0],
        authors: pubkeysToFetch,
        limit: pubkeysToFetch.length,
      );

      final nostrService = ref.read(nostrServiceProvider);
      Log.debug(
        'Got nostr service, subscribing to events...',
        name: 'UserProfileNotifier',
        category: LogCategory.system,
      );
      final stream = nostrService.subscribeToEvents(filters: [filter]);
      StreamSubscription<Event>? subscription;

      // Collect profiles as they come in
      final fetchedPubkeys = <String>{};

      // Timeout after 5 seconds
      _batchTimer = Timer(const Duration(seconds: 5), () {
        subscription?.cancel();
        _finalizeBatchFetch(pubkeysToFetch, fetchedPubkeys);
      });

      subscription = stream.listen(
        (event) {
          try {
            final profile = UserProfile.fromNostrEvent(event);
            fetchedPubkeys.add(profile.pubkey);

            // Update both memory cache and state cache
            _cacheUserProfile(profile.pubkey, profile);
            
            final newCache = {...state.profileCache, profile.pubkey: profile};
            state = state.copyWith(
              profileCache: newCache,
              totalProfilesCached: newCache.length,
            );

            Log.debug(
              'Batch fetched profile: ${profile.bestDisplayName}',
              name: 'UserProfileNotifier',
              category: LogCategory.system,
            );
          } catch (e) {
            Log.error(
              'Error parsing batch profile event: $e',
              name: 'UserProfileNotifier',
              category: LogCategory.system,
            );
          }
        },
        onError: (error) {
          Log.error('Batch fetch error: $error',
              name: 'UserProfileNotifier', category: LogCategory.system);
          state = state.copyWith(error: error.toString());
        },
        onDone: () {
          _batchTimer?.cancel();
          subscription?.cancel();
          _finalizeBatchFetch(pubkeysToFetch, fetchedPubkeys);
        },
      );

      // Store subscription ID for cleanup
      _batchSubscriptionId = 'batch-${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      Log.error('Error executing batch fetch: $e',
          name: 'UserProfileNotifier', category: LogCategory.system);
      state = state.copyWith(
        pendingBatchPubkeys: {},
        isLoading: state.pendingRequests.isEmpty,
        error: e.toString(),
      );
    }
  }

  void _finalizeBatchFetch(List<String> requested, Set<String> fetched) {
    // Mark unfetched profiles as missing
    for (final pubkey in requested) {
      if (!fetched.contains(pubkey)) {
        markProfileAsMissing(pubkey);
      }
    }

    // Clear batch state
    state = state.copyWith(
      pendingBatchPubkeys: {},
      isLoading: state.pendingRequests.isNotEmpty,
    );

    Log.info(
      'Batch fetch complete: ${fetched.length}/${requested.length} profiles fetched',
      name: 'UserProfileNotifier',
      category: LogCategory.system,
    );
  }

  Future<void> _cleanupProfileRequest(String pubkey) async {
    final subscriptionId = _activeSubscriptionIds[pubkey];
    if (subscriptionId != null) {
      try {
        final subscriptionManager = ref.read(subscriptionManagerProvider);
        subscriptionManager.cancelSubscription(subscriptionId);
        _activeSubscriptionIds.remove(pubkey);
      } catch (e) {
        Log.error('Error canceling subscription: $e',
            name: 'UserProfileNotifier', category: LogCategory.system);
      }
    }
  }

  void _cleanupAllSubscriptions() {
    try {
      final subscriptionManager = ref.read(subscriptionManagerProvider);

      // Clean up individual subscriptions
      for (final subscriptionId in _activeSubscriptionIds.values) {
        subscriptionManager.cancelSubscription(subscriptionId);
      }
      _activeSubscriptionIds.clear();

      // Clean up batch subscription
      if (_batchSubscriptionId != null) {
        subscriptionManager.cancelSubscription(_batchSubscriptionId!);
        _batchSubscriptionId = null;
      }
    } catch (e) {
      // Container might be disposed, ignore cleanup errors
      Log.debug('Cleanup error during disposal: $e',
          name: 'UserProfileNotifier', category: LogCategory.system);
    }
  }

  /// Check if we have a cached profile
  bool hasProfile(String pubkey) => state.hasProfile(pubkey);
}
