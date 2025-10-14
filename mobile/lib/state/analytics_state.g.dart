// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AnalyticsState _$AnalyticsStateFromJson(Map<String, dynamic> json) =>
    _AnalyticsState(
      analyticsEnabled: json['analyticsEnabled'] as bool? ?? true,
      isInitialized: json['isInitialized'] as bool? ?? false,
      isLoading: json['isLoading'] as bool? ?? false,
      lastEvent: json['lastEvent'] as String?,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$AnalyticsStateToJson(_AnalyticsState instance) =>
    <String, dynamic>{
      'analyticsEnabled': instance.analyticsEnabled,
      'isInitialized': instance.isInitialized,
      'isLoading': instance.isLoading,
      'lastEvent': instance.lastEvent,
      'error': instance.error,
    };
