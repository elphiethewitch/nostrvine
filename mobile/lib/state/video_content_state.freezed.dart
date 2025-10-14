// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_content_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VideoMetadata implements DiagnosticableTreeMixin {

 Duration get duration; double get width; double get height; double get aspectRatio; int? get bitrate; String? get format;
/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoMetadataCopyWith<VideoMetadata> get copyWith => _$VideoMetadataCopyWithImpl<VideoMetadata>(this as VideoMetadata, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'VideoMetadata'))
    ..add(DiagnosticsProperty('duration', duration))..add(DiagnosticsProperty('width', width))..add(DiagnosticsProperty('height', height))..add(DiagnosticsProperty('aspectRatio', aspectRatio))..add(DiagnosticsProperty('bitrate', bitrate))..add(DiagnosticsProperty('format', format));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoMetadata&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.aspectRatio, aspectRatio) || other.aspectRatio == aspectRatio)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.format, format) || other.format == format));
}


@override
int get hashCode => Object.hash(runtimeType,duration,width,height,aspectRatio,bitrate,format);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'VideoMetadata(duration: $duration, width: $width, height: $height, aspectRatio: $aspectRatio, bitrate: $bitrate, format: $format)';
}


}

/// @nodoc
abstract mixin class $VideoMetadataCopyWith<$Res>  {
  factory $VideoMetadataCopyWith(VideoMetadata value, $Res Function(VideoMetadata) _then) = _$VideoMetadataCopyWithImpl;
@useResult
$Res call({
 Duration duration, double width, double height, double aspectRatio, int? bitrate, String? format
});




}
/// @nodoc
class _$VideoMetadataCopyWithImpl<$Res>
    implements $VideoMetadataCopyWith<$Res> {
  _$VideoMetadataCopyWithImpl(this._self, this._then);

  final VideoMetadata _self;
  final $Res Function(VideoMetadata) _then;

/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? duration = null,Object? width = null,Object? height = null,Object? aspectRatio = null,Object? bitrate = freezed,Object? format = freezed,}) {
  return _then(_self.copyWith(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,aspectRatio: null == aspectRatio ? _self.aspectRatio : aspectRatio // ignore: cast_nullable_to_non_nullable
as double,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoMetadata].
extension VideoMetadataPatterns on VideoMetadata {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoMetadata value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoMetadata value)  $default,){
final _that = this;
switch (_that) {
case _VideoMetadata():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoMetadata value)?  $default,){
final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Duration duration,  double width,  double height,  double aspectRatio,  int? bitrate,  String? format)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
return $default(_that.duration,_that.width,_that.height,_that.aspectRatio,_that.bitrate,_that.format);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Duration duration,  double width,  double height,  double aspectRatio,  int? bitrate,  String? format)  $default,) {final _that = this;
switch (_that) {
case _VideoMetadata():
return $default(_that.duration,_that.width,_that.height,_that.aspectRatio,_that.bitrate,_that.format);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Duration duration,  double width,  double height,  double aspectRatio,  int? bitrate,  String? format)?  $default,) {final _that = this;
switch (_that) {
case _VideoMetadata() when $default != null:
return $default(_that.duration,_that.width,_that.height,_that.aspectRatio,_that.bitrate,_that.format);case _:
  return null;

}
}

}

/// @nodoc


class _VideoMetadata with DiagnosticableTreeMixin implements VideoMetadata {
  const _VideoMetadata({required this.duration, required this.width, required this.height, required this.aspectRatio, this.bitrate, this.format});
  

@override final  Duration duration;
@override final  double width;
@override final  double height;
@override final  double aspectRatio;
@override final  int? bitrate;
@override final  String? format;

/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoMetadataCopyWith<_VideoMetadata> get copyWith => __$VideoMetadataCopyWithImpl<_VideoMetadata>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'VideoMetadata'))
    ..add(DiagnosticsProperty('duration', duration))..add(DiagnosticsProperty('width', width))..add(DiagnosticsProperty('height', height))..add(DiagnosticsProperty('aspectRatio', aspectRatio))..add(DiagnosticsProperty('bitrate', bitrate))..add(DiagnosticsProperty('format', format));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoMetadata&&(identical(other.duration, duration) || other.duration == duration)&&(identical(other.width, width) || other.width == width)&&(identical(other.height, height) || other.height == height)&&(identical(other.aspectRatio, aspectRatio) || other.aspectRatio == aspectRatio)&&(identical(other.bitrate, bitrate) || other.bitrate == bitrate)&&(identical(other.format, format) || other.format == format));
}


