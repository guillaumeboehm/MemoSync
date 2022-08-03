import 'package:flutter/material.dart';
import 'package:flutter_memosync/app.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart'
    show AuthenticationRepository;
import 'package:flutter_memosync/src/home/repositories/memo.dart'
    show MemoRepository;
import 'package:flutter_memosync/src/services/background_handlers/desktop_background_manager.dart';
import 'package:flutter_memosync/src/services/background_handlers/desktop_window_manager.dart';
import 'package:flutter_memosync/src/services/background_handlers/smartphones_background_manager.dart';
import 'package:flutter_memosync/src/services/repositories/user.dart'
    show UserRepository;
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/services/storage/translate_preferences.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Storage.initStorage();
  await initBackgroundService();
  await DesktopWindowManager.init();
  await DesktopBackroungManager.initBackgroundService();

  runApp(
    LocalizedApp(
      await LocalizationDelegate.create(
        fallbackLocale: 'en_US',
        supportedLocales: ['en_US', 'fr_FR'],
        preferences: TranslatePreferences(),
      ),
      App(
        authenticationRepository: AuthenticationRepository(),
        userRepository: UserRepository(),
        memoRepository: MemoRepository(),
      ),
    ),
  );
}
