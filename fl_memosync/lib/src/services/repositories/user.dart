import 'dart:async';
import 'package:memosync/src/services/models/models.dart'
    show UserObject;
import 'package:memosync/src/services/storage/storage.dart';

/// Repository managing the user data.
class UserRepository {
  UserObject? _user;

  /// Returns the stored [UserObject] or constructs it if none is stored.
  Future<UserObject?> getUser() async {
    return _user ??= Storage.getUser();
  }

  /// Stores a [UserObject] and returns it.
  Future<UserObject?> saveUser({
    String? email,
    String? accessToken,
    String? refreshToken,
  }) async {
    _user ??= Storage.getUser() ?? UserObject();
    if (email != null) _user?.email = email;
    if (accessToken != null) _user?.accessToken = accessToken;
    if (refreshToken != null) _user?.refreshToken = refreshToken;
    Storage.setUser(_user);
    return _user;
  }

  /// Deletes the stored [UserObject].
  Future<void> removeUser() async {
    Storage.removeUser();
  }
}
