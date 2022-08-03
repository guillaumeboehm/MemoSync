import 'dart:async';

import 'package:flutter_memosync/src/services/background_handlers/common_handlers/job_handlers.dart';
import 'package:flutter_memosync/src/services/notification_service.dart';
import 'package:universal_platform/universal_platform.dart';

/// Static class mimicing the smartphone background services for desktop and web
class DesktopBackroungManager {
  /// Initializes the background service
  static Future<void> initBackgroundService() async {
    if (!UniversalPlatform.isDesktopOrWeb) return;

    await NotificationService.initNotifications();
    // Lunching the isolate and setting up communication
    Timer.periodic(const Duration(seconds: 1), (timer) {
      // Mimics the background service for notifications
      permanentJobHandler(timer.tick);
    });

    // Mimics the WMJob every 15 mins
    Timer.periodic(
      const Duration(minutes: 15),
      (timer) => periodicJobHandler('backendFetch'),
    );
  }
}
