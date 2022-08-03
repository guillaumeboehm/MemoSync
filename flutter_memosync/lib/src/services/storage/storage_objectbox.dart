import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_memosync/objectbox.g.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/notification_service.dart';
import 'package:flutter_memosync/src/services/storage/storage_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static ValueNotifier<SettingsObject> settingsStorageStream() {
    final cn = ValueNotifier<SettingsObject>(
      settingsStorage.getAll().isEmpty
          ? SettingsObject()
          : settingsStorage.getAll()[0],
    );
    settingsStorage.query().watch(triggerImmediately: true).listen(
          (query) => cn.value = query.findUnique() ?? SettingsObject(),
        );
    return cn;
  }

  /// Stream of the memo values notifying only on change to the memo [title].
  static ValueNotifier<MemoObject> singleMemoStorageStream(
    String title,
  ) {
    final cn = ValueNotifier<MemoObject>(
      memosStorage
              .query(MemoObject_.title.equals(title))
              .build()
              .findUnique() ??
          MemoObject(),
    );
    memosStorage
        .query(MemoObject_.title.equals(title))
        .watch(triggerImmediately: true)
        .listen(
          (query) => cn.value = query.findUnique() ?? MemoObject(),
        );
    return cn;
  }

  /// Stream of the memos values.
  static ValueNotifier<List<MemoObject>> memosStorageStream() {
    final cn = ValueNotifier<List<MemoObject>>(
      memosStorage.getAll(),
    );
    memosStorage.query().watch(triggerImmediately: true).listen(
          (query) => cn.value = query.find(),
        );
    return cn;
  }

  /// Stream of the user value.
  static ValueNotifier<UserObject> userStorageStream() {
    final cn = ValueNotifier<UserObject>(
      userStorage.getAll().isEmpty ? UserObject() : userStorage.getAll()[0],
    );
    userStorage.query().watch(triggerImmediately: true).listen(
          (query) => cn.value = query.findUnique() ?? UserObject(),
        );
    return cn;
  }

  /// Stream of the settings for the memo [title]
  ///
  /// [setting] allows to listen to a specific setting only
  static ValueNotifier<dynamic> memoSettingsStorageStream(
    String title, {
    String? setting,
  }) {
    final cn = ValueNotifier<dynamic>(
      setting == null
          ? memosStorage
                  .query(MemoObject_.title.equals(title))
                  .build()
                  .findUnique()
                  ?.settings ??
              <String, dynamic>{}
          : memosStorage
              .query(MemoObject_.title.equals(title))
              .build()
              .findUnique()
              ?.settings[setting],
    );
    memosStorage
        .query(MemoObject_.title.equals(title))
        .watch(triggerImmediately: true)
        .listen(
          (query) => cn.value = setting == null
              ? query.findUnique()?.settings
              : query.findUnique()?.settings[setting],
        );
    return cn;
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
    return settingsStorage.getAll().isEmpty
        ? SettingsObject()
        : settingsStorage.getAll()[0];
  }

  /// Stores the value of [settings] in [settingsStorage].
  static void setSettings(SettingsObject? settings) {
    settingsStorage.put(
      settings ?? SettingsObject(),
    );
  }

  /// Returns the entire memos map.
  static Map<dynamic, MemoObject> getMemos() {
    return {
      for (var memo in memosStorage.getAll()) memo.title: memo,
    };
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
      mode: PutMode.put,
    );
    if (obj != null) {
      SharedPreferences.getInstance().then(
        (prefs) {
          if (prefs.getString('currentPermanentMemo')!.startsWith('$memo-')) {
            NotificationService.setPermanentNotification(
              obj.text,
              memoTitle: obj.title,
              memoVersion: obj.version,
            );
          }
        },
      );
    }
  }

  /// Removes [memo] from the cache
  static void removeMemo({required String memo}) {
    try {
      memosStorage.remove(
        memosStorage
            .query(MemoObject_.title.equals(memo))
            .build()
            .findUnique()!
            .id,
      );
    } catch (e) {
      Logger.error('Cannot remove memo: $e');
    }
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
    final newMemo = memosStorage
        .query(MemoObject_.title.equals(memo))
        .build()
        .findUnique()
      ?..settings = settings ?? <String, dynamic>{};
    // ..save();
    if (newMemo == null) return;
    memosStorage.put(newMemo);
  }

  /// Returns the user object or ```null``` if not set.
  static UserObject? getUser() {
    return userStorage.getAll().isEmpty ? null : userStorage.getAll()[0];
  }

  /// Stores the value of [user] in [userStorage].
  static void setUser(UserObject? user) {
    userStorage.put(
      user ?? UserObject(),
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
