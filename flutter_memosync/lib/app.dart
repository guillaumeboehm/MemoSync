import 'package:disable_battery_optimization/disable_battery_optimization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/home/home.dart';
import 'package:flutter_memosync/src/home/repositories/memo.dart';
import 'package:flutter_memosync/src/login/views/login_page.dart';
import 'package:flutter_memosync/src/services/background_handlers/desktop_window_manager.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/settings.dart';
import 'package:flutter_memosync/src/services/repositories/user.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/splash/splash.dart';
import 'package:flutter_memosync/src/widgets/route_404.dart';
import 'package:flutter_translate/flutter_translate.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_platform/universal_platform.dart';

/// Widget providing the [MaterialApp], listening for changes on the
/// [AuthenticationBloc] for routing.
class AppView extends StatefulWidget {
  /// Default constructor
  const AppView({super.key});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  NavigatorState get _navigator => _navigatorKey.currentState!;

  bool startup = true;
  SharedPreferences? _sharedPreferences;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      _sharedPreferences = await SharedPreferences.getInstance();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    App.lifeCycleState = state;
    _sharedPreferences?.setString('lifeCycleState', state.name);
  }

  @override
  Widget build(BuildContext context) {
    final localizationDelegate = LocalizedApp.of(context).delegate;

    return ValueListenableBuilder<SettingsObject>(
      valueListenable: Storage.settingsStorageStream(),
      builder: (context, settings, _) {
        return MaterialApp(
          navigatorObservers: [
            SentryNavigatorObserver(),
          ],
          theme: App.lightTheme,
          darkTheme: App.darkTheme,
          themeMode: (settings.darkMode) ? ThemeMode.dark : ThemeMode.light,
          navigatorKey: _navigatorKey,
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            localizationDelegate,
          ],
          supportedLocales: localizationDelegate.supportedLocales,
          locale: localizationDelegate.currentLocale,
          builder: (context, child) {
            Future(() async {
              if (!UniversalPlatform.isDesktopOrWeb &&
                  !(await DisableBatteryOptimization
                          .isAllBatteryOptimizationDisabled ??
                      false)) {
//                 await DisableBatteryOptimization
//                     .showDisableAllOptimizationsSettings(
//                   'Enable Auto Start',
//                   'Follow the steps and enable the auto start of this app',
//                   'Your device has additional battery optimization',
//                   '''
// Follow the steps and disable the optimizations to allow smooth functioning of this app''',
                // );
              }
            });

            Logger.info('built');
            return BlocListener<AuthenticationBloc, AuthenticationState>(
              listenWhen: (previous, current) =>
                  current.status == AuthenticationStatus.unknown ||
                  previous.status != current.status,
              listener: (context, state) {
                if (!kIsWeb || Uri.base.path == '/') {
                  // Not ideal but meh
                  Logger.info(
                    'BlocListener rebuild with auth status: ${state.status}',
                  );
                  switch (state.status) {
                    case AuthenticationStatus.authenticated:
                      // NotificationService.initNotifications();
                      _navigator.pushAndRemoveUntil<void>(
                        HomePage.route(),
                        (route) => false,
                      );
                      break;
                    case AuthenticationStatus.unauthenticated:
                      _navigator.pushAndRemoveUntil<void>(
                        LoginPage.route(),
                        (route) => false,
                      );
                      break;
                    case AuthenticationStatus.unknown:
                      _navigator.pushAndRemoveUntil<void>(
                        LoginPage.route(),
                        (route) => false,
                      );
                      break;
                  }
                } else {
                  if (state.status == AuthenticationStatus.authenticated) {
                    _navigator.pushAndRemoveUntil<void>(
                      HomePage.route(),
                      (route) => false,
                    );
                  }
                  switch (Uri.base.path) {
                    case '/verifEmail':
                    case '/changePassword':
                      if (startup) {
                        _navigator.pushAndRemoveUntil<void>(
                          LoginPage.route(
                            args: {
                              'route': Uri.base.path,
                              ...Uri.base.queryParameters
                            },
                          ),
                          (route) => false,
                        );
                        startup = false;
                      }
                      break;
                    default:
                      _navigator.pushAndRemoveUntil<void>(
                        route404,
                        (route) => false,
                      );
                      break;
                  }
                }
              },
              child: child,
            );
          },
          // home: const SplashPage(),
          onGenerateRoute: (RouteSettings settings) => SplashPage.route(),
        );
      },
    );
  }
}

/// Top Level [StatelessWidget]
///
/// Must be instanciated with an [AuthenticationRepository]
/// and a [UserRepository]
class App extends StatelessWidget {
  /// Default constructor requiring both repositories
  const App({
    super.key,
    required this.authenticationRepository,
    required this.userRepository,
    required this.memoRepository,
  });

  /// Repository used to handle authentication calls
  final AuthenticationRepository authenticationRepository;

  /// Repository used to handle user changes
  final UserRepository userRepository;

  /// Repository used to handle user changes
  final MemoRepository memoRepository;

  /// Max width for small screen display.
  static const double maxWidth = 1000;

  /// Used for Logger.graphic
  static BuildContext? context;

  /// Used to access life cycle state from anywhere in the app
  static AppLifecycleState? lifeCycleState;

  /// Light theme used in the app
  static final lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color.fromRGBO(14, 65, 98, 1),
      secondary: Color.fromARGB(255, 119, 66, 12),
      tertiary: Color.fromRGBO(199, 199, 199, 1),
    ),
  );

  /// Dark theme used in the app
  static final darkTheme = ThemeData(
    colorScheme: const ColorScheme.dark(
      primary: Color.fromRGBO(105, 182, 234, 1),
      secondary: Color.fromRGBO(244, 175, 107, 1),
      tertiary: Color.fromRGBO(199, 199, 199, 1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    App.context = context;
    Logger.info('Launching App');
    return DesktopWindowManager.windowWrapper(
      child: LocalizationProvider(
        state: LocalizationProvider.of(context).state,
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider.value(
              value: authenticationRepository,
            ),
            RepositoryProvider.value(
              value: memoRepository,
            ),
          ],
          child: BlocProvider(
            create: (_) => AuthenticationBloc(
              authenticationRepository: authenticationRepository,
              userRepository: userRepository,
            ),
            child: const AppView(),
          ),
        ),
      ),
    );
  }
}
