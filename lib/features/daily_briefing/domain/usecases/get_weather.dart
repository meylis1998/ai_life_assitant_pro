import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/weather.dart';
import '../repositories/briefing_repository.dart';

class GetWeather implements UseCase<Weather, GetWeatherParams> {
  final BriefingRepository repository;

  GetWeather(this.repository);

  @override
  Future<Either<Failure, Weather>> call(GetWeatherParams params) async {
    return await repository.getWeather(
      cityName: params.cityName,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class GetWeatherParams extends Equatable {
  final String? cityName;
  final double? latitude;
  final double? longitude;

  const GetWeatherParams({
    this.cityName,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [cityName, latitude, longitude];
}