@override
int get hashCode => Object.hash(runtimeType,duration,width,height,aspectRatio,bitrate,format);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'VideoMetadata(duration: $duration, width: $width, height: $height, aspectRatio: $aspectRatio, bitrate: $bitrate, format: $format)';
}


}

/// @nodoc
abstract mixin class _$VideoMetadataCopyWith<$Res> implements $VideoMetadataCopyWith<$Res> {
  factory _$VideoMetadataCopyWith(_VideoMetadata value, $Res Function(_VideoMetadata) _then) = __$VideoMetadataCopyWithImpl;
@override @useResult
$Res call({
 Duration duration, double width, double height, double aspectRatio, int? bitrate, String? format
});




}
/// @nodoc
class __$VideoMetadataCopyWithImpl<$Res>
    implements _$VideoMetadataCopyWith<$Res> {
  __$VideoMetadataCopyWithImpl(this._self, this._then);

  final _VideoMetadata _self;
  final $Res Function(_VideoMetadata) _then;

/// Create a copy of VideoMetadata
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? duration = null,Object? width = null,Object? height = null,Object? aspectRatio = null,Object? bitrate = freezed,Object? format = freezed,}) {
  return _then(_VideoMetadata(
duration: null == duration ? _self.duration : duration // ignore: cast_nullable_to_non_nullable
as Duration,width: null == width ? _self.width : width // ignore: cast_nullable_to_non_nullable
as double,height: null == height ? _self.height : height // ignore: cast_nullable_to_non_nullable
as double,aspectRatio: null == aspectRatio ? _self.aspectRatio : aspectRatio // ignore: cast_nullable_to_non_nullable
as double,bitrate: freezed == bitrate ? _self.bitrate : bitrate // ignore: cast_nullable_to_non_nullable
as int?,format: freezed == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$VideoContent implements DiagnosticableTreeMixin {

 String get videoId; String get url; ContentLoadingState get loadingState; DateTime get createdAt; VideoMetadata? get metadata; Uint8List? get thumbnailData; String? get errorMessage; DateTime? get lastAccessedAt; PreloadPriority get priority;
/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoContentCopyWith<VideoContent> get copyWith => _$VideoContentCopyWithImpl<VideoContent>(this as VideoContent, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'VideoContent'))
    ..add(DiagnosticsProperty('videoId', videoId))..add(DiagnosticsProperty('url', url))..add(DiagnosticsProperty('loadingState', loadingState))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('metadata', metadata))..add(DiagnosticsProperty('thumbnailData', thumbnailData))..add(DiagnosticsProperty('errorMessage', errorMessage))..add(DiagnosticsProperty('lastAccessedAt', lastAccessedAt))..add(DiagnosticsProperty('priority', priority));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoContent&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.url, url) || other.url == url)&&(identical(other.loadingState, loadingState) || other.loadingState == loadingState)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,videoId,url,loadingState,createdAt,metadata,const DeepCollectionEquality().hash(thumbnailData),errorMessage,lastAccessedAt,priority);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'VideoContent(videoId: $videoId, url: $url, loadingState: $loadingState, createdAt: $createdAt, metadata: $metadata, thumbnailData: $thumbnailData, errorMessage: $errorMessage, lastAccessedAt: $lastAccessedAt, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $VideoContentCopyWith<$Res>  {
  factory $VideoContentCopyWith(VideoContent value, $Res Function(VideoContent) _then) = _$VideoContentCopyWithImpl;
@useResult
$Res call({
 String videoId, String url, ContentLoadingState loadingState, DateTime createdAt, VideoMetadata? metadata, Uint8List? thumbnailData, String? errorMessage, DateTime? lastAccessedAt, PreloadPriority priority
});


$VideoMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class _$VideoContentCopyWithImpl<$Res>
    implements $VideoContentCopyWith<$Res> {
  _$VideoContentCopyWithImpl(this._self, this._then);

  final VideoContent _self;
  final $Res Function(VideoContent) _then;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? videoId = null,Object? url = null,Object? loadingState = null,Object? createdAt = null,Object? metadata = freezed,Object? thumbnailData = freezed,Object? errorMessage = freezed,Object? lastAccessedAt = freezed,Object? priority = null,}) {
  return _then(_self.copyWith(
videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,loadingState: null == loadingState ? _self.loadingState : loadingState // ignore: cast_nullable_to_non_nullable
as ContentLoadingState,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as VideoMetadata?,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,lastAccessedAt: freezed == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as PreloadPriority,
  ));
}
/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $VideoMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}


