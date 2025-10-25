import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_briefing.dart';
import '../repositories/briefing_repository.dart';

/// Use case for getting cached briefing
class GetCachedBriefingUseCase implements UseCase<DailyBriefing, NoParams> {
  final BriefingRepository repository;

  GetCachedBriefingUseCase(this.repository);

  @override
  Future<Either<Failure, DailyBriefing>> call(NoParams params) async {
    return await repository.getCachedBriefing();
  }
}