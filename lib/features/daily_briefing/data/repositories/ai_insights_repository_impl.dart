import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/ai_insights.dart';
import '../../domain/repositories/ai_insights_repository.dart';
import '../datasources/ai_insights_datasource.dart';

class AIInsightsRepositoryImpl implements AIInsightsRepository {
  final AIInsightsDataSource remoteDataSource;

  AIInsightsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AIInsights>> generateInsights({
    required AIInsightsContext context,
  }) async {
    try {
      final insightsModel = await remoteDataSource.generateInsights(
        context: context,
      );

      return Right(insightsModel.toEntity());
    } on Exception catch (e) {
      return Left(AIProviderFailure(message: e.toString()));
    } catch (e) {
      return Left(AIProviderFailure(message: 'Unexpected error: $e'));
    }
  }
}
