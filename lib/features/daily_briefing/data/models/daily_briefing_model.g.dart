// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_briefing_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyBriefingModel _$DailyBriefingModelFromJson(Map<String, dynamic> json) =>
    DailyBriefingModel(
      id: json['id'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      weather: json['weather'] == null
          ? null
          : WeatherModel.fromJson(json['weather'] as Map<String, dynamic>),
      topNews: (json['topNews'] as List<dynamic>)
          .map((e) => NewsArticleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      todayEvents: (json['todayEvents'] as List<dynamic>)
          .map((e) => CalendarEventModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      insights: json['insights'] == null
          ? null
          : AIInsightsModel.fromJson(json['insights'] as Map<String, dynamic>),
      errorMessage: json['errorMessage'] as String? ?? '',
    );

Map<String, dynamic> _$DailyBriefingModelToJson(DailyBriefingModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'weather': instance.weather,
      'topNews': instance.topNews,
      'todayEvents': instance.todayEvents,
      'insights': instance.insights,
    };
