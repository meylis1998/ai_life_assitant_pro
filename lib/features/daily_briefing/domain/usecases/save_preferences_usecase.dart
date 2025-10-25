import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/briefing_repository.dart';

/// Parameters for saving preferences
class SavePreferencesParams extends Equatable {
  final BriefingPreferences preferences;

  const SavePreferencesParams({required this.preferences});

  @override
  List<Object?> get props => [preferences];
}

/// Use case for saving user preferences
class SavePreferencesUseCase implements UseCase<void, SavePreferencesParams> {
  final BriefingRepository repository;

  SavePreferencesUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SavePreferencesParams params) async {
    return await repository.savePreferences(params.preferences);
  }
}