/// Adds pattern-matching-related methods to [VideoContent].
extension VideoContentPatterns on VideoContent {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoContent value)  $default,){
final _that = this;
switch (_that) {
case _VideoContent():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoContent value)?  $default,){
final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String videoId,  String url,  ContentLoadingState loadingState,  DateTime createdAt,  VideoMetadata? metadata,  Uint8List? thumbnailData,  String? errorMessage,  DateTime? lastAccessedAt,  PreloadPriority priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that.videoId,_that.url,_that.loadingState,_that.createdAt,_that.metadata,_that.thumbnailData,_that.errorMessage,_that.lastAccessedAt,_that.priority);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String videoId,  String url,  ContentLoadingState loadingState,  DateTime createdAt,  VideoMetadata? metadata,  Uint8List? thumbnailData,  String? errorMessage,  DateTime? lastAccessedAt,  PreloadPriority priority)  $default,) {final _that = this;
switch (_that) {
case _VideoContent():
return $default(_that.videoId,_that.url,_that.loadingState,_that.createdAt,_that.metadata,_that.thumbnailData,_that.errorMessage,_that.lastAccessedAt,_that.priority);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String videoId,  String url,  ContentLoadingState loadingState,  DateTime createdAt,  VideoMetadata? metadata,  Uint8List? thumbnailData,  String? errorMessage,  DateTime? lastAccessedAt,  PreloadPriority priority)?  $default,) {final _that = this;
switch (_that) {
case _VideoContent() when $default != null:
return $default(_that.videoId,_that.url,_that.loadingState,_that.createdAt,_that.metadata,_that.thumbnailData,_that.errorMessage,_that.lastAccessedAt,_that.priority);case _:
  return null;

}
}

}

/// @nodoc


class _VideoContent extends VideoContent with DiagnosticableTreeMixin {
  const _VideoContent({required this.videoId, required this.url, required this.loadingState, required this.createdAt, this.metadata, this.thumbnailData, this.errorMessage, this.lastAccessedAt, this.priority = PreloadPriority.background}): super._();
  

@override final  String videoId;
@override final  String url;
@override final  ContentLoadingState loadingState;
@override final  DateTime createdAt;
@override final  VideoMetadata? metadata;
@override final  Uint8List? thumbnailData;
@override final  String? errorMessage;
@override final  DateTime? lastAccessedAt;
@override@JsonKey() final  PreloadPriority priority;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoContentCopyWith<_VideoContent> get copyWith => __$VideoContentCopyWithImpl<_VideoContent>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'VideoContent'))
    ..add(DiagnosticsProperty('videoId', videoId))..add(DiagnosticsProperty('url', url))..add(DiagnosticsProperty('loadingState', loadingState))..add(DiagnosticsProperty('createdAt', createdAt))..add(DiagnosticsProperty('metadata', metadata))..add(DiagnosticsProperty('thumbnailData', thumbnailData))..add(DiagnosticsProperty('errorMessage', errorMessage))..add(DiagnosticsProperty('lastAccessedAt', lastAccessedAt))..add(DiagnosticsProperty('priority', priority));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoContent&&(identical(other.videoId, videoId) || other.videoId == videoId)&&(identical(other.url, url) || other.url == url)&&(identical(other.loadingState, loadingState) || other.loadingState == loadingState)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&const DeepCollectionEquality().equals(other.thumbnailData, thumbnailData)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.lastAccessedAt, lastAccessedAt) || other.lastAccessedAt == lastAccessedAt)&&(identical(other.priority, priority) || other.priority == priority));
}


@override
int get hashCode => Object.hash(runtimeType,videoId,url,loadingState,createdAt,metadata,const DeepCollectionEquality().hash(thumbnailData),errorMessage,lastAccessedAt,priority);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'VideoContent(videoId: $videoId, url: $url, loadingState: $loadingState, createdAt: $createdAt, metadata: $metadata, thumbnailData: $thumbnailData, errorMessage: $errorMessage, lastAccessedAt: $lastAccessedAt, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$VideoContentCopyWith<$Res> implements $VideoContentCopyWith<$Res> {
  factory _$VideoContentCopyWith(_VideoContent value, $Res Function(_VideoContent) _then) = __$VideoContentCopyWithImpl;
