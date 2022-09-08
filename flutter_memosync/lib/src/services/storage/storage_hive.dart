import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/notification_service.dart';
import 'package:flutter_memosync/src/services/storage/storage_interface.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static ValueNotifier<SettingsObject> settingsStorageStream() {
    final vn = ValueNotifier<SettingsObject>(
      Hive.box<SettingsObject>('settings').get('settings') ?? SettingsObject(),
    );
    Hive.box<SettingsObject>('settings').listenable().addListener(() {
      vn.value = Hive.box<SettingsObject>('settings').get('settings') ??
          SettingsObject();
    });
    return vn;
  }

  /// Stream of the memo values notifying only on change to the memo [title].
  static ValueNotifier<MemoObject> singleMemoStorageStream(String title) {
    final vn = ValueNotifier<MemoObject>(
      Hive.box<MemoObject>('memos').get(title) ?? MemoObject(),
    );
    Hive.box<MemoObject>('settings')
        .listenable(keys: <dynamic>[title]).addListener(() {
      vn.value = Hive.box<MemoObject>('settings').get(title) ?? MemoObject();
    });
    return vn;
  }

  /// Stream of the memos values.
  static ValueNotifier<List<MemoObject>> memosStorageStream() {
    final vn = ValueNotifier<List<MemoObject>>(
      Hive.box<MemoObject>('memos').values.toList(),
    );
    Hive.box<MemoObject>('memos').listenable().addListener(() {
      vn.value = Hive.box<MemoObject>('memos').values.toList();
    });
    return vn;
  }

  /// Stream of the user value.
  static ValueNotifier<UserObject> userStorageStream() {
    final vn = ValueNotifier<UserObject>(
      Hive.box<UserObject>('user').get('user') ?? UserObject(),
    );
    Hive.box<UserObject>('user').listenable().addListener(() {
      vn.value = Hive.box<UserObject>('user').get('user') ?? UserObject();
    });
    return vn;
  }

  /// Stream of the settings for the memo [title]
  ///
  /// [setting] allows to listen to a specific setting only
  static ValueListenable<dynamic> memoSettingsStorageStream(
    String title, {
    String? setting,
  }) {
    final vn = ValueNotifier<dynamic>(
      Hive.box<MemoObject>('memos').get(title)?.settings ?? {},
    );

    Hive.box<MemoObject>('memos').watch(key: title).listen((BoxEvent event) {
      vn
        ..value = (setting == null
            ? (event.value as MemoObject).settings
            : (event.value as MemoObject).settings[setting])
        // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
        ..notifyListeners();
      // Not supposed to do that but I don't know how to make it work otherwise
    });
    return vn;
  }

  /// Initializes Hive and all the boxes.
  static Future<bool> initStorage({ByteData? existingStore}) async {
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

    return true;
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
    if (obj != null) {
      SharedPreferences.getInstance().then(
        (prefs) {
          if (prefs
              .getString('currentPermanentMemo')!
              .startsWith('${memo as String}-')) {
            log('Should notify');
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
  static void removeMemo({required dynamic memo}) {
    memosStorage.delete(memo);
    SharedPreferences.getInstance().then(
      (prefs) {
        if (prefs
            .getString('currentPermanentMemo')!
            .startsWith('${memo as String}-')) {
          NotificationService.unsetPermanentNotification();
        }
      },
    );
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
