import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_memosync/objectbox.g.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/storage/storage_interface.dart';

/// Handles all the storage using Hive
class Storage extends StorageInterface {
  /// ObjectBox store
  static late final Store store;

  /// Settings ObjectBox storage box.
  static final settingsStorage = store.box<SettingsObject>();

  /// Memos ObjectBox storage box.
  static final memosStorage = store.box<MemoObject>();

  /// User ObjectBox storage box.
  static final userStorage = store.box<UserObject>();

  /// Stream of the settings value.
  static final settingsStorageStream = settingsStorage.query().build().stream();

  /// Stream of the memo values notifying only on change to the memo [title].
  static Stream<MemoObject> singleMemoStorageStream(
    String title,
  ) =>
      memosStorage.query(MemoObject_.title.equals(title)).build().stream();

  /// Stream of the memos values.
  static final memosStorageStream = memosStorage.query().build().stream();

  /// Stream of the user value.
  static final userStorageStream = userStorage.query().build().stream();

  /// Stream of the settings for the memo [title]
  ///
  /// [setting] allows to listen to a specific setting only
  static ValueNotifier<dynamic> memoSettingsStorageStream(
    String title, {
    String? setting,
  }) {
    final vl = ValueNotifier<dynamic>(
      memosStorage
              .query(MemoObject_.title.equals(title))
              .build()
              .findFirst()
              ?.settings ??
          {},
    );
    memosStorage
        .query(MemoObject_.title.equals(title))
        .build()
        .stream()
        .listen((query) {
      vl
        ..value = (setting == null ? query.settings : query.settings[setting])
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        ..notifyListeners();
      // Not supposed to do that but I don't know how to make it work otherwise
    });
    return vl;
  }

  /// Initializes ObjectBox store.
  static Future<void> initStorage({ByteData? existingStore}) async {
    store = (existingStore != null)
        ? Store.fromReference(
            getObjectBoxModel(),
            existingStore,
          )
        : await openStore();
  }

  /// Returns the settings object or a new object if it is not set.
  static SettingsObject getSettings() {
    return settingsStorage.get(0) ?? SettingsObject();
  }

  /// Stores the value of [settings] in [settingsStorage].
  static void setSettings(SettingsObject? settings) {
    settingsStorage.put(
      settings ?? SettingsObject(),
      mode: settings != null ? PutMode.update : PutMode.put,
    );
  }

  /// Returns the entire memos map.
  static Map<dynamic, MemoObject> getMemos() {
    return memosStorage.getAll().asMap();
  }

  /// Returns a specific memo
  static MemoObject? getMemo({required String memo}) {
    return memosStorage
        .query(MemoObject_.title.equals(memo))
        .build()
        .findUnique();
  }

  /// Stores [obj] as [memo] in [memosStorage]
  static void setMemo({
    required String memo,
    MemoObject? obj,
  }) {
    memosStorage.put(
      obj ?? MemoObject(),
      mode: obj == null ? PutMode.put : PutMode.update,
    );
  }

  /// Removes [memo] from the cache
  static void removeMemo({required String memo}) {
    memosStorage
        .query(MemoObject_.title.equals(memo))
        .build()
        .findUnique()
        ?.delete();
  }

  /// Returns the settings object for [memo] or a new object if it is not set.
  static dynamic getMemoSettings(String memo, {String? setting}) {
    var ret = memosStorage
        .query(MemoObject_.title.equals(memo))
        .build()
        .findUnique()
        ?.settings as dynamic;
    if (ret != null && setting != null) {
      ret = (ret as Map<String, dynamic>)[setting];
    }
    return ret;
  }

  /// Stores [memo] settings
  static void setMemoSettings({
    required String memo,
    Map<String, dynamic>? settings,
  }) {
    memosStorage.query(MemoObject_.title.equals(memo)).build().findUnique()
      ?..settings = settings ?? <String, dynamic>{}
      ..save();
  }

  /// Returns the user object or ```null``` if not set.
  static UserObject? getUser() {
    return userStorage.get(0);
  }

  /// Stores the value of [user] in [userStorage].
  static void setUser(UserObject? user) {
    userStorage.put(
      user ?? UserObject(),
      mode: user == null ? PutMode.put : PutMode.update,
    );
  }

  /// Deletes the stored user value of [userStorage].
  static void removeUser() {
    userStorage.removeAll();
  }

  /// Deletes all the locally stored memos.
  static void removeAllMemos() {
    memosStorage.removeAll();
  }

  /// Deletes all the locally stored settings.
  static void removeAllSettings() {
    settingsStorage.removeAll();
  }
}
