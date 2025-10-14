// ABOUTME: Profile-specific feed provider for route-driven ProfileScreenRouter
// ABOUTME: Returns videos for a specific user's profile based on route context

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/router/page_context_provider.dart';
import 'package:openvine/router/route_utils.dart';
import 'package:openvine/state/video_feed_state.dart';

/// Profile feed state for a specific user
/// Returns AsyncValue<VideoFeedState> filtered by profile pubkey from route
final videosForProfileRouteProvider =
    Provider<AsyncValue<VideoFeedState>>((ref) {
  final contextAsync = ref.watch(pageContextProvider);

  return contextAsync.when(
    data: (ctx) {
      if (ctx.type != RouteType.profile) {
        // Not on profile route - return loading
        return const AsyncValue.loading();
      }

      // TODO: Implement actual profile feed fetching based on ctx.profilePubkey
      // For now, return empty feed until we wire up real profile feed provider
      return AsyncValue.data(VideoFeedState(
        videos: const [],
        hasMoreContent: false,
        isLoadingMore: false,
      ));
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
