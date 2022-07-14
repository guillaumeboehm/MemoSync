import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:universal_platform/universal_platform.dart';

class LaunchStartup {
  static Future<void> init() async {
    if (!UniversalPlatform.isDesktop) {
      print('stubbing StartupLauncher');
      return;
    }

    final packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  static Future<void> enable() async {
    if (UniversalPlatform.isDesktop) launchAtStartup.enable();
  }

  static Future<void> disable() async {
    if (UniversalPlatform.isDesktop) launchAtStartup.disable();
  }

  static Future<bool> isEnabled() async {
    return UniversalPlatform.isDesktop
        ? launchAtStartup.isEnabled()
        : Future(() => false);
  }
}
