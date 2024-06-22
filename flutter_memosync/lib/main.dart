import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
import 'package:flutter_memosync/src/utilities/sentry_wrappers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_strategy/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(); //.env
  // await dotenv.load(fileName: '.env-secret');
  await EasyLocalization.ensureInitialized();
  setPathUrlStrategy();
  if (!await Storage.initStorage()) {
    await sentryCaptureMessage("Couldn't open main storage");
    throw Exception("Couldn't open main storage");
  }
  await initBackgroundService();
  await DesktopWindowManager.init();
  await DesktopBackroungManager.initBackgroundService();

  Future<void> appRunner() async => runApp(
        DefaultAssetBundle(
          bundle: SentryAssetBundle(),
          child: EasyLocalization(
            supportedLocales: const [
              Locale('en'),
              Locale('fr'),
            ],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            useFallbackTranslations: true,
            useOnlyLangCode: true,
            child: App(
              authenticationRepository: AuthenticationRepository(),
              userRepository: UserRepository(),
              memoRepository: MemoRepository(),
            ),
          ),
        ),
      );

  await SentryFlutter.init(
    (options) => options
      ..dsn = dotenv.get('SENTRY_URI')
      ..environment = kDebugMode ? 'dev' : 'prod',
    appRunner: appRunner,
  );
}
