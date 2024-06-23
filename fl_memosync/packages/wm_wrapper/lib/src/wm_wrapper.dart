import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:system_tray/system_tray.dart' as st;
import 'package:system_tray/system_tray.dart' as st;
import 'package:universal_platform/universal_platform.dart';
import 'package:window_manager/window_manager.dart';

class WM {
  static Widget windowWrapper({
    required Widget child,
  }) {
    return UniversalPlatform.isDesktop
        ? _Wrapper(
            child: child,
          )
        : child;
  }

  static Future<void> forceClose() async {
    if (await windowManager.isPreventClose()) {
      await windowManager.setPreventClose(false);
      await windowManager.close();
      // if error set it back
      await windowManager.setPreventClose(true);
    } else {
      await windowManager.close();
    }
  }

  static Future<void> toggleVisibility() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
  }

  static Future<void> minimizeOnClose(bool enabled) async {
    await windowManager.setPreventClose(enabled);
  }

  static Future<void> init() async {
    if (!UniversalPlatform.isDesktop) {
      if (kDebugMode) print('Stubbing WM');
      return;
    }

    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      minimumSize: Size(800, 600),
      title: 'MemoSync',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    await _initSystemTray();
  }

  static Future<void> _initSystemTray() async {
    final path = UniversalPlatform.isWindows
        ? 'assets/resources/logos/ico/Full_logo_32px.ico'
        : 'assets/resources/logos/png/Full_logo_32px.png';

    final systemTray = st.SystemTray();

    // We first init the systray menu
    await systemTray.initSystemTray(
      toolTip: 'MemoSync',
      iconPath: path,
    );

    // create context menu
    final menu = st.Menu();
    await menu.buildFrom([
      st.MenuItemLable(
        label: 'Show/Hide',
        onClicked: (menuItem) => toggleVisibility(),
      ),
      st.MenuItemLable(
        label: 'Exit',
        onClicked: (menuItem) {
          forceClose();
        },
      ),
    ]);

    // set context menu
    await systemTray.setContextMenu(menu);

    // handle system tray event
    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == st.kSystemTrayEventClick) {
        if (UniversalPlatform.isMacOS) {
          systemTray.popUpContextMenu();
        } else {
          UniversalPlatform.isWindows
              ? windowManager.show()
              : toggleVisibility();
        }
      } else if (eventName == st.kSystemTrayEventRightClick) {
        UniversalPlatform.isMacOS
            ? windowManager.show()
            : systemTray.popUpContextMenu();
      }
    });
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
    await windowManager.setPreventClose(true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  Future<void> onWindowClose() async {
    // do something
    final _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onWindowFocus() {
    // do something
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
