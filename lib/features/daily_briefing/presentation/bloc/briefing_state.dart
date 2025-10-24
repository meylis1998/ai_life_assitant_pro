part of 'briefing_bloc.dart';

/// Base class for all briefing states
abstract class BriefingState extends Equatable {
  const BriefingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class BriefingInitial extends BriefingState {
  const BriefingInitial();
}

/// Loading state
class BriefingLoading extends BriefingState {
  const BriefingLoading();
}

/// Loaded state with briefing data
class BriefingLoaded extends BriefingState {
  final DailyBriefing briefing;
  final BriefingPreferences preferences;
  final bool isFromCache;

  const BriefingLoaded({
    required this.briefing,
    required this.preferences,
    this.isFromCache = false,
  });

  @override
  List<Object?> get props => [briefing, preferences, isFromCache];

  BriefingLoaded copyWith({
    DailyBriefing? briefing,
    BriefingPreferences? preferences,
    bool? isFromCache,
  }) {
    return BriefingLoaded(
      briefing: briefing ?? this.briefing,
      preferences: preferences ?? this.preferences,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// Error state
class BriefingError extends BriefingState {
  final String message;
  final DailyBriefing? cachedBriefing;

  const BriefingError({
    required this.message,
    this.cachedBriefing,
  });

  @override
  List<Object?> get props => [message, cachedBriefing];
}

/// Preferences loaded state
class PreferencesLoaded extends BriefingState {
  final BriefingPreferences preferences;

  const PreferencesLoaded(this.preferences);

  @override
  List<Object?> get props => [preferences];
}
