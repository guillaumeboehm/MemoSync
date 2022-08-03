import 'package:flutter/services.dart';

/// Handles all the storage
// ignore: lines_longer_than_80_chars
// ignore_for_file: type_annotate_public_apis, always_declare_return_types, inference_failure_on_function_return_type

abstract class StorageInterface {
  /// Settings Hive storage box.
  static get settingsStorage {
    throw UnimplementedError();
  }

  /// Memos Hive storage box.
  static get memosStorage {
    throw UnimplementedError();
  }

  /// User Hive storage box.
  static get userStorage {
    throw UnimplementedError();
  }

  /// Stream of the settings value.
  static get settingsStorageStream {
    throw UnimplementedError();
  }

  /// Stream of the memo values notifying only on change to the memo [title].
  static singleMemoStorageStream(
    String title,
  ) {
    throw UnimplementedError();
  }

  /// Stream of the memos values.
  static get memosStorageStream {
    throw UnimplementedError();
  }

  /// Stream of the user value.
  static get userStorageStream {
    throw UnimplementedError();
  }

  /// Stream of the settings for the memo [title]
  ///
  /// [setting] allows to listen to a specific setting only
  static memoSettingsStorageStream(
    String title, {
    String? setting,
  }) {
    throw UnimplementedError();
  }

  /// Initializes Hive and all the boxes.
  static initStorage({ByteData? existingStore}) async {
    throw UnimplementedError();
  }

  /// Returns the settings object or a new object if it is not set.
  static getSettings() {
    throw UnimplementedError();
  }

  /// Stores the value of [settings] in [settingsStorage].
  static setSettings(dynamic settings) {
    throw UnimplementedError();
  }

  /// Returns the entire memos map.
  static getMemos() {
    throw UnimplementedError();
  }

  /// Returns a specific memo
  static getMemo({required dynamic memo}) {
    throw UnimplementedError();
  }

  /// Stores [obj] as [memo] in [memosStorage]
  static void setMemo({
    required dynamic memo,
    dynamic obj,
  }) {
    throw UnimplementedError();
  }

  /// Removes [memo] from the cache
  static void removeMemo({required dynamic memo}) {
    throw UnimplementedError();
  }

  /// Returns the settings object for [memo] or a new object if it is not set.
  static getMemoSettings(String memo, {String? setting}) {
    throw UnimplementedError();
  }

  /// Stores [memo] settings
  static void setMemoSettings({
    required dynamic memo,
    Map<String, dynamic>? settings,
  }) {
    throw UnimplementedError();
  }

  /// Returns the user object or ```null``` if not set.
  static getUser() {
    throw UnimplementedError();
  }

  /// Stores the value of [user] in [userStorage].
  static void setUser(dynamic user) {
    throw UnimplementedError();
  }

  /// Deletes the stored user value of [userStorage].
  static void removeUser() {
    throw UnimplementedError();
  }

  /// Deletes all the locally stored memos.
  static void removeAllMemos() {
    throw UnimplementedError();
  }

  /// Deletes all the locally stored settings.
  static void removeAllSettings() {
    throw UnimplementedError();
  }
}
