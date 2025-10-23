// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_briefing_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyBriefingModelAdapter extends TypeAdapter<DailyBriefingModel> {
  @override
  final int typeId = 10;

  @override
  DailyBriefingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyBriefingModel(
      hiveId: fields[0] as String,
      hiveGeneratedAt: fields[1] as DateTime,
      hiveGreeting: fields[2] as String,
      hiveWeather: (fields[3] as Map).cast<String, dynamic>(),
      hiveTopNews: (fields[4] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      hiveTodayEvents: (fields[5] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      hiveInsights: (fields[6] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyBriefingModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.hiveId)
      ..writeByte(1)
      ..write(obj.hiveGeneratedAt)
      ..writeByte(2)
      ..write(obj.hiveGreeting)
      ..writeByte(3)
      ..write(obj.hiveWeather)
      ..writeByte(4)
      ..write(obj.hiveTopNews)
      ..writeByte(5)
      ..write(obj.hiveTodayEvents)
      ..writeByte(6)
      ..write(obj.hiveInsights);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyBriefingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AIInsightsModelAdapter extends TypeAdapter<AIInsightsModel> {
  @override
  final int typeId = 11;

  @override
  AIInsightsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AIInsightsModel(
      hiveSummary: fields[0] as String,
      hivePriorities: (fields[1] as List).cast<String>(),
      hiveTrafficAlert: fields[2] as String?,
      hiveSuggestions: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AIInsightsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.hiveSummary)
      ..writeByte(1)
      ..write(obj.hivePriorities)
      ..writeByte(2)
      ..write(obj.hiveTrafficAlert)
      ..writeByte(3)
      ..write(obj.hiveSuggestions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIInsightsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
