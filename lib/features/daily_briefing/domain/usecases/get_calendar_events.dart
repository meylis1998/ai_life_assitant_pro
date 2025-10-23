import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/calendar_event.dart';
import '../repositories/briefing_repository.dart';

class GetCalendarEvents implements UseCase<List<CalendarEvent>, NoParams> {
  final BriefingRepository repository;

  GetCalendarEvents(this.repository);

  @override
  Future<Either<Failure, List<CalendarEvent>>> call(NoParams params) async {
    return await repository.getTodayEvents();
  }
}
