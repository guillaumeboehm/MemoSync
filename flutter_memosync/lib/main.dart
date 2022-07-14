import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_memosync/app.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart'
    show AuthenticationRepository;
import 'package:flutter_memosync/src/home/repositories/memo.dart'
    show MemoRepository;
import 'package:flutter_memosync/src/services/desktop_window_manager.dart';
import 'package:flutter_memosync/src/services/repositories/user.dart'
    show UserRepository;
import 'package:flutter_memosync/src/services/smartphones_background_manager.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:quick_notify/quick_notify.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Storage.initStorage();

  await DesktopWindowManager.init();
  await initBackgroundService();

  // final mainPort = ReceivePort();
  // await Isolate.spawn(
  //   (SendPort parentPort) async {
  //     final bgReceivePort = ReceivePort();

  //     // Send where you'll receive first
  //     parentPort.send(bgReceivePort.sendPort);

  //     // Listen for received stuff
  //     await for (final message in bgReceivePort) {
  //       if (message is List) {
  //         final msg = message[0];
  //         final coffeeType = message[1];
  //         log(msg.toString());

  //         parentPort.send('taking $coffeeType');
  //       }
  //     }
  //     log('BG IS DONE');
  //   },
  //   mainPort.sendPort,
  // );
  // final mainBroadcast = mainPort.asBroadcastStream();
  // final bgPort = await mainBroadcast.first as SendPort;
  // mainBroadcast.listen((message) {
  //   log('Message into mainPort : $message');
  // });
  // bgPort.send(['Some message', 'Espresso']);

  // QuickNotify.notify(title: 'Launched', content: 'App launched');
  runApp(
    App(
      authenticationRepository: AuthenticationRepository(),
      userRepository: UserRepository(),
      memoRepository: MemoRepository(),
    ),
  );
}
