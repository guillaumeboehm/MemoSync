class LaunchAtStartup {
  LaunchAtStartup._();

  /// The shared instance of [LaunchAtStartup].
  static final LaunchAtStartup instance = LaunchAtStartup._();

  void setup({
    required String appName,
    required String appPath,
    String? packageName,
    List<String> args = const [],
  }) {}

  /// Sets your app to auto-launch at startup
  Future<bool> enable() => Future.value(false);

  /// Disables your app from auto-launching at startup.
  Future<bool> disable() => Future.value(false);

  Future<bool> isEnabled() => Future.value(false);
}

final launchAtStartup = LaunchAtStartup.instance;
