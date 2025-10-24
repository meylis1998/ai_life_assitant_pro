import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/weather.dart';
import '../repositories/weather_repository.dart';

/// Parameters for getting weather
class GetWeatherParams {
  final double? latitude;
  final double? longitude;
  final String? cityName;

  const GetWeatherParams({
    this.latitude,
    this.longitude,
    this.cityName,
  });

  /// Validate params
  bool get isValid {
    // Either coordinates or city name must be provided
    return (latitude != null && longitude != null) || cityName != null;
  }
}

/// Use case for getting current weather and forecast
class GetWeatherUseCase implements UseCase<Weather, GetWeatherParams> {
  final WeatherRepository repository;

  GetWeatherUseCase(this.repository);

  @override
  Future<Either<Failure, Weather>> call(GetWeatherParams params) async {
    // Validate params
    if (!params.isValid) {
      return const Left(
        ValidationFailure(
          message: 'Either coordinates or city name must be provided',
        ),
      );
    }

    // Use coordinates if available (more precise)
    if (params.latitude != null && params.longitude != null) {
      return await repository.getWeather(
        latitude: params.latitude!,
        longitude: params.longitude!,
      );
    }

    // Otherwise use city name
    if (params.cityName != null) {
      return await repository.getWeatherByCity(params.cityName!);
    }

    return const Left(
      ValidationFailure(
        message: 'Invalid weather parameters',
      ),
    );
  }
}
