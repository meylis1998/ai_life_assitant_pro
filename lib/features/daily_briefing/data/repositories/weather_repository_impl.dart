import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_api_datasource.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final WeatherApiDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  WeatherRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Weather>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final weatherModel = await remoteDataSource.getWeather(
        latitude: latitude,
        longitude: longitude,
      );

      return Right(weatherModel.toEntity());
    } on Exception catch (e) {
      return Left(WeatherFailure(message: e.toString()));
    } catch (e) {
      return Left(WeatherFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Weather>> getWeatherByCity(String cityName) async {
    // Check network connectivity
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(message: 'No internet connection'),
      );
    }

    try {
      final weatherModel = await remoteDataSource.getWeatherByCity(cityName);
      return Right(weatherModel.toEntity());
    } on Exception catch (e) {
      return Left(WeatherFailure(message: e.toString()));
    } catch (e) {
      return Left(WeatherFailure(message: 'Unexpected error: $e'));
    }
  }
}