@override @useResult
$Res call({
 String videoId, String url, ContentLoadingState loadingState, DateTime createdAt, VideoMetadata? metadata, Uint8List? thumbnailData, String? errorMessage, DateTime? lastAccessedAt, PreloadPriority priority
});


@override $VideoMetadataCopyWith<$Res>? get metadata;

}
/// @nodoc
class __$VideoContentCopyWithImpl<$Res>
    implements _$VideoContentCopyWith<$Res> {
  __$VideoContentCopyWithImpl(this._self, this._then);

  final _VideoContent _self;
  final $Res Function(_VideoContent) _then;

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? videoId = null,Object? url = null,Object? loadingState = null,Object? createdAt = null,Object? metadata = freezed,Object? thumbnailData = freezed,Object? errorMessage = freezed,Object? lastAccessedAt = freezed,Object? priority = null,}) {
  return _then(_VideoContent(
videoId: null == videoId ? _self.videoId : videoId // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,loadingState: null == loadingState ? _self.loadingState : loadingState // ignore: cast_nullable_to_non_nullable
as ContentLoadingState,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as VideoMetadata?,thumbnailData: freezed == thumbnailData ? _self.thumbnailData : thumbnailData // ignore: cast_nullable_to_non_nullable
as Uint8List?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,lastAccessedAt: freezed == lastAccessedAt ? _self.lastAccessedAt : lastAccessedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as PreloadPriority,
  ));
}

/// Create a copy of VideoContent
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VideoMetadataCopyWith<$Res>? get metadata {
    if (_self.metadata == null) {
    return null;
  }

  return $VideoMetadataCopyWith<$Res>(_self.metadata!, (value) {
    return _then(_self.copyWith(metadata: value));
  });
}
}

/// @nodoc
mixin _$SingleVideoState implements DiagnosticableTreeMixin {

 VideoControllerState get state; String? get currentVideoId; String? get previousVideoId; String? get errorMessage; bool get isInBackground; DateTime? get lastStateChange;
/// Create a copy of SingleVideoState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SingleVideoStateCopyWith<SingleVideoState> get copyWith => _$SingleVideoStateCopyWithImpl<SingleVideoState>(this as SingleVideoState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SingleVideoState'))
    ..add(DiagnosticsProperty('state', state))..add(DiagnosticsProperty('currentVideoId', currentVideoId))..add(DiagnosticsProperty('previousVideoId', previousVideoId))..add(DiagnosticsProperty('errorMessage', errorMessage))..add(DiagnosticsProperty('isInBackground', isInBackground))..add(DiagnosticsProperty('lastStateChange', lastStateChange));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SingleVideoState&&(identical(other.state, state) || other.state == state)&&(identical(other.currentVideoId, currentVideoId) || other.currentVideoId == currentVideoId)&&(identical(other.previousVideoId, previousVideoId) || other.previousVideoId == previousVideoId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isInBackground, isInBackground) || other.isInBackground == isInBackground)&&(identical(other.lastStateChange, lastStateChange) || other.lastStateChange == lastStateChange));
}


@override
int get hashCode => Object.hash(runtimeType,state,currentVideoId,previousVideoId,errorMessage,isInBackground,lastStateChange);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SingleVideoState(state: $state, currentVideoId: $currentVideoId, previousVideoId: $previousVideoId, errorMessage: $errorMessage, isInBackground: $isInBackground, lastStateChange: $lastStateChange)';
}


}

