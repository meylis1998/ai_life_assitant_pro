import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_event.dart';
import '../entities/daily_briefing.dart';
import '../entities/news_article.dart';
import '../entities/weather.dart';
import '../repositories/briefing_repository.dart';

class GenerateAIInsights implements UseCase<AIInsights, GenerateAIInsightsParams> {
  final BriefingRepository repository;

  GenerateAIInsights(this.repository);

  @override
  Future<Either<Failure, AIInsights>> call(GenerateAIInsightsParams params) async {
    return await repository.generateAIInsights(
      weather: params.weather,
      news: params.news,
      events: params.events,
      userName: params.userName,
    );
  }
}

class GenerateAIInsightsParams extends Equatable {
  final Weather weather;
  final List<NewsArticle> news;
  final List<CalendarEvent> events;
  final String? userName;

  const GenerateAIInsightsParams({
    required this.weather,
    required this.news,
    required this.events,
    this.userName,
  });

  @override
  List<Object?> get props => [weather, news, events, userName];
}
