// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_stats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$profileStatsHash() => r'd5c6d5d944c249d4161d3201fe9faddab232f7d0';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// Async provider for loading profile statistics
///
/// Copied from [profileStats].
@ProviderFor(profileStats)
const profileStatsProvider = ProfileStatsFamily();

/// Async provider for loading profile statistics
///
/// Copied from [profileStats].
class ProfileStatsFamily extends Family<AsyncValue<ProfileStats>> {
  /// Async provider for loading profile statistics
  ///
  /// Copied from [profileStats].
  const ProfileStatsFamily();

  /// Async provider for loading profile statistics
  ///
  /// Copied from [profileStats].
  ProfileStatsProvider call(
    String pubkey,
  ) {
    return ProfileStatsProvider(
      pubkey,
    );
  }

  @override
  ProfileStatsProvider getProviderOverride(
    covariant ProfileStatsProvider provider,
  ) {
    return call(
      provider.pubkey,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'profileStatsProvider';
}

/// Async provider for loading profile statistics
///
/// Copied from [profileStats].
class ProfileStatsProvider extends AutoDisposeFutureProvider<ProfileStats> {
  /// Async provider for loading profile statistics
  ///
  /// Copied from [profileStats].
  ProfileStatsProvider(
    String pubkey,
  ) : this._internal(
          (ref) => profileStats(
            ref as ProfileStatsRef,
            pubkey,
          ),
          from: profileStatsProvider,
          name: r'profileStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$profileStatsHash,
          dependencies: ProfileStatsFamily._dependencies,
          allTransitiveDependencies:
              ProfileStatsFamily._allTransitiveDependencies,
          pubkey: pubkey,
        );

  ProfileStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.pubkey,
  }) : super.internal();

  final String pubkey;

  @override
  Override overrideWith(
    FutureOr<ProfileStats> Function(ProfileStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProfileStatsProvider._internal(
        (ref) => create(ref as ProfileStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        pubkey: pubkey,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProfileStats> createElement() {
    return _ProfileStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileStatsProvider && other.pubkey == pubkey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, pubkey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProfileStatsRef on AutoDisposeFutureProviderRef<ProfileStats> {
  /// The parameter `pubkey` of this provider.
  String get pubkey;
}

class _ProfileStatsProviderElement
    extends AutoDisposeFutureProviderElement<ProfileStats>
    with ProfileStatsRef {
  _ProfileStatsProviderElement(super.provider);

  @override
  String get pubkey => (origin as ProfileStatsProvider).pubkey;
}

String _$profileStatsNotifierHash() =>
    r'ef429150896a603acedfc4ce0a199f9816fb693f';

/// Notifier for managing profile stats state
///
/// Copied from [ProfileStatsNotifier].
@ProviderFor(ProfileStatsNotifier)
final profileStatsNotifierProvider = AutoDisposeNotifierProvider<
    ProfileStatsNotifier, ProfileStatsState>.internal(
  ProfileStatsNotifier.new,
  name: r'profileStatsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileStatsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ProfileStatsNotifier = AutoDisposeNotifier<ProfileStatsState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
