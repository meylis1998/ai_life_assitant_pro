import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_briefing.dart';
import '../repositories/briefing_repository.dart';

class GenerateDailyBriefing implements UseCase<DailyBriefing, GenerateDailyBriefingParams> {
  final BriefingRepository repository;

  GenerateDailyBriefing(this.repository);

  @override
  Future<Either<Failure, DailyBriefing>> call(GenerateDailyBriefingParams params) async {
    return await repository.generateDailyBriefing(
      userName: params.userName,
      cityName: params.cityName,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class GenerateDailyBriefingParams extends Equatable {
  final String? userName;
  final String? cityName;
  final double? latitude;
  final double? longitude;

  const GenerateDailyBriefingParams({
    this.userName,
    this.cityName,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [userName, cityName, latitude, longitude];
}
