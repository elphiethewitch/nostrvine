// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_overlay_manager_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for VideoOverlayManager that VideoOverlayModal can use
/// This replaces the missing videoManagerProvider referenced in TODO comments

@ProviderFor(videoOverlayManager)
const videoOverlayManagerProvider = VideoOverlayManagerProvider._();

/// Provider for VideoOverlayManager that VideoOverlayModal can use
/// This replaces the missing videoManagerProvider referenced in TODO comments

final class VideoOverlayManagerProvider
    extends
        $FunctionalProvider<
          VideoOverlayManager,
          VideoOverlayManager,
          VideoOverlayManager
        >
    with $Provider<VideoOverlayManager> {
  /// Provider for VideoOverlayManager that VideoOverlayModal can use
  /// This replaces the missing videoManagerProvider referenced in TODO comments
  const VideoOverlayManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoOverlayManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoOverlayManagerHash();

  @$internal
  @override
  $ProviderElement<VideoOverlayManager> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VideoOverlayManager create(Ref ref) {
    return videoOverlayManager(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoOverlayManager value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoOverlayManager>(value),
    );
  }
}

String _$videoOverlayManagerHash() =>
    r'e50d791ad09e411a0228dd02a53064251d580ed0';
