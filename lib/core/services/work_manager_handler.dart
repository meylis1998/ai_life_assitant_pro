import 'package:workmanager/workmanager.dart';

import '../../features/daily_briefing/domain/usecases/generate_daily_briefing_usecase.dart';
import '../../features/daily_briefing/domain/repositories/briefing_repository.dart';
import '../../injection_container.dart' as di;
import 'notification_service.dart';

/// Callback for WorkManager background tasks
/// This function must be a top-level function
@pragma('vm:entry-point')
void workManagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize dependencies if needed
      if (!di.sl.isRegistered<BriefingRepository>()) {
        await di.init();
      }

      // Check if this is the daily briefing task
      if (task == 'daily_briefing_task') {
        return await _handleDailyBriefingTask(inputData);
      }

      return true;
    } catch (e) {
      // Log error and return failure
      print('WorkManager task failed: $e');
      return false;
    }
  });
}

/// Handle daily briefing background task
Future<bool> _handleDailyBriefingTask(Map<String, dynamic>? inputData) async {
  try {
    // Get repository and preferences
    final repository = di.sl<BriefingRepository>();
    final preferencesResult = await repository.getPreferences();

    // If we can't get preferences, fail
    if (preferencesResult.isLeft()) {
      print('Failed to get briefing preferences');
      return false;
    }

    final preferences = preferencesResult.fold(
      (failure) => null,
      (prefs) => prefs,
    );

    if (preferences == null) {
      return false;
    }

    // Generate briefing
    final generateBriefing = di.sl<GenerateDailyBriefingUseCase>();
    final result = await generateBriefing(
      GenerateDailyBriefingParams(
        preferences: preferences,
        forceRefresh: true,
      ),
    );

    // Handle result
    return result.fold(
      (failure) {
        // Briefing generation failed
        print('Failed to generate briefing: ${failure.message}');
        return false;
      },
      (briefing) async {
        // Send notification
        final notificationService = di.sl<NotificationService>();

        // Create notification summary - handle null insights
        String body;
        if (briefing.insights != null && briefing.insights!.priorities.isNotEmpty) {
          final priorities = briefing.insights!.priorities.take(3).join(', ');
          body = 'Priorities: $priorities';
        } else {
          body = 'Your daily briefing is ready to view!';
        }

        await notificationService.showBriefingNotification(
          title: '${_getGreeting()} Your daily briefing is ready!',
          body: body,
          payload: 'briefing',
        );

        return true;
      },
    );
  } catch (e) {
    print('Daily briefing task error: $e');
    return false;
  }
}

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good Morning!';
  if (hour < 17) return 'Good Afternoon!';
  return 'Good Evening!';
}
