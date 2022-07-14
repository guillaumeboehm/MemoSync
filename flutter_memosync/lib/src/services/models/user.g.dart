// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserObjectAdapter extends TypeAdapter<UserObject> {
  @override
  final int typeId = 1;

  @override
  UserObject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserObject()
      ..email = fields[0] as String
      ..accessToken = fields[1] as String
      ..refreshToken = fields[2] as String;
  }

  @override
  void write(BinaryWriter writer, UserObject obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.accessToken)
      ..writeByte(2)
      ..write(obj.refreshToken);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserObjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
