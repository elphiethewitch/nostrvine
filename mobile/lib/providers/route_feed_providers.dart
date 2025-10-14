// ABOUTME: Route-aware feed providers that select correct video source per route
// ABOUTME: Enables router-driven screens to reactively get route-appropriate data

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/providers/home_feed_provider.dart';
import 'package:openvine/router/page_context_provider.dart';
import 'package:openvine/router/route_utils.dart';
import 'package:openvine/state/video_feed_state.dart';

/// Home feed state (follows only)
/// Returns AsyncValue<VideoFeedState> for route-aware home screen
final videosForHomeRouteProvider =
    Provider<AsyncValue<VideoFeedState>>((ref) {
  final contextAsync = ref.watch(pageContextProvider);

  return contextAsync.when(
    data: (ctx) {
      if (ctx.type != RouteType.home) {
        // Not on home route - return loading
        return const AsyncValue.loading();
      }
      // On home route - return home feed state
      return ref.watch(homeFeedProvider);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
