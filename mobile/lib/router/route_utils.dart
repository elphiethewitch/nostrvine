// ABOUTME: Route parsing and building utilities
// ABOUTME: Converts between URLs and structured route context

/// Route types supported by the app
enum RouteType {
  home,
  explore,
  profile,
  hashtag,
  camera,
  settings,
}

/// Structured representation of a route
class RouteContext {
  const RouteContext({
    required this.type,
    this.videoIndex,
    this.npub,
    this.hashtag,
  });

  final RouteType type;
  final int? videoIndex;
  final String? npub;
  final String? hashtag;
}

/// Parse a URL path into a structured RouteContext
RouteContext parseRoute(String path) {
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();

  if (segments.isEmpty) {
    return const RouteContext(type: RouteType.home, videoIndex: 0);
  }

  final firstSegment = segments[0];

  switch (firstSegment) {
    case 'home':
      final index = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
      return RouteContext(type: RouteType.home, videoIndex: index);

    case 'explore':
      final index = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
      return RouteContext(type: RouteType.explore, videoIndex: index);

    case 'profile':
      if (segments.length < 2) {
        return const RouteContext(type: RouteType.home, videoIndex: 0);
      }
      final npub = segments[1];
      final index = segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;
      return RouteContext(
        type: RouteType.profile,
        npub: npub,
        videoIndex: index,
      );

    case 'hashtag':
      if (segments.length < 2) {
        return const RouteContext(type: RouteType.home, videoIndex: 0);
      }
      final tag = segments[1];
      final index = segments.length > 2 ? int.tryParse(segments[2]) ?? 0 : 0;
      return RouteContext(
        type: RouteType.hashtag,
        hashtag: tag,
        videoIndex: index,
      );

    case 'camera':
      return const RouteContext(type: RouteType.camera);

    case 'settings':
      return const RouteContext(type: RouteType.settings);

    default:
      return const RouteContext(type: RouteType.home, videoIndex: 0);
  }
}

/// Build a URL path from a RouteContext
String buildRoute(RouteContext context) {
  switch (context.type) {
    case RouteType.home:
      final index = context.videoIndex ?? 0;
      return '/home/$index';

    case RouteType.explore:
      final index = context.videoIndex ?? 0;
      return '/explore/$index';

    case RouteType.profile:
      final npub = context.npub ?? '';
      final index = context.videoIndex ?? 0;
      return '/profile/$npub/$index';

    case RouteType.hashtag:
      final hashtag = context.hashtag ?? '';
      final index = context.videoIndex ?? 0;
      return '/hashtag/$hashtag/$index';

    case RouteType.camera:
      return '/camera';

    case RouteType.settings:
      return '/settings';
  }
}
