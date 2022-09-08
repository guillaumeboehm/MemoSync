// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsObjectAdapter extends TypeAdapter<SettingsObject> {
  @override
  final int typeId = 0;

  @override
  SettingsObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsObject()
      ..notificationsEnabled = fields[4] as bool
      ..locale = fields[1] as String?
      ..onStartup = fields[7] as bool
      ..launchMinimized = fields[8] as bool
      ..closeMinimized = fields[9] as bool
      ..darkMode = fields[0] as bool
      ..autoSave = fields[2] as bool
      ..autoSaveInterval = fields[3] as int
      ..bgSync = fields[5] as bool
      ..bgSyncWifiOnly = fields[6] as bool
      ..analytics = fields[10] as bool;
  }

  @override
  void write(BinaryWriter writer, SettingsObject obj) {
    writer
      ..writeByte(11)
      ..writeByte(4)
      ..write(obj.notificationsEnabled)
      ..writeByte(1)
      ..write(obj.locale)
      ..writeByte(7)
      ..write(obj.onStartup)
      ..writeByte(8)
      ..write(obj.launchMinimized)
      ..writeByte(9)
      ..write(obj.closeMinimized)
      ..writeByte(0)
      ..write(obj.darkMode)
      ..writeByte(2)
      ..write(obj.autoSave)
      ..writeByte(3)
      ..write(obj.autoSaveInterval)
      ..writeByte(5)
      ..write(obj.bgSync)
      ..writeByte(6)
      ..write(obj.bgSyncWifiOnly)
      ..writeByte(10)
      ..write(obj.analytics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
