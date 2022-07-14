import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:objectbox/objectbox.dart';

part 'user.g.dart';

/// [HiveObject] used to store all the user data.
@Entity()
@HiveType(typeId: 1)
class UserObject extends HiveObject {
  /// Default constructor.
  UserObject();

  /// ObjectBox id
  int id = 0;

  /// User email.
  @HiveField(0)
  String email = '';

  /// User access token.
  @HiveField(1)
  String accessToken = '';

  /// User refresh token.
  @HiveField(2)
  String refreshToken = '';
}
