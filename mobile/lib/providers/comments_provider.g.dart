// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$commentsNotifierHash() => r'72f65ec9a5fd91a2d0a8dcb924891a91474eff38';

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

abstract class _$CommentsNotifier
    extends BuildlessAutoDisposeNotifier<CommentsState> {
  late final String rootEventId;
  late final String rootAuthorPubkey;

  CommentsState build(
    String rootEventId,
    String rootAuthorPubkey,
  );
}

/// Notifier for managing comments for a specific video
///
/// Copied from [CommentsNotifier].
@ProviderFor(CommentsNotifier)
const commentsNotifierProvider = CommentsNotifierFamily();

/// Notifier for managing comments for a specific video
///
/// Copied from [CommentsNotifier].
class CommentsNotifierFamily extends Family<CommentsState> {
  /// Notifier for managing comments for a specific video
  ///
  /// Copied from [CommentsNotifier].
  const CommentsNotifierFamily();

  /// Notifier for managing comments for a specific video
  ///
  /// Copied from [CommentsNotifier].
  CommentsNotifierProvider call(
    String rootEventId,
    String rootAuthorPubkey,
  ) {
    return CommentsNotifierProvider(
      rootEventId,
      rootAuthorPubkey,
    );
  }

  @override
  CommentsNotifierProvider getProviderOverride(
    covariant CommentsNotifierProvider provider,
  ) {
    return call(
      provider.rootEventId,
      provider.rootAuthorPubkey,
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
  String? get name => r'commentsNotifierProvider';
}

/// Notifier for managing comments for a specific video
///
/// Copied from [CommentsNotifier].
class CommentsNotifierProvider
    extends AutoDisposeNotifierProviderImpl<CommentsNotifier, CommentsState> {
  /// Notifier for managing comments for a specific video
  ///
  /// Copied from [CommentsNotifier].
  CommentsNotifierProvider(
    String rootEventId,
    String rootAuthorPubkey,
  ) : this._internal(
          () => CommentsNotifier()
            ..rootEventId = rootEventId
            ..rootAuthorPubkey = rootAuthorPubkey,
          from: commentsNotifierProvider,
          name: r'commentsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$commentsNotifierHash,
          dependencies: CommentsNotifierFamily._dependencies,
          allTransitiveDependencies:
              CommentsNotifierFamily._allTransitiveDependencies,
          rootEventId: rootEventId,
          rootAuthorPubkey: rootAuthorPubkey,
        );

  CommentsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.rootEventId,
    required this.rootAuthorPubkey,
  }) : super.internal();

  final String rootEventId;
  final String rootAuthorPubkey;

  @override
  CommentsState runNotifierBuild(
    covariant CommentsNotifier notifier,
  ) {
    return notifier.build(
      rootEventId,
      rootAuthorPubkey,
    );
  }

  @override
  Override overrideWith(CommentsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentsNotifierProvider._internal(
        () => create()
          ..rootEventId = rootEventId
          ..rootAuthorPubkey = rootAuthorPubkey,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        rootEventId: rootEventId,
        rootAuthorPubkey: rootAuthorPubkey,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<CommentsNotifier, CommentsState>
      createElement() {
    return _CommentsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsNotifierProvider &&
        other.rootEventId == rootEventId &&
        other.rootAuthorPubkey == rootAuthorPubkey;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, rootEventId.hashCode);
    hash = _SystemHash.combine(hash, rootAuthorPubkey.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentsNotifierRef on AutoDisposeNotifierProviderRef<CommentsState> {
  /// The parameter `rootEventId` of this provider.
  String get rootEventId;

  /// The parameter `rootAuthorPubkey` of this provider.
  String get rootAuthorPubkey;
}

class _CommentsNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<CommentsNotifier, CommentsState>
    with CommentsNotifierRef {
  _CommentsNotifierProviderElement(super.provider);

  @override
  String get rootEventId => (origin as CommentsNotifierProvider).rootEventId;
  @override
  String get rootAuthorPubkey =>
      (origin as CommentsNotifierProvider).rootAuthorPubkey;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
