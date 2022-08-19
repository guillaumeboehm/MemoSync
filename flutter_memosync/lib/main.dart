import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memosync/app.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart'
    show AuthenticationRepository;
import 'package:flutter_memosync/src/home/repositories/memo.dart'
    show MemoRepository;
import 'package:flutter_memosync/src/services/background_handlers/desktop_background_manager.dart';
import 'package:flutter_memosync/src/services/background_handlers/desktop_window_manager.dart';
import 'package:flutter_memosync/src/services/background_handlers/smartphones_background_manager.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/repositories/user.dart'
    show UserRepository;
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/services/storage/translate_preferences.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:quick_notify/quick_notify.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await Storage.initStorage();
  await initBackgroundService();
  await DesktopWindowManager.init();
  await DesktopBackroungManager.initBackgroundService();
  // Logger.info('permission: ${(await QuickNotify.hasPermission()).toString()}');
  //TODO issue with quickNotify permissions and backgroundService notif permissions
  await SentryFlutter.init(
    (options) => options
      ..dsn = 'https://examplePublicKey@o0.ingest.sentry.io/0'
      ..environment = kDebugMode ? 'dev' : 'prod',
    appRunner: () async => runApp(
      DefaultAssetBundle(
        bundle: SentryAssetBundle(enableStructuredDataTracing: true),
        child: LocalizedApp(
          await LocalizationDelegate.create(
            fallbackLocale: 'en',
            supportedLocales: ['en', 'fr'],
            preferences: TranslatePreferences(),
            useFallbackForMissingStrings: true,
            interpolateEmptyAsEmtpyString: true,
          ),
          App(
            authenticationRepository: AuthenticationRepository(),
            userRepository: UserRepository(),
            memoRepository: MemoRepository(),
          ),
        ),
      ),
    ),
  );
}
