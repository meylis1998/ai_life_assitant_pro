part of 'briefing_bloc.dart';

/// Base class for all briefing events
abstract class BriefingEvent extends Equatable {
  const BriefingEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request briefing generation
class BriefingRequested extends BriefingEvent {
  final bool forceRefresh;

  const BriefingRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Event to refresh the briefing (pull-to-refresh)
class BriefingRefreshed extends BriefingEvent {
  const BriefingRefreshed();
}

/// Event to load cached briefing
class CachedBriefingRequested extends BriefingEvent {
  const CachedBriefingRequested();
}

/// Event to save preferences
class PreferencesSaved extends BriefingEvent {
  final BriefingPreferences preferences;

  const PreferencesSaved(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

/// Event to load preferences
class PreferencesRequested extends BriefingEvent {
  const PreferencesRequested();
}
