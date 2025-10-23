import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/generate_daily_briefing.dart';
import '../../domain/usecases/get_cached_briefing.dart';
import 'briefing_event.dart';
import 'briefing_state.dart';

class BriefingBloc extends Bloc<BriefingEvent, BriefingState> {
  final GenerateDailyBriefing generateDailyBriefing;
  final GetCachedBriefing getCachedBriefing;

  BriefingBloc({
    required this.generateDailyBriefing,
    required this.getCachedBriefing,
  }) : super(const BriefingInitial()) {
    on<BriefingRequested>(_onBriefingRequested);
    on<BriefingRefreshRequested>(_onBriefingRefreshRequested);
    on<CachedBriefingRequested>(_onCachedBriefingRequested);
  }

  Future<void> _onBriefingRequested(
    BriefingRequested event,
    Emitter<BriefingState> emit,
  ) async {
    emit(const BriefingLoading());

    // Try to load cached briefing first
    final cachedResult = await getCachedBriefing(NoParams());
    cachedResult.fold(
      (failure) {}, // Ignore cache failure, will fetch fresh data
      (briefing) {
        // Show cached data while fetching fresh
        emit(BriefingLoaded(briefing: briefing, isCached: true));
      },
    );

    // Fetch fresh briefing
    final result = await generateDailyBriefing(
      GenerateDailyBriefingParams(
        userName: event.userName,
        cityName: event.cityName,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    result.fold(
      (failure) => emit(BriefingError(message: failure.message)),
      (briefing) => emit(BriefingLoaded(briefing: briefing, isCached: false)),
    );
  }

  Future<void> _onBriefingRefreshRequested(
    BriefingRefreshRequested event,
    Emitter<BriefingState> emit,
  ) async {
    emit(const BriefingLoading());

    final result = await generateDailyBriefing(
      GenerateDailyBriefingParams(
        userName: event.userName,
        cityName: event.cityName,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    result.fold(
      (failure) => emit(BriefingError(message: failure.message)),
      (briefing) => emit(BriefingLoaded(briefing: briefing, isCached: false)),
    );
  }

  Future<void> _onCachedBriefingRequested(
    CachedBriefingRequested event,
    Emitter<BriefingState> emit,
  ) async {
    emit(const BriefingLoading());

    final result = await getCachedBriefing(NoParams());

    result.fold(
      (failure) => emit(const BriefingError(
          message: 'No cached briefing available. Pull to refresh.')),
      (briefing) => emit(BriefingLoaded(briefing: briefing, isCached: true)),
    );
  }
}