/// @nodoc
abstract mixin class $SingleVideoStateCopyWith<$Res>  {
  factory $SingleVideoStateCopyWith(SingleVideoState value, $Res Function(SingleVideoState) _then) = _$SingleVideoStateCopyWithImpl;
@useResult
$Res call({
 VideoControllerState state, String? currentVideoId, String? previousVideoId, String? errorMessage, bool isInBackground, DateTime? lastStateChange
});




}
/// @nodoc
class _$SingleVideoStateCopyWithImpl<$Res>
    implements $SingleVideoStateCopyWith<$Res> {
  _$SingleVideoStateCopyWithImpl(this._self, this._then);

  final SingleVideoState _self;
  final $Res Function(SingleVideoState) _then;

/// Create a copy of SingleVideoState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? state = null,Object? currentVideoId = freezed,Object? previousVideoId = freezed,Object? errorMessage = freezed,Object? isInBackground = null,Object? lastStateChange = freezed,}) {
  return _then(_self.copyWith(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as VideoControllerState,currentVideoId: freezed == currentVideoId ? _self.currentVideoId : currentVideoId // ignore: cast_nullable_to_non_nullable
as String?,previousVideoId: freezed == previousVideoId ? _self.previousVideoId : previousVideoId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isInBackground: null == isInBackground ? _self.isInBackground : isInBackground // ignore: cast_nullable_to_non_nullable
as bool,lastStateChange: freezed == lastStateChange ? _self.lastStateChange : lastStateChange // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [SingleVideoState].
extension SingleVideoStatePatterns on SingleVideoState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SingleVideoState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SingleVideoState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SingleVideoState value)  $default,){
final _that = this;
switch (_that) {
case _SingleVideoState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SingleVideoState value)?  $default,){
final _that = this;
switch (_that) {
case _SingleVideoState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( VideoControllerState state,  String? currentVideoId,  String? previousVideoId,  String? errorMessage,  bool isInBackground,  DateTime? lastStateChange)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SingleVideoState() when $default != null:
return $default(_that.state,_that.currentVideoId,_that.previousVideoId,_that.errorMessage,_that.isInBackground,_that.lastStateChange);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( VideoControllerState state,  String? currentVideoId,  String? previousVideoId,  String? errorMessage,  bool isInBackground,  DateTime? lastStateChange)  $default,) {final _that = this;
switch (_that) {
case _SingleVideoState():
return $default(_that.state,_that.currentVideoId,_that.previousVideoId,_that.errorMessage,_that.isInBackground,_that.lastStateChange);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( VideoControllerState state,  String? currentVideoId,  String? previousVideoId,  String? errorMessage,  bool isInBackground,  DateTime? lastStateChange)?  $default,) {final _that = this;
switch (_that) {
case _SingleVideoState() when $default != null:
return $default(_that.state,_that.currentVideoId,_that.previousVideoId,_that.errorMessage,_that.isInBackground,_that.lastStateChange);case _:
  return null;

}
}

}

/// @nodoc


class _SingleVideoState extends SingleVideoState with DiagnosticableTreeMixin {
  const _SingleVideoState({this.state = VideoControllerState.idle, this.currentVideoId, this.previousVideoId, this.errorMessage, this.isInBackground = false, this.lastStateChange}): super._();
  

@override@JsonKey() final  VideoControllerState state;
@override final  String? currentVideoId;
@override final  String? previousVideoId;
@override final  String? errorMessage;
@override@JsonKey() final  bool isInBackground;
@override final  DateTime? lastStateChange;

/// Create a copy of SingleVideoState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SingleVideoStateCopyWith<_SingleVideoState> get copyWith => __$SingleVideoStateCopyWithImpl<_SingleVideoState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'SingleVideoState'))
    ..add(DiagnosticsProperty('state', state))..add(DiagnosticsProperty('currentVideoId', currentVideoId))..add(DiagnosticsProperty('previousVideoId', previousVideoId))..add(DiagnosticsProperty('errorMessage', errorMessage))..add(DiagnosticsProperty('isInBackground', isInBackground))..add(DiagnosticsProperty('lastStateChange', lastStateChange));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SingleVideoState&&(identical(other.state, state) || other.state == state)&&(identical(other.currentVideoId, currentVideoId) || other.currentVideoId == currentVideoId)&&(identical(other.previousVideoId, previousVideoId) || other.previousVideoId == previousVideoId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage)&&(identical(other.isInBackground, isInBackground) || other.isInBackground == isInBackground)&&(identical(other.lastStateChange, lastStateChange) || other.lastStateChange == lastStateChange));
}


@override
int get hashCode => Object.hash(runtimeType,state,currentVideoId,previousVideoId,errorMessage,isInBackground,lastStateChange);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'SingleVideoState(state: $state, currentVideoId: $currentVideoId, previousVideoId: $previousVideoId, errorMessage: $errorMessage, isInBackground: $isInBackground, lastStateChange: $lastStateChange)';
}


}

