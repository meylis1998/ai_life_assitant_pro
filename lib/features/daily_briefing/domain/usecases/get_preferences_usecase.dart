import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/briefing_repository.dart';

/// Use case for getting user preferences
class GetPreferencesUseCase implements UseCase<BriefingPreferences, NoParams> {
  final BriefingRepository repository;

  GetPreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, BriefingPreferences>> call(NoParams params) async {
    return await repository.getPreferences();
  }
}