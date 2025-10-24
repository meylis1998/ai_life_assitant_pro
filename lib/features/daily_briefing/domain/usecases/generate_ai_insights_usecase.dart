import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/ai_insights.dart';
import '../repositories/ai_insights_repository.dart';

/// Use case for generating AI insights
class GenerateAIInsightsUseCase
    implements UseCase<AIInsights, AIInsightsContext> {
  final AIInsightsRepository repository;

  GenerateAIInsightsUseCase(this.repository);

  @override
  Future<Either<Failure, AIInsights>> call(AIInsightsContext params) async {
    return await repository.generateInsights(context: params);
  }
}
