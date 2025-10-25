import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:workmanager/workmanager.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

/// Parameters for scheduling daily briefing
class ScheduleBriefingParams extends Equatable {
  final bool enabled;
  final int hour; // 24-hour format (0-23)
  final int minute; // (0-59)
  final bool notificationsEnabled;

  const ScheduleBriefingParams({
    required this.enabled,
    required this.hour,
    required this.minute,
    this.notificationsEnabled = true,
  });

  @override
  List<Object?> get props => [enabled, hour, minute, notificationsEnabled];
}

/// Result of scheduling operation
class SchedulingResult extends Equatable {
  final bool success;
  final String? workRequestId; // WorkManager task ID
  final DateTime? nextScheduledTime;
  final String message;

  const SchedulingResult({
    required this.success,
    this.workRequestId,
    this.nextScheduledTime,
    required this.message,
  });

  @override
  List<Object?> get props => [success, workRequestId, nextScheduledTime, message];
}

/// Failure for scheduling errors
class SchedulingFailure extends Failure {
  const SchedulingFailure({super.message = 'Scheduling failed', super.code});
}

/// Use case for scheduling daily briefing background tasks
///
/// This use case handles:
/// - Enabling/disabling daily briefing schedule
/// - Setting specific time for briefings
/// - Configuring notification preferences
/// - Managing WorkManager background tasks
class ScheduleBriefingUseCase implements UseCase<SchedulingResult, ScheduleBriefingParams> {
  static const String _taskName = 'daily_briefing_task';
  static const String _uniqueName = 'daily_briefing_unique';

  ScheduleBriefingUseCase();

  @override
  Future<Either<Failure, SchedulingResult>> call(ScheduleBriefingParams params) async {
    try {
      // Validate parameters
      if (params.hour < 0 || params.hour > 23) {
        return const Left(SchedulingFailure(message: 'Invalid hour: must be between 0-23'));
      }

      if (params.minute < 0 || params.minute > 59) {
        return const Left(SchedulingFailure(message: 'Invalid minute: must be between 0-59'));
      }

      if (params.enabled) {
        // Schedule the background task
        final result = await _scheduleBackgroundTask(params);
        return Right(result);
      } else {
        // Cancel any existing scheduled tasks
        final result = await _cancelScheduledTasks();
        return Right(result);
      }
    } catch (e) {
      return Left(SchedulingFailure(message: 'Failed to schedule briefing: $e'));
    }
  }

  /// Schedule background task using WorkManager
  Future<SchedulingResult> _scheduleBackgroundTask(ScheduleBriefingParams params) async {
    try {
      // Cancel any existing tasks first
      await Workmanager().cancelByUniqueName(_uniqueName);

      // Calculate initial delay until the next scheduled time
      final now = DateTime.now();
      var nextScheduled = DateTime(
        now.year,
        now.month,
        now.day,
        params.hour,
        params.minute,
      );

      // If the time has passed today, schedule for tomorrow
      if (nextScheduled.isBefore(now) || nextScheduled.difference(now).inMinutes < 1) {
        nextScheduled = nextScheduled.add(const Duration(days: 1));
      }

      final initialDelay = nextScheduled.difference(now);

      // Schedule the recurring daily task
      await Workmanager().registerPeriodicTask(
        _uniqueName,
        _taskName,
        frequency: const Duration(days: 1), // Run daily
        initialDelay: initialDelay,
        constraints: Constraints(
          networkType: NetworkType.connected, // Require internet
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
        inputData: {
          'hour': params.hour,
          'minute': params.minute,
          'notifications_enabled': params.notificationsEnabled,
          'scheduled_at': DateTime.now().toIso8601String(),
        },
      );

      return SchedulingResult(
        success: true,
        workRequestId: _uniqueName,
        nextScheduledTime: nextScheduled,
        message: 'Daily briefing scheduled for ${_formatTime(params.hour, params.minute)}',
      );
    } catch (e) {
      throw SchedulingFailure(message: 'Failed to schedule background task: $e');
    }
  }

  /// Cancel all scheduled briefing tasks
  Future<SchedulingResult> _cancelScheduledTasks() async {
    try {
      // Cancel the daily briefing task
      await Workmanager().cancelByUniqueName(_uniqueName);

      return const SchedulingResult(
        success: true,
        message: 'Daily briefing schedule disabled',
      );
    } catch (e) {
      throw SchedulingFailure(message: 'Failed to cancel scheduled tasks: $e');
    }
  }

  /// Format time for display
  String _formatTime(int hour, int minute) {
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final minuteStr = minute.toString().padLeft(2, '0');
    return '$displayHour:$minuteStr $amPm';
  }
}