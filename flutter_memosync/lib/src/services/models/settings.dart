import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:objectbox/objectbox.dart';

part 'settings.g.dart';

// Last field 9
/// [HiveObject] used to store all the global settings.
// @Entity()
@HiveType(typeId: 0)
class SettingsObject extends HiveObject {
  /// Default constructor.
  SettingsObject();

  /// ObjectBox id
  int id = 0;

  //########################## General

  /// Are global app notifications.
  @HiveField(4)
  bool notificationsEnabled = false;

  /// Locale for the app.
  @HiveField(1)
  String? locale;

  /// Launch the app on startup
  @HiveField(7)
  bool onStartup = false;

  /// Launch the app minimized
  @HiveField(8)
  bool launchMinimized = true;

  /// Minimize to tray when closed
  @HiveField(9)
  bool closeMinimized = true;

  //########################## Appearance

  /// Is the application using dark color mode.
  @HiveField(0)
  bool darkMode = true;

  //########################## Auto save

  /// Is memo autosave enabled
  @HiveField(2)
  bool autoSave = false;

  /// Interval between autosaves in seconds
  @HiveField(3)
  int autoSaveInterval = 120;

  //########################## Background sync

  /// Enable background sync
  @HiveField(5)
  bool bgSync = true;

  /// Enable background sync on wifi only
  @HiveField(6)
  bool bgSyncWifiOnly = false;

  //########################## Privacy

  /// Opt-in analytics option
  @HiveField(10)
  bool analytics = false;
}
