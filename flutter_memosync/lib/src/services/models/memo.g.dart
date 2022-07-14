// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoObjectAdapter extends TypeAdapter<MemoObject> {
  @override
  final int typeId = 3;

  @override
  MemoObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MemoObject()
      ..title = fields[0] as String
      ..text = fields[1] as String
      ..lastSynchedText = fields[5] as String
      ..version = fields[2] as int
      ..patches = fields[4] as String
      ..settings = (fields[7] as Map).cast<String, dynamic>();
  }

  @override
  void write(BinaryWriter writer, MemoObject obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(5)
      ..write(obj.lastSynchedText)
      ..writeByte(2)
      ..write(obj.version)
      ..writeByte(4)
      ..write(obj.patches)
      ..writeByte(7)
      ..write(obj.settings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationTypesAdapter extends TypeAdapter<NotificationTypes> {
  @override
  final int typeId = 4;

  @override
  NotificationTypes read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 2:
        return NotificationTypes.fixedTime;
      case 3:
        return NotificationTypes.timePeriod;
      case 4:
        return NotificationTypes.unknown;
      default:
        return NotificationTypes.fixedTime;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationTypes obj) {
    switch (obj) {
      case NotificationTypes.fixedTime:
        writer.writeByte(2);
        break;
      case NotificationTypes.timePeriod:
        writer.writeByte(3);
        break;
      case NotificationTypes.unknown:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTypesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotificationRepeatEveryAdapter
    extends TypeAdapter<NotificationRepeatEvery> {
  @override
  final int typeId = 5;

  @override
  NotificationRepeatEvery read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return NotificationRepeatEvery.day;
      case 1:
        return NotificationRepeatEvery.week;
      case 2:
        return NotificationRepeatEvery.month;
      case 3:
        return NotificationRepeatEvery.year;
      case 4:
        return NotificationRepeatEvery.period;
      case 6:
        return NotificationRepeatEvery.unknown;
      default:
        return NotificationRepeatEvery.day;
    }
  }

  @override
  void write(BinaryWriter writer, NotificationRepeatEvery obj) {
    switch (obj) {
      case NotificationRepeatEvery.day:
        writer.writeByte(0);
        break;
      case NotificationRepeatEvery.week:
        writer.writeByte(1);
        break;
      case NotificationRepeatEvery.month:
        writer.writeByte(2);
        break;
      case NotificationRepeatEvery.year:
        writer.writeByte(3);
        break;
      case NotificationRepeatEvery.period:
        writer.writeByte(4);
        break;
      case NotificationRepeatEvery.unknown:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationRepeatEveryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
