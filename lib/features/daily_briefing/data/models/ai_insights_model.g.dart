// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_insights_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AIInsightsModel _$AIInsightsModelFromJson(Map<String, dynamic> json) =>
    AIInsightsModel(
      greeting: json['greeting'] as String,
      summary: json['summary'] as String,
      priorities: (json['priorities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      weatherAlert: json['weatherAlert'] as String?,
      trafficAlert: json['trafficAlert'] as String?,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );

Map<String, dynamic> _$AIInsightsModelToJson(AIInsightsModel instance) =>
    <String, dynamic>{
      'greeting': instance.greeting,
      'summary': instance.summary,
      'priorities': instance.priorities,
      'suggestions': instance.suggestions,
      'weatherAlert': instance.weatherAlert,
      'trafficAlert': instance.trafficAlert,
      'generatedAt': instance.generatedAt.toIso8601String(),
    };
