import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_briefing.dart';
import '../repositories/briefing_repository.dart';

/// Parameters for generating daily briefing
class GenerateDailyBriefingParams {
  final BriefingPreferences preferences;
  final bool forceRefresh;

  const GenerateDailyBriefingParams({
    required this.preferences,
    this.forceRefresh = false,
  });
}

/// Use case for generating a complete daily briefing
///
/// This orchestrates all data sources (weather, news, calendar, AI)
/// and combines them into a single briefing.
class GenerateDailyBriefingUseCase
    implements UseCase<DailyBriefing, GenerateDailyBriefingParams> {
  final BriefingRepository repository;

  GenerateDailyBriefingUseCase(this.repository);

  @override
  Future<Either<Failure, DailyBriefing>> call(
    GenerateDailyBriefingParams params,
  ) async {
    return await repository.generateBriefing(
      preferences: params.preferences,
      forceRefresh: params.forceRefresh,
    );
  }
}
