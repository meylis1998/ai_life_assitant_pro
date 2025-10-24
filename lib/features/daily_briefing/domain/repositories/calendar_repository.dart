import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/calendar_event.dart';

/// Abstract repository interface for calendar data
abstract class CalendarRepository {
  /// Request calendar permission
  ///
  /// Returns:
  /// - Right(true) if permission granted
  /// - Right(false) if permission denied
  /// - Left(Failure) on error
  Future<Either<Failure, bool>> requestPermission();

  /// Check if calendar permission is granted
  ///
  /// Returns:
  /// - Right(true) if permission granted
  /// - Right(false) if permission not granted
  /// - Left(Failure) on error
  Future<Either<Failure, bool>> hasPermission();

  /// Get today's calendar events
  ///
  /// Returns:
  /// - Right(List<CalendarEvent>) on success (empty list if no events)
  /// - Left(Failure) on error
  Future<Either<Failure, List<CalendarEvent>>> getTodayEvents();

  /// Get events for a specific date range
  ///
  /// Parameters:
  /// - [startDate]: Start date
  /// - [endDate]: End date
  ///
  /// Returns:
  /// - Right(List<CalendarEvent>) on success
  /// - Left(Failure) on error
  Future<Either<Failure, List<CalendarEvent>>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  });
}
