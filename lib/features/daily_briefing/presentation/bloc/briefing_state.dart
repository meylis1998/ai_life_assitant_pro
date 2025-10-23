import 'package:equatable/equatable.dart';

import '../../domain/entities/daily_briefing.dart';

abstract class BriefingState extends Equatable {
  const BriefingState();

  @override
  List<Object?> get props => [];
}

class BriefingInitial extends BriefingState {
  const BriefingInitial();
}

class BriefingLoading extends BriefingState {
  const BriefingLoading();
}

class BriefingLoaded extends BriefingState {
  final DailyBriefing briefing;
  final bool isCached;

  const BriefingLoaded({
    required this.briefing,
    this.isCached = false,
  });

  @override
  List<Object?> get props => [briefing, isCached];
}

class BriefingError extends BriefingState {
  final String message;

  const BriefingError({required this.message});

  @override
  List<Object?> get props => [message];
}
