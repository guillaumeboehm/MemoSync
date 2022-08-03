import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_memosync/src/home/repositories/memo.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/memo.dart';
import 'package:flutter_memosync/src/services/notification_service.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recurrentNotifMaxDelay = 5; // don't notify anymore after more than 5 min

/// Function that handles all recurrent (>15min) tasks
///
/// Assume the Storage opened when this function is called
Future<void> periodicJobHandler(String taskName) async {
  if (Storage.getUser() == null ||
      !Storage.getSettings().bgSync ||
      (Storage.getSettings().bgSyncWifiOnly &&
          (await Connectivity().checkConnectivity()) ==
              ConnectivityResult.mobile)) return;

  final sharedPreferences = await SharedPreferences.getInstance();
  switch (taskName) {
    case 'backendFetch':
      await MemoRepository().getAllMemos(Storage.getUser()!.accessToken);
      break;
    case 'autoSave':
      if (Storage.getSettings().autoSave) {
        try {
          if (sharedPreferences.getString('lastAutoSave') != null &&
              DateTime.now()
                      .difference(
                        DateTime.parse(
                          sharedPreferences.getString('lastAutoSave')!,
                        ),
                      )
                      .inSeconds >
                  Storage.getSettings().autoSaveInterval) {
            //TODO(me): Implement autosave
          }
        } catch (e) {
          unawaited(Logger.error('$e'));
        }
      }
      break;
    default:
      unawaited(Logger.notify('WorkManager task unknown : $taskName'));
  }
}

/// Function that handles the permanent service (called every 1sec)
///
/// Assume the Storage opened when this function is called

Future<void> permanentJobHandler(int tick) async {
  if (Storage.getUser() == null) return;

  var memoId = 0;
  for (final memo in Storage.getMemos().values) {
    if ((memo.settings['notifications_on'] as bool? ?? false) &&
        (memo.settings['notifications'] as List? ?? []).isNotEmpty) {
      var notifId = 0;
      for (final notif in memo.settings['notifications'] as List) {
        notif as Map<String, dynamic>;
        final sharedPreferences = await SharedPreferences.getInstance();

        final lastNotif = DateTime.tryParse(
          sharedPreferences.getString(
                '${memo.title}_lastNotif_$notifId',
              ) ??
              '',
        )?.toLocal();
        var notified = false;
        final now = DateTime.now();
        switch (notif['repeatEvery'] as NotificationRepeatEvery) {
          case NotificationRepeatEvery.day:
            // Break if the [repeatEveryCount] days interval is not reached
            if (lastNotif != null &&
                now.difference(lastNotif).inDays >
                    (notif['repeatEveryCount'] as int)) break;

            final diff =
                Duration(hours: now.hour, minutes: now.minute).inMinutes -
                    Duration(
                      hours: notif['repeatEveryHour'] as int,
                      minutes: notif['repeatEveryMinute'] as int,
                    ).inMinutes;
            if (diff > 0 && diff < _recurrentNotifMaxDelay) {
              unawaited(
                NotificationService.pushNotification(
                  memoId,
                  memo.title,
                  body: memo.text,
                ),
              );
              notified = true;
            }
            break;
          case NotificationRepeatEvery.week:
            // Break if the [repeatEveryCount] weeks interval is not reached
            if (lastNotif != null &&
                now.difference(lastNotif).inDays >
                    (notif['repeatEveryCount'] as int) * 7) break;

            if (!(notif['repeatOnDays'] as Map).containsKey(now.weekday)) break;

            final diff =
                Duration(hours: now.hour, minutes: now.minute).inMinutes -
                    Duration(
                      hours: notif['repeatEveryHour'] as int,
                      minutes: notif['repeatEveryMinute'] as int,
                    ).inMinutes;
            if (diff > 0 && diff < _recurrentNotifMaxDelay) {
              unawaited(
                NotificationService.pushNotification(
                  memoId,
                  memo.title,
                  body: memo.text,
                ),
              );
              notified = true;
            }
            break;
          case NotificationRepeatEvery.month:
            // Break if the [repeatEveryCount] month interval is not reached
            if (lastNotif != null &&
                now.month - lastNotif.month >
                    (notif['repeatEveryCount'] as int)) break;
            if (now.day != (notif['repeatOnDate'] as DateTime).day) break;

            final diff =
                Duration(hours: now.hour, minutes: now.minute).inMinutes -
                    Duration(
                      hours: notif['repeatEveryHour'] as int,
                      minutes: notif['repeatEveryMinute'] as int,
                    ).inMinutes;
            if (diff > 0 && diff < _recurrentNotifMaxDelay) {
              unawaited(
                NotificationService.pushNotification(
                  memoId,
                  memo.title,
                  body: memo.text,
                ),
              );
              notified = true;
            }
            break;
          case NotificationRepeatEvery.year:
            // Break if the [repeatEveryCount] years interval is not reached
            if (lastNotif != null &&
                now.year - lastNotif.year >
                    (notif['repeatEveryCount'] as int)) {
              break;
            }
            if (now.day != (notif['repeatOnDate'] as DateTime).day ||
                now.month != (notif['repeatOnDate'] as DateTime).month) break;

            final diff =
                Duration(hours: now.hour, minutes: now.minute).inMinutes -
                    Duration(
                      hours: notif['repeatEveryHour'] as int,
                      minutes: notif['repeatEveryMinute'] as int,
                    ).inMinutes;
            if (diff > 0 && diff < _recurrentNotifMaxDelay) {
              unawaited(
                NotificationService.pushNotification(
                  memoId,
                  memo.title,
                  body: memo.text,
                ),
              );
              notified = true;
            }
            break;
          case NotificationRepeatEvery.period:
            if ((notif['ignoreOnDays'] as Map)[(notif['ignoreOnDays'] as Map)
                .keys
                .toList()[now.weekday]] as bool) break;

            if (lastNotif == null ||
                (now.difference(lastNotif).inSeconds) >=
                    Duration(
                      hours: notif['repeatEveryHour'] as int,
                      minutes: notif['repeatEveryMinute'] as int,
                      seconds: notif['repeatEverySecond'] as int,
                    ).inSeconds) {
              unawaited(
                NotificationService.pushNotification(
                  memoId,
                  memo.title,
                  body: memo.text,
                ),
              );
              notified = true;
            }
            break;
          case NotificationRepeatEvery.unknown:
            break;
        }
        // Once notified register the notification time
        if (notified) {
          await sharedPreferences.setString(
            '${memo.title}_lastNotif_$notifId',
            DateTime.now().toUtc().toIso8601String(),
          );
        }
        notifId++;
      }
    }
    memoId++;
  }
}
