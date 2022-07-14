import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/storage/storage_interface.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

/// Handles all the storage using Hive
class Storage extends StorageInterface {
  /// Settings Hive storage box.
  static final settingsStorage = Hive.box<SettingsObject>('settings');

  /// Memos Hive storage box.
  static final memosStorage = Hive.box<MemoObject>('memos');

  /// User Hive storage box.
  static final userStorage = Hive.box<UserObject>('user');

  /// Stream of the settings value.
  static final settingsStorageStream =
      Hive.box<SettingsObject>('settings').listenable();

  /// Stream of the memo values notifying only on change to the memo [title].
  static ValueListenable<Box<MemoObject>> singleMemoStorageStream(
    String title,
  ) =>
      Hive.box<MemoObject>('memos').listenable(keys: <dynamic>[title]);

  /// Stream of the memos values.
  static final memosStorageStream = Hive.box<MemoObject>('memos').listenable();

  /// Stream of the user value.
  static final userStorageStream = Hive.box<UserObject>('user').listenable();

  /// Stream of the settings for the memo [title]
  ///
  /// [setting] allows to listen to a specific setting only
  static ValueListenable<dynamic> memoSettingsStorageStream(
    String title, {
    String? setting,
  }) {
    final vl = ValueNotifier<dynamic>(
      Hive.box<MemoObject>('memos').get(title)?.settings ?? {},
    );

    Hive.box<MemoObject>('memos').watch(key: title).listen((BoxEvent event) {
      vl
        ..value = (setting == null
            ? (event.value as MemoObject).settings
            : (event.value as MemoObject).settings[setting])
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        ..notifyListeners();
      // Not supposed to do that but I don't know how to make it work otherwise
    });
    return vl;
  }

  /// Initializes Hive and all the boxes.
  static Future<void> initStorage({ByteData? existingStore}) async {
    if (UniversalPlatform.isWeb) {
      await Hive.initFlutter();
    } else {
      final storageDir = '${(await getApplicationSupportDirectory()).path}'
          "${kDebugMode ? '_debug' : ''}";
      unawaited(Logger.info('Using storage: $storageDir'));
      await Hive.initFlutter(
        storageDir.runtimeType == String ? storageDir : null,
      );
    }

    Hive
      ..registerAdapter(SettingsObjectAdapter())
      ..registerAdapter(MemoObjectAdapter())
      ..registerAdapter(NotificationRepeatEveryAdapter())
      ..registerAdapter(UserObjectAdapter());

    Future<void> openBox<T>(String box) async {
      try {
        await Hive.openBox<T>(box);
      } catch (_) {
        if (kDebugMode) print('Reseting $box');
        await Hive.deleteBoxFromDisk(box);
        await Hive.openBox<T>(box);
      }
    }

    await openBox<SettingsObject>('settings');
    await openBox<MemoObject>('memos');
    await openBox<UserObject>('user');
  }

  /// Returns the settings object or a new object if it is not set.
  static SettingsObject getSettings() {
    final settings = settingsStorage.get('settings');
    return settings ?? SettingsObject();
  }

  /// Stores the value of [settings] in [settingsStorage].
  static void setSettings(SettingsObject? settings) {
    settingsStorage.put('settings', settings ?? SettingsObject());
  }

  /// Returns the entire memos map.
  static Map<dynamic, MemoObject> getMemos() {
    return memosStorage.toMap();
  }

  /// Returns a specific memo
  static MemoObject? getMemo({required dynamic memo}) {
    return memosStorage.get(memo);
  }

  /// Stores [obj] as [memo] in [memosStorage]
  static void setMemo({
    required dynamic memo,
    MemoObject? obj,
  }) {
    memosStorage.put(memo, obj ?? MemoObject());
  }

  /// Removes [memo] from the cache
  static void removeMemo({required dynamic memo}) {
    memosStorage.delete(memo);
  }

  /// Returns the settings object for [memo] or a new object if it is not set.
  static dynamic getMemoSettings(String memo, {String? setting}) {
    var ret = memosStorage.get(memo)?.settings as dynamic;
    if (ret != null && setting != null) {
      ret = (ret as Map<String, dynamic>)[setting];
    }
    return ret;
  }

  /// Stores [memo] settings
  static void setMemoSettings({
    required dynamic memo,
    Map<String, dynamic>? settings,
  }) {
    memosStorage.put(
      memo,
      (memosStorage.get(memo) ?? MemoObject())
        ..settings = settings ?? <String, dynamic>{},
    );
  }

  /// Returns the user object or ```null``` if not set.
  static UserObject? getUser() {
    return userStorage.get('user');
  }

  /// Stores the value of [user] in [userStorage].
  static void setUser(UserObject? user) {
    userStorage.put('user', user ?? UserObject());
  }

  /// Deletes the stored user value of [userStorage].
  static void removeUser() {
    userStorage.delete('user');
  }

  /// Deletes all the locally stored memos.
  static void removeAllMemos() {
    memosStorage.deleteAll(memosStorage.keys);
  }

  /// Deletes all the locally stored settings.
  static void removeAllSettings() {
    settingsStorage.deleteAll(memosStorage.keys);
  }
}
