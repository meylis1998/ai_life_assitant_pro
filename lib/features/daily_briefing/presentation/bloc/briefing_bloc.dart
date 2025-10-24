import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/daily_briefing.dart';
import '../../domain/repositories/briefing_repository.dart';
import '../../domain/usecases/generate_daily_briefing_usecase.dart';

part 'briefing_event.dart';
part 'briefing_state.dart';

class BriefingBloc extends Bloc<BriefingEvent, BriefingState> {
  final GenerateDailyBriefingUseCase generateDailyBriefingUseCase;
  final BriefingRepository briefingRepository;

  BriefingBloc({
    required this.generateDailyBriefingUseCase,
    required this.briefingRepository,
  }) : super(const BriefingInitial()) {
    on<BriefingRequested>(_onBriefingRequested);
    on<BriefingRefreshed>(_onBriefingRefreshed);
    on<CachedBriefingRequested>(_onCachedBriefingRequested);
    on<PreferencesSaved>(_onPreferencesSaved);
    on<PreferencesRequested>(_onPreferencesRequested);
  }

  Future<void> _onBriefingRequested(
    BriefingRequested event,
    Emitter<BriefingState> emit,
  ) async {
    emit(const BriefingLoading());

    // Get preferences first
    final preferencesResult = await briefingRepository.getPreferences();

    final preferences = preferencesResult.fold(
      (failure) => null,
      (prefs) => prefs,
    );

    if (preferences == null) {
      final failure = preferencesResult.fold((f) => f, (_) => null);
      if (!emit.isDone) {
        emit(BriefingError(message: 'Failed to load preferences: ${failure?.message ?? "Unknown error"}'));
      }
      return;
    }

    // Generate briefing
    final result = await generateDailyBriefingUseCase(
      GenerateDailyBriefingParams(
        preferences: preferences,
        forceRefresh: event.forceRefresh,
      ),
    );

    final briefing = result.fold(
      (failure) => null,
      (b) => b,
    );

    if (briefing != null) {
      if (!emit.isDone) {
        emit(BriefingLoaded(
          briefing: briefing,
          preferences: preferences,
          isFromCache: false,
        ));
      }
    } else {
      // Try to load cached briefing on error
      final failure = result.fold((f) => f, (_) => null);
      final cachedResult = await briefingRepository.getCachedBriefing();

      final cached = cachedResult.fold(
        (_) => null,
        (c) => c,
      );

      if (!emit.isDone) {
        if (cached != null) {
          emit(BriefingError(
            message: failure?.message ?? "Unknown error",
            cachedBriefing: cached,
          ));
        } else {
          emit(BriefingError(message: failure?.message ?? "Unknown error"));
        }
      }
    }
  }

  Future<void> _onBriefingRefreshed(
    BriefingRefreshed event,
    Emitter<BriefingState> emit,
  ) async {
    // Keep current state while refreshing
    final currentState = state;

    // Get preferences
    final preferencesResult = await briefingRepository.getPreferences();

    final preferences = preferencesResult.fold(
      (failure) => null,
      (prefs) => prefs,
    );

    if (preferences == null) {
      if (!emit.isDone) {
        if (currentState is BriefingLoaded) {
          emit(currentState); // Keep current state on preferences error
        } else {
          emit(BriefingError(message: 'Failed to load preferences'));
        }
      }
      return;
    }

    // Generate new briefing with force refresh
    final result = await generateDailyBriefingUseCase(
      GenerateDailyBriefingParams(
        preferences: preferences,
        forceRefresh: true,
      ),
    );

    final briefing = result.fold(
      (failure) => null,
      (b) => b,
    );

    if (!emit.isDone) {
      if (briefing != null) {
        emit(BriefingLoaded(
          briefing: briefing,
          preferences: preferences,
          isFromCache: false,
        ));
      } else {
        final failure = result.fold((f) => f, (_) => null);
        if (currentState is BriefingLoaded) {
          // Keep showing current data but with error message
          emit(currentState);
        } else {
          emit(BriefingError(message: failure?.message ?? "Unknown error"));
        }
      }
    }
  }

  Future<void> _onCachedBriefingRequested(
    CachedBriefingRequested event,
    Emitter<BriefingState> emit,
  ) async {
    emit(const BriefingLoading());

    final preferencesResult = await briefingRepository.getPreferences();
    final cachedResult = await briefingRepository.getCachedBriefing();

    final preferences = preferencesResult.fold(
      (failure) => null,
      (prefs) => prefs,
    );

    if (preferences == null) {
      if (!emit.isDone) {
        emit(BriefingError(message: 'Failed to load preferences'));
      }
      return;
    }

    final cached = cachedResult.fold(
      (failure) => null,
      (briefing) => briefing,
    );

    if (!emit.isDone) {
      if (cached != null) {
        emit(BriefingLoaded(
          briefing: cached,
          preferences: preferences,
          isFromCache: true,
        ));
      } else {
        emit(BriefingError(message: 'No cached briefing available'));
      }
    }
  }

  Future<void> _onPreferencesSaved(
    PreferencesSaved event,
    Emitter<BriefingState> emit,
  ) async {
    final result = await briefingRepository.savePreferences(event.preferences);

    result.fold(
      (failure) {
        // Could emit an error state or show a snackbar
      },
      (_) {
        // Preferences saved successfully
        // If currently loaded, update with new preferences
        if (state is BriefingLoaded) {
          final currentState = state as BriefingLoaded;
          if (!emit.isDone) {
            emit(currentState.copyWith(preferences: event.preferences));
          }
        }
      },
    );
  }

  Future<void> _onPreferencesRequested(
    PreferencesRequested event,
    Emitter<BriefingState> emit,
  ) async {
    final result = await briefingRepository.getPreferences();

    result.fold(
      (failure) {
        if (!emit.isDone) {
          emit(BriefingError(message: 'Failed to load preferences'));
        }
      },
      (preferences) {
        if (!emit.isDone) {
          emit(PreferencesLoaded(preferences));
        }
      },
    );
  }
}