/// @nodoc
abstract mixin class _$SingleVideoStateCopyWith<$Res> implements $SingleVideoStateCopyWith<$Res> {
  factory _$SingleVideoStateCopyWith(_SingleVideoState value, $Res Function(_SingleVideoState) _then) = __$SingleVideoStateCopyWithImpl;
@override @useResult
$Res call({
 VideoControllerState state, String? currentVideoId, String? previousVideoId, String? errorMessage, bool isInBackground, DateTime? lastStateChange
});




}
/// @nodoc
class __$SingleVideoStateCopyWithImpl<$Res>
    implements _$SingleVideoStateCopyWith<$Res> {
  __$SingleVideoStateCopyWithImpl(this._self, this._then);

  final _SingleVideoState _self;
  final $Res Function(_SingleVideoState) _then;

/// Create a copy of SingleVideoState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? state = null,Object? currentVideoId = freezed,Object? previousVideoId = freezed,Object? errorMessage = freezed,Object? isInBackground = null,Object? lastStateChange = freezed,}) {
  return _then(_SingleVideoState(
state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as VideoControllerState,currentVideoId: freezed == currentVideoId ? _self.currentVideoId : currentVideoId // ignore: cast_nullable_to_non_nullable
as String?,previousVideoId: freezed == previousVideoId ? _self.previousVideoId : previousVideoId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,isInBackground: null == isInBackground ? _self.isInBackground : isInBackground // ignore: cast_nullable_to_non_nullable
as bool,lastStateChange: freezed == lastStateChange ? _self.lastStateChange : lastStateChange // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$VideoContentBufferState implements DiagnosticableTreeMixin {

 Map<String, VideoContent> get content; int get totalSize; double get estimatedMemoryMB; DateTime? get lastCleanup;
/// Create a copy of VideoContentBufferState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VideoContentBufferStateCopyWith<VideoContentBufferState> get copyWith => _$VideoContentBufferStateCopyWithImpl<VideoContentBufferState>(this as VideoContentBufferState, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'VideoContentBufferState'))
    ..add(DiagnosticsProperty('content', content))..add(DiagnosticsProperty('totalSize', totalSize))..add(DiagnosticsProperty('estimatedMemoryMB', estimatedMemoryMB))..add(DiagnosticsProperty('lastCleanup', lastCleanup));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VideoContentBufferState&&const DeepCollectionEquality().equals(other.content, content)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.estimatedMemoryMB, estimatedMemoryMB) || other.estimatedMemoryMB == estimatedMemoryMB)&&(identical(other.lastCleanup, lastCleanup) || other.lastCleanup == lastCleanup));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(content),totalSize,estimatedMemoryMB,lastCleanup);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'VideoContentBufferState(content: $content, totalSize: $totalSize, estimatedMemoryMB: $estimatedMemoryMB, lastCleanup: $lastCleanup)';
}


}

/// @nodoc
abstract mixin class $VideoContentBufferStateCopyWith<$Res>  {
  factory $VideoContentBufferStateCopyWith(VideoContentBufferState value, $Res Function(VideoContentBufferState) _then) = _$VideoContentBufferStateCopyWithImpl;
@useResult
$Res call({
 Map<String, VideoContent> content, int totalSize, double estimatedMemoryMB, DateTime? lastCleanup
});




}
/// @nodoc
class _$VideoContentBufferStateCopyWithImpl<$Res>
    implements $VideoContentBufferStateCopyWith<$Res> {
  _$VideoContentBufferStateCopyWithImpl(this._self, this._then);

  final VideoContentBufferState _self;
  final $Res Function(VideoContentBufferState) _then;

/// Create a copy of VideoContentBufferState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? content = null,Object? totalSize = null,Object? estimatedMemoryMB = null,Object? lastCleanup = freezed,}) {
  return _then(_self.copyWith(
content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as Map<String, VideoContent>,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,estimatedMemoryMB: null == estimatedMemoryMB ? _self.estimatedMemoryMB : estimatedMemoryMB // ignore: cast_nullable_to_non_nullable
as double,lastCleanup: freezed == lastCleanup ? _self.lastCleanup : lastCleanup // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VideoContentBufferState].
extension VideoContentBufferStatePatterns on VideoContentBufferState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VideoContentBufferState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VideoContentBufferState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VideoContentBufferState value)  $default,){
final _that = this;
switch (_that) {
case _VideoContentBufferState():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VideoContentBufferState value)?  $default,){
final _that = this;
switch (_that) {
case _VideoContentBufferState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, VideoContent> content,  int totalSize,  double estimatedMemoryMB,  DateTime? lastCleanup)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VideoContentBufferState() when $default != null:
return $default(_that.content,_that.totalSize,_that.estimatedMemoryMB,_that.lastCleanup);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, VideoContent> content,  int totalSize,  double estimatedMemoryMB,  DateTime? lastCleanup)  $default,) {final _that = this;
switch (_that) {
case _VideoContentBufferState():
return $default(_that.content,_that.totalSize,_that.estimatedMemoryMB,_that.lastCleanup);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, VideoContent> content,  int totalSize,  double estimatedMemoryMB,  DateTime? lastCleanup)?  $default,) {final _that = this;
switch (_that) {
case _VideoContentBufferState() when $default != null:
return $default(_that.content,_that.totalSize,_that.estimatedMemoryMB,_that.lastCleanup);case _:
  return null;

}
}

}

