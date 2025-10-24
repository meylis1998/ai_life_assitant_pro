import 'package:equatable/equatable.dart';

/// Represents AI-generated insights and recommendations
class AIInsights extends Equatable {
  final String greeting;
  final String summary;
  final List<String> priorities;
  final List<String> suggestions;
  final String? weatherAlert;
  final String? trafficAlert;
  final DateTime generatedAt;

  const AIInsights({
    required this.greeting,
    required this.summary,
    required this.priorities,
    required this.suggestions,
    this.weatherAlert,
    this.trafficAlert,
    required this.generatedAt,
  });

  @override
  List<Object?> get props => [
        greeting,
        summary,
        priorities,
        suggestions,
        weatherAlert,
        trafficAlert,
        generatedAt,
      ];

  /// Check if there are any alerts
  bool get hasAlerts =>
      (weatherAlert != null && weatherAlert!.isNotEmpty) ||
      (trafficAlert != null && trafficAlert!.isNotEmpty);

  /// Get all alerts as a list
  List<String> get allAlerts {
    final alerts = <String>[];
    if (weatherAlert != null && weatherAlert!.isNotEmpty) {
      alerts.add(weatherAlert!);
    }
    if (trafficAlert != null && trafficAlert!.isNotEmpty) {
      alerts.add(trafficAlert!);
    }
    return alerts;
  }
}
