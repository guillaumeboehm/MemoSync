import 'dart:async';
import 'dart:ui';

import 'package:enum_flag/enum_flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:memosync/src/services/background_handlers/common_handlers/job_handlers.dart';
import 'package:memosync/src/services/logger.dart';
import 'package:memosync/src/services/notification_service.dart';
import 'package:memosync/src/services/storage/storage.dart';
import 'package:memosync/src/utilities/sentry_wrappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:workmanager/workmanager.dart';

enum _WMJobType with EnumFlag {
  backendFetch,
  // wallpaper,
}

/// Initializes the smartphone background service
Future<void> initBackgroundService() async {
  if (UniversalPlatform.isDesktopOrWeb) return;

  // TODO(me): Move the notif init somewhere that makes more sense
  await NotificationService.initNotifications();

  // Init Background service
  FlutterBackgroundService().invoke('stopService');

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

  // FlutterBackgroundService().on('allSet').listen((event) {
  //   service.invoke('openStore', {
  //     'store': Storage.store.reference.buffer.asInt64List(),
  //   });
  // });

  unawaited(service.startService());

  // Init workmanager
  await Workmanager().initialize(
    _workManagerCallbackDispatcher,
    //isInDebugMode: true,
  );
  await Workmanager().cancelAll();
  await Workmanager().registerPeriodicTask(
    'memosync_backend_fetch',
    'backendFetch',
    tag: [_WMJobType.backendFetch].flag.toString(),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
bool _onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) print('FLUTTER BACKGROUND FETCH');

  return true;
}

// Called on every service start
Future<void> _onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  var storeInitialized = false;

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // service.on('openStore').listen((event) async {
  await Storage.initStorage(
      // existingStore: Int64List.fromList(
      //   (event?['store'] as List).map((e) => e as int).toList(),
      // ).buffer.asByteData(),
      );
  storeInitialized = true;
  // });

  // If it takes too much time assume it was auto started
  // Future.delayed(
  //   const Duration(seconds: 2),
  //   () async {
  //     if (!storeInitialized) {
  //       await Storage.initStorage();
  //       storeInitialized = true;
  //     }
  //     // There should always be a store ref at this point
  //     // so save it for the workmanager jobs
  //     await SharedPreferences.getInstance().then((sharedPrefs) {
  //       sharedPrefs.setStringList(
  //         'storeRef',
  //         Storage.store.reference.buffer
  //             .asInt64List()
  //             .map((e) => e.toString())
  //             .toList(),
  //       );
  //     });
  //   },
  // );

  // service.invoke('allSet');

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (storeInitialized) {
      await permanentJobHandler(timer.tick);
    }
  });
}

// Called by all the workmanager jobs
void _workManagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Wait for some time for first app launch
      await SharedPreferences.getInstance().then((prefs) async {
        await Future.delayed(
          Duration(
            seconds: prefs.getString('lifeCycleState') == null ? 10 : 1,
          ),
          () {},
        );
      });

      if (!await Storage.initStorage()) return Future.value(false); // retry
      await periodicJobHandler(task);
    } catch (err, st) {
      unawaited(
        Logger.error(
          err.toString(),
        ),
      );
      // try {
      //   Storage.store.close();
      // } catch (e, st2) {
      //   unawaited(Logger.error('Could not close store ${e.toString()}'));
      //   await sentryCaptureException(e, st2);
      // }
      await sentryCaptureException(err, st);
      return Future.value(false); // retry
    }
    return Future.value(true);
  });
}