/// @nodoc


class _VideoContentBufferState extends VideoContentBufferState with DiagnosticableTreeMixin {
  const _VideoContentBufferState({final  Map<String, VideoContent> content = const {}, this.totalSize = 0, this.estimatedMemoryMB = 0.0, this.lastCleanup}): _content = content,super._();
  

 final  Map<String, VideoContent> _content;
@override@JsonKey() Map<String, VideoContent> get content {
  if (_content is EqualUnmodifiableMapView) return _content;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_content);
}

@override@JsonKey() final  int totalSize;
@override@JsonKey() final  double estimatedMemoryMB;
@override final  DateTime? lastCleanup;

/// Create a copy of VideoContentBufferState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VideoContentBufferStateCopyWith<_VideoContentBufferState> get copyWith => __$VideoContentBufferStateCopyWithImpl<_VideoContentBufferState>(this, _$identity);


@override
void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  properties
    ..add(DiagnosticsProperty('type', 'VideoContentBufferState'))
    ..add(DiagnosticsProperty('content', content))..add(DiagnosticsProperty('totalSize', totalSize))..add(DiagnosticsProperty('estimatedMemoryMB', estimatedMemoryMB))..add(DiagnosticsProperty('lastCleanup', lastCleanup));
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VideoContentBufferState&&const DeepCollectionEquality().equals(other._content, _content)&&(identical(other.totalSize, totalSize) || other.totalSize == totalSize)&&(identical(other.estimatedMemoryMB, estimatedMemoryMB) || other.estimatedMemoryMB == estimatedMemoryMB)&&(identical(other.lastCleanup, lastCleanup) || other.lastCleanup == lastCleanup));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_content),totalSize,estimatedMemoryMB,lastCleanup);

@override
String toString({ DiagnosticLevel minLevel = DiagnosticLevel.info }) {
  return 'VideoContentBufferState(content: $content, totalSize: $totalSize, estimatedMemoryMB: $estimatedMemoryMB, lastCleanup: $lastCleanup)';
}


}

/// @nodoc
abstract mixin class _$VideoContentBufferStateCopyWith<$Res> implements $VideoContentBufferStateCopyWith<$Res> {
  factory _$VideoContentBufferStateCopyWith(_VideoContentBufferState value, $Res Function(_VideoContentBufferState) _then) = __$VideoContentBufferStateCopyWithImpl;
@override @useResult
$Res call({
 Map<String, VideoContent> content, int totalSize, double estimatedMemoryMB, DateTime? lastCleanup
});




}
/// @nodoc
class __$VideoContentBufferStateCopyWithImpl<$Res>
    implements _$VideoContentBufferStateCopyWith<$Res> {
  __$VideoContentBufferStateCopyWithImpl(this._self, this._then);

  final _VideoContentBufferState _self;
  final $Res Function(_VideoContentBufferState) _then;

/// Create a copy of VideoContentBufferState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? content = null,Object? totalSize = null,Object? estimatedMemoryMB = null,Object? lastCleanup = freezed,}) {
  return _then(_VideoContentBufferState(
content: null == content ? _self._content : content // ignore: cast_nullable_to_non_nullable
as Map<String, VideoContent>,totalSize: null == totalSize ? _self.totalSize : totalSize // ignore: cast_nullable_to_non_nullable
as int,estimatedMemoryMB: null == estimatedMemoryMB ? _self.estimatedMemoryMB : estimatedMemoryMB // ignore: cast_nullable_to_non_nullable
as double,lastCleanup: freezed == lastCleanup ? _self.lastCleanup : lastCleanup // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
