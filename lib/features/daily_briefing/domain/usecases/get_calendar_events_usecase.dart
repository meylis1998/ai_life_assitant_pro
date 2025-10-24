import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_event.dart';
import '../repositories/calendar_repository.dart';

/// Use case for getting calendar events
class GetCalendarEventsUseCase
    implements UseCase<List<CalendarEvent>, NoParams> {
  final CalendarRepository repository;

  GetCalendarEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(NoParams params) async {
    // First, check if permission is granted
    final permissionResult = await repository.hasPermission();

    return permissionResult.fold(
      (failure) => Left(failure),
      (hasPermission) async {
        if (!hasPermission) {
          // Try to request permission
          final requestResult = await repository.requestPermission();

          return requestResult.fold(
            (failure) => Left(failure),
            (granted) async {
              if (!granted) {
                // Permission denied - return empty list (graceful degradation)
                return const Right([]);
              }

              // Permission granted, fetch events
              return await repository.getTodayEvents();
            },
          );
        }

        // Permission already granted, fetch events
        return await repository.getTodayEvents();
      },
    );
  }
}
