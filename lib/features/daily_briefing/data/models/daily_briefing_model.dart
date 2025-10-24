import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/daily_briefing.dart';
import 'weather_model.dart';
import 'news_article_model.dart';
import 'calendar_event_model.dart';
import 'ai_insights_model.dart';

part 'daily_briefing_model.g.dart';

@JsonSerializable()
class DailyBriefingModel extends DailyBriefing {
  @override
  final WeatherModel? weather;

  @override
  final List<NewsArticleModel> topNews;

  @override
  final List<CalendarEventModel> todayEvents;

  @override
  final AIInsightsModel? insights;

  const DailyBriefingModel({
    required super.id,
    required super.generatedAt,
    this.weather,
    required this.topNews,
    required this.todayEvents,
    this.insights,
    super.errorMessage,
  }) : super(
          weather: weather,
          topNews: topNews,
          todayEvents: todayEvents,
          insights: insights,
        );

  factory DailyBriefingModel.fromJson(Map<String, dynamic> json) =>
      _$DailyBriefingModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailyBriefingModelToJson(this);

  DailyBriefing toEntity() => DailyBriefing(
        id: id,
        generatedAt: generatedAt,
        weather: weather?.toEntity(),
        topNews: topNews.map((article) => article.toEntity()).toList(),
        todayEvents: todayEvents.map((event) => event.toEntity()).toList(),
        insights: insights?.toEntity(),
        errorMessage: errorMessage,
      );

  /// Create a briefing with partial data (some sources may have failed)
  factory DailyBriefingModel.partial({
    required String id,
    required DateTime generatedAt,
    WeatherModel? weather,
    List<NewsArticleModel>? topNews,
    List<CalendarEventModel>? todayEvents,
    AIInsightsModel? insights,
    String? errorMessage,
  }) {
    return DailyBriefingModel(
      id: id,
      generatedAt: generatedAt,
      weather: weather,
      topNews: topNews ?? [],
      todayEvents: todayEvents ?? [],
      insights: insights,
      errorMessage: errorMessage ?? '',
    );
  }
}
