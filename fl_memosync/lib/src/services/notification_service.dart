import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memosync/src/services/logger.dart';
import 'package:memosync/src/services/storage/storage.dart';
import 'package:quick_notify/quick_notify.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

/// Static class to handle notifications
class NotificationService {
  static const _permanentNotifID = 2121;
  static const _notificationMaxLength = 200;

  /// Initializes [FlutterLocalNotificationsPlugin] if on smartphone
  static Future<bool> initNotifications() async {
    try {
      if (!UniversalPlatform.isDesktopOrWeb) {
        final ret = await FlutterLocalNotificationsPlugin().initialize(
              const InitializationSettings(
                android: AndroidInitializationSettings(
                  'ic_quick_notify',
                ),
                iOS: DarwinInitializationSettings(),
              ),
            ) ??
            false;
        return ret;
      }
      return true;
    } catch (e) {
      unawaited(Logger.error(e.toString()));
      return false;
    }
  }

  /// Used for systems that require permission to display notifications
  static Future<bool> requestPermission() async {
    try {
      if (!UniversalPlatform.isAndroid) return true;
      final localNotif = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (localNotif == null) return false;
      if (await localNotif.areNotificationsEnabled() ?? false) return true;
      if (await localNotif.requestNotificationsPermission() ?? false) {
        return true;
      }

      await Logger.info('PERM: ${await localNotif.areNotificationsEnabled()}');
    } catch (e) {
      unawaited(Logger.error(e.toString()));
    }
    return false;
  }

  /// Pushes a standard notification
  static Future<bool> pushNotification(
    int id,
    String title, {
    String? body,
  }) async {
    if (!Storage.getSettings().notificationsEnabled) return false;
    final bodyTxt = _ensureTextSize(body);
    final titleTxt = _ensureTextSize(title);

    if (UniversalPlatform.isDesktopOrWeb) {
      //QuickNotify
      await QuickNotify.hasPermission().then((canNotify) {
        if (!canNotify) return;
        QuickNotify.notify(title: titleTxt ?? '', content: bodyTxt);
      });
    } else {
      //LocalNotif
      await FlutterLocalNotificationsPlugin().show(
        id,
        titleTxt,
        bodyTxt,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'standardNotifications',
            'Standard notifications',
            groupKey: 'com.android.memosync.STANDARD_NOTIF',
            channelDescription:
                'Notification channel for standard notifications',
            priority: Priority.high,
            additionalFlags: Int32List.fromList([256]), //LOCAL_ONLY
          ),
        ),
      );
    }
    return true;
  }

  /// Pushes or Modifies the permanent notification on mobiles
  static Future<bool> setPermanentNotification(
    String title, {
    required int memoVersion,
    required String memoTitle,
    String? body,
  }) async {
    if (UniversalPlatform.isDesktopOrWeb) return false;
    try {
      final titleTxt = _ensureTextSize(title);
      final bodyTxt = _ensureTextSize(body);

      if (Storage.getSettings().notificationsEnabled) {
        await FlutterLocalNotificationsPlugin().show(
          _permanentNotifID,
          titleTxt,
          bodyTxt,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'persistantNotifications',
              'Persistant notifications',
              groupKey: 'com.android.memosync.PERSISTENT_NOTIF',
              channelDescription:
                  'Notification channel for persistant notifications',
              priority: Priority.min,
              importance: Importance.min,
              category: AndroidNotificationCategory.system,
              channelShowBadge: false,
              enableVibration: false,
              ongoing: true,
              playSound: false,
              autoCancel: false,
              onlyAlertOnce: true,
              additionalFlags:
                  Int32List.fromList([32, 256]), //NO_CLEAR/LOCAL_ONLY
            ),
            iOS: const DarwinNotificationDetails(
              threadIdentifier: 'memosync.PERSISTENT_NOTIF',
            ),
          ),
        );
      }
      unawaited(
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString(
            'currentPermanentMemo',
            '$memoTitle-$memoVersion',
          ),
        ),
      );
      return true;
    } catch (e) {
      unawaited(Logger.error(e.toString()));
      return false;
    }
  }

  /// Enable notifications from old state
  static void setPermanentNotificationFromOldState() {
    SharedPreferences.getInstance().then(
      (prefs) {
        try {
          final memo = Storage.getMemo(
            memo: prefs
                    .getString(
                      'currentPermanentMemo',
                    )
                    ?.split('-')[0] ??
                '',
          );
          if (memo != null) {
            setPermanentNotification(
              memoVersion: memo.version,
              memoTitle: memo.title,
              memo.text,
            );
          }
        } catch (e) {
          unawaited(Logger.error('$e'));
        }
      },
    );
  }

  /// Removes the permanent notification on mobiles
  static bool unsetPermanentNotification() {
    if (UniversalPlatform.isDesktopOrWeb) return false;
    try {
      FlutterLocalNotificationsPlugin().cancel(_permanentNotifID);
      unawaited(
        SharedPreferences.getInstance().then(
          (prefs) => prefs.remove(
            'currentPermanentMemo',
          ),
        ),
      );
      return true;
    } catch (e) {
      unawaited(Logger.error(e.toString()));
      return false;
    }
  }

  /// Disables the permanent notifications without loosing the state
  static void disablePermanentNotification() {
    FlutterLocalNotificationsPlugin().cancel(_permanentNotifID);
  }

  /// Removes all notifications from memosync
  static bool clearAllNotifications() {
    try {
      if (!UniversalPlatform.isDesktopOrWeb) {
        FlutterLocalNotificationsPlugin().cancelAll();
        unawaited(
          SharedPreferences.getInstance().then(
            (prefs) => prefs.remove(
              'currentPermanentMemo',
            ),
          ),
        );
      }
      return true;
    } catch (e) {
      unawaited(Logger.error(e.toString()));
      return false;
    }
  }

  static String? _ensureTextSize(String? text) {
    if (text == null) return null;

    String ret;
    if (text.length > _notificationMaxLength) {
      ret = text.substring(
        0,
        _notificationMaxLength,
      );
    } else {
      ret = text;
    }
    return ret;
  }
}
