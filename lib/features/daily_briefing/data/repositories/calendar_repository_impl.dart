import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_local_datasource.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarLocalDataSource localDataSource;

  CalendarRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, bool>> requestPermission() async {
    try {
      final granted = await localDataSource.requestPermission();
      return Right(granted);
    } on Exception catch (e) {
      return Left(PermissionFailure(
        message: e.toString(),
        permissionType: 'calendar',
      ));
    } catch (e) {
      return Left(CalendarFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPermission() async {
    try {
      final granted = await localDataSource.hasPermission();
      return Right(granted);
    } on Exception catch (e) {
      return Left(PermissionFailure(
        message: e.toString(),
        permissionType: 'calendar',
      ));
    } catch (e) {
      return Left(CalendarFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getTodayEvents() async {
    try {
      // Check permission first
      final hasPermissionResult = await hasPermission();

      return hasPermissionResult.fold(
        (failure) => Left(failure),
        (granted) async {
          if (!granted) {
            return const Right([]); // Return empty list if no permission
          }

          final events = await localDataSource.getTodayEvents();
          return Right(events.map((model) => model.toEntity()).toList());
        },
      );
    } on Exception catch (e) {
      return Left(CalendarFailure(message: e.toString()));
    } catch (e) {
      return Left(CalendarFailure(message: 'Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Check permission first
      final hasPermissionResult = await hasPermission();

      return hasPermissionResult.fold(
        (failure) => Left(failure),
        (granted) async {
          if (!granted) {
            return const Right([]); // Return empty list if no permission
          }

          final events = await localDataSource.getEvents(
            startDate: startDate,
            endDate: endDate,
          );
          return Right(events.map((model) => model.toEntity()).toList());
        },
      );
    } on Exception catch (e) {
      return Left(CalendarFailure(message: e.toString()));
    } catch (e) {
      return Left(CalendarFailure(message: 'Unexpected error: $e'));
    }
  }
}
