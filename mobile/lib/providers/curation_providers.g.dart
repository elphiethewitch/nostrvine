// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$curationServiceHash() => r'f5fa68c3a13bac3a5801c2d25aab2c4b8168164f';

/// Provider for CurationService instance
///
/// Copied from [curationService].
@ProviderFor(curationService)
final curationServiceProvider = AutoDisposeProvider<CurationService>.internal(
  curationService,
  name: r'curationServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$curationServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurationServiceRef = AutoDisposeProviderRef<CurationService>;
String _$curationLoadingHash() => r'e1a04d9f8d90870d340665613c0938b356085039';

/// Provider to check if curation is loading
///
/// Copied from [curationLoading].
@ProviderFor(curationLoading)
final curationLoadingProvider = AutoDisposeProvider<bool>.internal(
  curationLoading,
  name: r'curationLoadingProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$curationLoadingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurationLoadingRef = AutoDisposeProviderRef<bool>;
String _$editorsPicksHash() => r'47f6f4c73a8e2f6f8aafa718986c063feb530d08';

/// Provider to get editor's picks
///
/// Copied from [editorsPicks].
@ProviderFor(editorsPicks)
final editorsPicksProvider = AutoDisposeProvider<List<VideoEvent>>.internal(
  editorsPicks,
  name: r'editorsPicksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$editorsPicksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EditorsPicksRef = AutoDisposeProviderRef<List<VideoEvent>>;
String _$curationHash() => r'cc52c49a2b2eaab0bb1e846b8d850bc97632d8e7';

/// Main curation provider that manages curated content sets
///
/// Copied from [Curation].
@ProviderFor(Curation)
final curationProvider =
    AutoDisposeNotifierProvider<Curation, CurationState>.internal(
  Curation.new,
  name: r'curationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$curationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$Curation = AutoDisposeNotifier<CurationState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
