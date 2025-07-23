// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_feed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$videoFeedLoadingHash() => r'5a3880107474b0dfe89252742f62772f581bf585';

/// Provider to check if video feed is loading
///
/// Copied from [videoFeedLoading].
@ProviderFor(videoFeedLoading)
final videoFeedLoadingProvider = AutoDisposeProvider<bool>.internal(
  videoFeedLoading,
  name: r'videoFeedLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoFeedLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoFeedLoadingRef = AutoDisposeProviderRef<bool>;
String _$videoFeedCountHash() => r'c9fc7b68a402d8e63cff499a4a44842466718db8';

/// Provider to get current video count
///
/// Copied from [videoFeedCount].
@ProviderFor(videoFeedCount)
final videoFeedCountProvider = AutoDisposeProvider<int>.internal(
  videoFeedCount,
  name: r'videoFeedCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$videoFeedCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef VideoFeedCountRef = AutoDisposeProviderRef<int>;
String _$currentFeedModeHash() => r'51e2a476506a909c456c5af5731812f3bba47337';

/// Provider to get current feed mode
///
/// Copied from [currentFeedMode].
@ProviderFor(currentFeedMode)
final currentFeedModeProvider = AutoDisposeProvider<FeedMode>.internal(
  currentFeedMode,
  name: r'currentFeedModeProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentFeedModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentFeedModeRef = AutoDisposeProviderRef<FeedMode>;
String _$hasVideosHash() => r'2780fade78b3238a1979632f42151a3400b482b7';

/// Provider to check if we have videos
///
/// Copied from [hasVideos].
@ProviderFor(hasVideos)
final hasVideosProvider = AutoDisposeProvider<bool>.internal(
  hasVideos,
  name: r'hasVideosProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$hasVideosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HasVideosRef = AutoDisposeProviderRef<bool>;
String _$videoFeedHash() => r'1553a75d9015b5e3dec52307e13bf5bcb84d94b8';

/// Main video feed provider that orchestrates all video-related state
///
/// Copied from [VideoFeed].
@ProviderFor(VideoFeed)
final videoFeedProvider =
    AutoDisposeAsyncNotifierProvider<VideoFeed, VideoFeedState>.internal(
  VideoFeed.new,
  name: r'videoFeedProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videoFeedHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VideoFeed = AutoDisposeAsyncNotifier<VideoFeedState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
