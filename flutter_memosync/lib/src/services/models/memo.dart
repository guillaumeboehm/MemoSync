import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:objectbox/objectbox.dart';

part 'memo.g.dart';

/// Defines the notification type in memo settings.
@HiveType(typeId: 4)
enum NotificationTypes {
  /// Fixed date and time notification
  @HiveField(2)
  fixedTime,

  /// Recurrent period notification
  @HiveField(3)
  timePeriod,

  @HiveField(4)
  unknown,
}

void ensureNotificationTypesValues() {
  assert(NotificationTypes.fixedTime.index == 0, 'fixedTime must be 0');
  assert(NotificationTypes.timePeriod.index == 1, 'fixedTime must be 1');
  assert(NotificationTypes.unknown.index == 2, 'fixedTime must be 2');
}

/// Defines how the notification repeats in memo settings.
@HiveType(typeId: 5)
enum NotificationRepeatEvery {
  /// Repeat every day
  @HiveField(0)
  day,

  /// Repeat every week
  @HiveField(1)
  week,

  /// Repeat every month
  @HiveField(2)
  month,

  /// Repeat every year
  @HiveField(3)
  year,

  /// Repeat every time period (e.g. every 10min)
  @HiveField(4)
  period,

  @HiveField(6)
  unknown,
}

void ensureNotificationRepeatEveryValues() {
  assert(NotificationRepeatEvery.day.index == 0, 'day must be 0');
  assert(NotificationRepeatEvery.week.index == 1, 'week must be 1');
  assert(NotificationRepeatEvery.month.index == 2, 'month must be 2');
  assert(NotificationRepeatEvery.year.index == 3, 'year must be 3');
  assert(NotificationRepeatEvery.period.index == 4, 'day must be 4');
  assert(NotificationRepeatEvery.unknown.index == 5, 'day must be 5');
}

/// [HiveObject] used to cache the memos.
@Entity()
@HiveType(typeId: 3)
class MemoObject extends HiveObject {
  /// Default constructor.
  MemoObject();

  /// The ObjectBox id
  int id = 0;

  /// Memo title.
  @Unique()
  @HiveField(0)
  String title = '';

  /// Memo content.
  @HiveField(1)
  String text = '';

  /// Memo content.
  @HiveField(5)
  String lastSynchedText = '';

  /// Memo version.
  @HiveField(2)
  int version = 0;

  /// Last local memo modifications.
  @HiveField(4)
  String patches = '';

  /// Memo settings map with <MemoId, Settings>
  @HiveField(7)
  Map<String, dynamic> settings = <String, dynamic>{};

  /// ObjectBox converter for settings
  String? get dbSettings {
    return jsonEncode(settings);
  }

  /// ObjectBox converter for settings
  set dbSettings(String? value) {
    settings = jsonDecode(value ?? '') as Map<String, dynamic>;
  }
}
