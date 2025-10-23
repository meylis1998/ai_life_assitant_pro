import 'package:equatable/equatable.dart';

abstract class BriefingEvent extends Equatable {
  const BriefingEvent();

  @override
  List<Object?> get props => [];
}

class BriefingRequested extends BriefingEvent {
  final String? userName;
  final String? cityName;
  final double? latitude;
  final double? longitude;

  const BriefingRequested({
    this.userName,
    this.cityName,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [userName, cityName, latitude, longitude];
}

class BriefingRefreshRequested extends BriefingEvent {
  final String? userName;
  final String? cityName;
  final double? latitude;
  final double? longitude;

  const BriefingRefreshRequested({
    this.userName,
    this.cityName,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [userName, cityName, latitude, longitude];
}

class CachedBriefingRequested extends BriefingEvent {
  const CachedBriefingRequested();
}
