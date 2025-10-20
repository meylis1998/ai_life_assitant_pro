import 'package:intl/intl.dart';

/// Utility class for date formatting operations
class DateFormatter {
  DateFormatter._();

  /// Format date to display time (e.g., "10:30 AM")
  static String formatTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  /// Format date to display day and time (e.g., "Today at 10:30 AM")
  static String formatDayTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime).inDays;

    if (difference == 0) {
      return 'Today at ${formatTime(dateTime)}';
    } else if (difference == 1) {
      return 'Yesterday at ${formatTime(dateTime)}';
    } else if (difference < 7) {
      return '${DateFormat.EEEE().format(dateTime)} at ${formatTime(dateTime)}';
    } else {
      return DateFormat.yMMMd().add_jm().format(dateTime);
    }
  }

  /// Format date for API requests (ISO 8601)
  static String toIso8601(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Parse ISO 8601 date string
  static DateTime fromIso8601(String dateString) {
    return DateTime.parse(dateString);
  }

  /// Check if date is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Get relative time (e.g., "2 hours ago", "in 3 days")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future dates
      final futureDiff = difference.abs();
      if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} ${futureDiff.inDays == 1 ? 'day' : 'days'}';
      } else if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} ${futureDiff.inHours == 1 ? 'hour' : 'hours'}';
      } else if (futureDiff.inMinutes > 0) {
        return 'in ${futureDiff.inMinutes} ${futureDiff.inMinutes == 1 ? 'minute' : 'minutes'}';
      } else {
        return 'in a few seconds';
      }
    } else {
      // Past dates
      if (difference.inDays > 0) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else {
        return 'just now';
      }
    }
  }
}
