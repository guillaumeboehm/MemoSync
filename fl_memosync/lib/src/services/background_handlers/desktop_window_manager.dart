import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:launch_at_startup/launch_at_startup.dart'
    if (dart.library.html) 'package:memosync/src/services/background_handlers/noop_launch_at_startup.dart';
import 'package:memosync/src/services/storage/storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:universal_io/io.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

/// Handles desktop application actions
class DesktopWindowManager {
  /// Wraps the MaterialApp to handle window events
  static Widget windowWrapper({
    required Widget child,
  }) {
    return UniversalPlatform.isDesktop
        ? _Wrapper(
            child: child,
          )
        : child;
  }

  /// Initialization function
  static Future<void> init() async {
    if (!UniversalPlatform.isDesktop) {
      if (kDebugMode) print('Stubbing WM');
      return;
    }

    // ### Launch at startup stuff
    final packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );

    // ### Window Manager stuff
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      title: 'MemoSync',
    );

    // ### Show window if not launch minimized or just make tray icon
    if (Storage.getSettings().closeMinimized &&
        Storage.getSettings().launchMinimized) {
      await _makeSysTray();
    } else {
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  static Future<void> _makeSysTray() async {
    final path = UniversalPlatform.isWindows
        ? 'assets/resources/logos/ico/Full_logo_32px.ico'
        : 'assets/resources/logos/png/Full_logo_32px.png';

    // We first init the systray menu
    await trayManager.setIcon(path);
    await trayManager.setTitle('MemoSync');

    // create context menu
    final menu = Menu(
      items: [
        MenuItem(
          key: 'open',
          label: 'Open',
          onClick: (menuItem) => _openFromTray(),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'Exit',
          onClick: (menuItem) {
            windowManager.destroy();
          },
        ),
      ],
    );

    // set context menu
    await trayManager.setContextMenu(menu);
  }

  static Future<void> _deleteSysTray() async {
    await trayManager.destroy();
  }

  /// Set whether to minimize to system tray on close
  static Future<bool> minimizeOnClose({required bool enabled}) async {
    if (!UniversalPlatform.isDesktop) return false;

    try {
      await windowManager.setPreventClose(enabled);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _minimizeToTray() async {
    try {
      await _makeSysTray();
      await windowManager.hide();
    } catch (_) {
      await windowManager.destroy();
    }
  }

  static Future<void> _openFromTray() async {
    try {
      await _deleteSysTray();
    } catch (_) {}
    await windowManager.show();
  }

  /// Forces the window to close without going to system tray
  static Future<void> forceExit() async {
    await windowManager.destroy();
  }

  /// Set whether to launch the application on startup
  static Future<bool> launchOnStartup({required bool enabled}) async {
    if (!UniversalPlatform.isDesktop) return false;

    try {
      if (enabled) {
        await launchAtStartup.enable();
      } else {
        await launchAtStartup.disable();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// True if the application is set to launch on startup
  static Future<bool> isLaunchingOnStartup() async {
    return UniversalPlatform.isDesktop
        ? launchAtStartup.isEnabled()
        : Future(() => false);
  }
}

class _Wrapper extends StatefulWidget {
  const _Wrapper({
    required this.child,
  });

  final Widget child;

  @override
  State<_Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<_Wrapper> with WindowListener, TrayListener {
  @override
  void initState() {
    windowManager.addListener(this);
    trayManager.addListener(this);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }

  Future<void> _init() async {
    await windowManager.setPreventClose(Storage.getSettings().closeMinimized);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  Future<void> onWindowClose() async {
    final isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await DesktopWindowManager._minimizeToTray();
    }
  }

  // WindowManager signals
  @override
  void onWindowFocus() {
    // do something
    setState(() {});
  }

  @override
  void onWindowBlur() {
    // do something
  }

  @override
  void onWindowMaximize() {
    // do something
  }

  @override
  void onWindowUnmaximize() {
    // do something
  }

  @override
  void onWindowMinimize() {
    // do something
  }

  @override
  void onWindowRestore() {
    // do something
  }

  @override
  void onWindowResize() {
    // do something
  }

  @override
  void onWindowMove() {
    // do something
  }

  @override
  void onWindowEnterFullScreen() {
    // do something
  }

  @override
  void onWindowLeaveFullScreen() {
    // do something
  }

  // TrayManager signals
  @override
  void onTrayIconMouseDown() {
    // do something, for example pop up the menu
    trayManager.popUpContextMenu();
    if (UniversalPlatform.isMacOS) {
      trayManager.popUpContextMenu();
    } else {
      if (!UniversalPlatform.isWindows) {
        trayManager.destroy();
      }
      windowManager.show();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    // do something
    UniversalPlatform.isMacOS
        ? windowManager.show()
        : trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseUp() {
    // do something
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      // do something
    } else if (menuItem.key == 'exit_app') {
      // do something
    }
  }
}
