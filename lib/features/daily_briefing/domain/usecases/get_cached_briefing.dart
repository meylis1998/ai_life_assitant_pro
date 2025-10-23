import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_briefing.dart';
import '../repositories/briefing_repository.dart';

class GetCachedBriefing implements UseCase<DailyBriefing, NoParams> {
  final BriefingRepository repository;

  GetCachedBriefing(this.repository);

  @override
  Future<Either<Failure, DailyBriefing>> call(NoParams params) async {
    return await repository.getCachedBriefing();
  }
}
