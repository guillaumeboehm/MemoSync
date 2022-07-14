import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_tray/system_tray.dart' as st;
import 'package:universal_io/io.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

/// Handles desktop application actions
class DesktopWindowManager {
  /// The app system tray icon
  static st.SystemTray? systemTray;

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

    // Show window if not launch minimized
    if (!Storage.getSettings().launchMinimized) {
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }

    // ### System tray stuff
    systemTray = st.SystemTray();
  }

  static Future<void> _makeSysTray() async {
    final path = UniversalPlatform.isWindows
        ? 'assets/resources/logos/ico/Full_logo_32px.ico'
        : 'assets/resources/logos/png/Full_logo_32px.png';

    // We first init the systray menu
    await systemTray?.initSystemTray(
      toolTip: 'MemoSync',
      iconPath: path,
    );

    // create context menu
    final menu = st.Menu();
    await menu.buildFrom([
      st.MenuItemLable(
        label: 'Open',
        onClicked: (menuItem) => _openFromTray(),
      ),
      st.MenuItemLable(
        label: 'Exit',
        onClicked: (menuItem) {
          windowManager.destroy();
        },
      ),
    ]);

    // set context menu
    await systemTray?.setContextMenu(menu);

    // handle system tray event
    systemTray?.registerSystemTrayEventHandler((eventName) {
      if (eventName == st.kSystemTrayEventClick) {
        if (UniversalPlatform.isMacOS) {
          systemTray?.popUpContextMenu();
        } else {
          UniversalPlatform.isWindows ? windowManager.show() : _openFromTray();
        }
      } else if (eventName == st.kSystemTrayEventRightClick) {
        UniversalPlatform.isMacOS
            ? windowManager.show()
            : systemTray?.popUpContextMenu();
      }
    });
  }

  static Future<void> _deleteSysTray() async {
    await systemTray?.destroy();
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

class _WrapperState extends State<_Wrapper> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    _init();
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
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
    final _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      await DesktopWindowManager._minimizeToTray();
    }
  }

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
}
