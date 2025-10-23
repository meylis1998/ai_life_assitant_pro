import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:workmanager/workmanager.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// Use case to schedule daily morning briefing using WorkManager
class ScheduleMorningBriefing
    implements UseCase<void, ScheduleMorningBriefingParams> {
  static const String taskName = 'daily_briefing_task';

  @override
  Future<Either<Failure, void>> call(ScheduleMorningBriefingParams params) async {
    try {
      if (params.enabled) {
        // Calculate initial delay to target time
        final now = DateTime.now();
        final targetTime = DateTime(
          now.year,
          now.month,
          now.day,
          params.hour,
          params.minute,
        );

        // If target time has passed today, schedule for tomorrow
        final scheduledTime =
            targetTime.isBefore(now) ? targetTime.add(const Duration(days: 1)) : targetTime;

        final initialDelay = scheduledTime.difference(now);

        // Schedule periodic task
        await Workmanager().registerPeriodicTask(
          taskName,
          taskName,
          frequency: const Duration(days: 1),
          initialDelay: initialDelay,
          constraints: Constraints(
            networkType: NetworkType.connected,
          ),
          inputData: {
            'hour': params.hour,
            'minute': params.minute,
          },
        );

        return const Right(null);
      } else {
        // Cancel the scheduled task
        await Workmanager().cancelByUniqueName(taskName);
        return const Right(null);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to schedule briefing: $e'));
    }
  }
}

class ScheduleMorningBriefingParams extends Equatable {
  final bool enabled;
  final int hour;
  final int minute;

  const ScheduleMorningBriefingParams({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  @override
  List<Object?> get props => [enabled, hour, minute];
}
