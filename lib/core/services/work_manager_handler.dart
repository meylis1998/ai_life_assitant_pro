import 'package:workmanager/workmanager.dart';

import '../../features/daily_briefing/domain/usecases/generate_daily_briefing.dart';
import '../../injection_container.dart' as di;
import 'briefing_preferences_service.dart';
import 'notification_service.dart';

/// Callback for WorkManager background tasks
/// This function must be a top-level function
@pragma('vm:entry-point')
void workManagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize dependencies if needed
      if (!di.sl.isRegistered<BriefingPreferencesService>()) {
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
    final prefsService = di.sl<BriefingPreferencesService>();

    // Check if notifications are enabled
    if (!prefsService.notificationsEnabled) {
      return true; // Task succeeded, just didn't send notification
    }

    // Generate briefing
    final generateBriefing = di.sl<GenerateDailyBriefing>();
    final result = await generateBriefing(
      GenerateDailyBriefingParams(
        cityName: prefsService.useGps ? null : prefsService.city,
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

        // Create notification summary
        final priorities = briefing.insights.priorities.take(3).join(', ');
        final body = 'Priorities: $priorities';

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
