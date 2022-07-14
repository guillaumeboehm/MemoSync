import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_memosync/objectbox.g.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:hive/hive.dart';
import 'package:quick_notify/quick_notify.dart';
import 'package:universal_platform/universal_platform.dart';

/// Initializes the smartphone background service
Future<void> initBackgroundService() async {
  if (UniversalPlatform.isDesktopOrWeb) return;

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onStart,
      isForegroundMode: false,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: _onStart,
      onBackground: _onIosBackground,
    ),
  );

  FlutterBackgroundService().on('update').listen((event) {
    log('UPDATE $event');
  });

  unawaited(service.startService());
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
bool _onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) print('FLUTTER BACKGROUND FETCH');

  return true;
}

Future<void> _onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();
  Store? store;
  // await Storage.initStorage();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  service.on('openStore').listen((event) {
    Storage.initStorage(existingStore: event?['store'] as ByteData);
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (store != null && timer.tick % 5 == 0) {
      QuickNotify.notify(
        title: """
Notifs: ${Storage.getSettings().notificationsEnabled ? 'enabled' : 'disabled'}""",
        content: 'Yep ${timer.tick} ${DateTime.now().toIso8601String()}',
      );
    }
  });
}
