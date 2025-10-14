// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_prewarmer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(VideoPrewarmer)
const videoPrewarmerProvider = VideoPrewarmerProvider._();

final class VideoPrewarmerProvider
    extends $NotifierProvider<VideoPrewarmer, void> {
  const VideoPrewarmerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'videoPrewarmerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$videoPrewarmerHash();

  @$internal
  @override
  VideoPrewarmer create() => VideoPrewarmer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$videoPrewarmerHash() => r'92cb2207562e704a46b2ecafaeb87311ba31ca85';

abstract class _$VideoPrewarmer extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
