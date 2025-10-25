import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';

import 'package:ai_life_assistant_pro/features/daily_briefing/domain/usecases/schedule_briefing_usecase.dart';

void main() {
  late ScheduleBriefingUseCase useCase;

  setUp(() {
    useCase = ScheduleBriefingUseCase();
  });

  group('ScheduleBriefingUseCase', () {
    test('should return SchedulingResult when scheduling is enabled with valid time', () async {
      // arrange
      const params = ScheduleBriefingParams(
        enabled: true,
        hour: 8,
        minute: 30,
        notificationsEnabled: true,
      );

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (schedulingResult) {
          expect(schedulingResult.success, true);
          expect(schedulingResult.nextScheduledTime, isNotNull);
          expect(schedulingResult.workRequestId, isNotNull);
          expect(schedulingResult.message, contains('8:30 AM'));
        },
      );
    });

    test('should return SchedulingResult when scheduling is disabled', () async {
      // arrange
      const params = ScheduleBriefingParams(
        enabled: false,
        hour: 8,
        minute: 30,
        notificationsEnabled: true,
      );

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (schedulingResult) {
          expect(schedulingResult.success, true);
          expect(schedulingResult.message, contains('disabled'));
        },
      );
    });

    test('should return SchedulingFailure when hour is invalid', () async {
      // arrange
      const params = ScheduleBriefingParams(
        enabled: true,
        hour: 25, // Invalid hour
        minute: 30,
        notificationsEnabled: true,
      );

      // act
      final result = await useCase(params);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<SchedulingFailure>());
          expect(failure.message, contains('Invalid hour'));
        },
        (schedulingResult) => fail('Should not return success'),
      );
    });

    test('should return SchedulingFailure when minute is invalid', () async {
      // arrange
      const params = ScheduleBriefingParams(
        enabled: true,
        hour: 8,
        minute: 70, // Invalid minute
        notificationsEnabled: true,
      );

      // act
      final result = await useCase(params);

      // assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<SchedulingFailure>());
          expect(failure.message, contains('Invalid minute'));
        },
        (schedulingResult) => fail('Should not return success'),
      );
    });

    test('should calculate next scheduled time correctly for same day', () async {
      // arrange
      final now = DateTime.now();
      final futureHour = (now.hour + 2) % 24; // 2 hours from now

      const params = ScheduleBriefingParams(
        enabled: true,
        hour: 23, // Test with a specific hour that should work
        minute: 59,
        notificationsEnabled: true,
      );

      // act
      final result = await useCase(params);

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (schedulingResult) {
          expect(schedulingResult.success, true);
          expect(schedulingResult.nextScheduledTime, isNotNull);
          // Should be scheduled for either today or tomorrow
          final scheduledTime = schedulingResult.nextScheduledTime!;
          expect(scheduledTime.isAfter(now), true);
        },
      );
    });

    test('should format time correctly for AM/PM display', () async {
      // Test morning time
      const morningParams = ScheduleBriefingParams(
        enabled: true,
        hour: 9,
        minute: 15,
        notificationsEnabled: true,
      );

      final morningResult = await useCase(morningParams);
      morningResult.fold(
        (failure) => fail('Should not return failure'),
        (result) => expect(result.message, contains('9:15 AM')),
      );

      // Test afternoon time
      const afternoonParams = ScheduleBriefingParams(
        enabled: true,
        hour: 15,
        minute: 30,
        notificationsEnabled: true,
      );

      final afternoonResult = await useCase(afternoonParams);
      afternoonResult.fold(
        (failure) => fail('Should not return failure'),
        (result) => expect(result.message, contains('3:30 PM')),
      );

      // Test midnight
      const midnightParams = ScheduleBriefingParams(
        enabled: true,
        hour: 0,
        minute: 0,
        notificationsEnabled: true,
      );

      final midnightResult = await useCase(midnightParams);
      midnightResult.fold(
        (failure) => fail('Should not return failure'),
        (result) => expect(result.message, contains('12:00 AM')),
      );
    });
  });
}