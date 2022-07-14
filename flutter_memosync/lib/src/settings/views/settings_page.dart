import 'package:flutter/material.dart';
import 'package:flutter_memosync/src/services/desktop_window_manager.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/widgets/number_input.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:universal_platform/universal_platform.dart';

/// Page showing the app settings
class SettingsPage extends StatelessWidget {
  /// Default constructor
  const SettingsPage({Key? key}) : super(key: key);

  /// Settings page route
  static MaterialPageRoute<SettingsPage> route() =>
      MaterialPageRoute<SettingsPage>(
        builder: (context) => const SettingsPage(),
      );

  @override
  Widget build(BuildContext context) {
    Logger.info('Building settings page.');
    return Scaffold(
      appBar: AppBar(
        title: Flex(
          direction: Axis.horizontal,
          children: const [
            Flexible(
              child: Text(
                'Global Settings',
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<Box<SettingsObject>>(
        valueListenable: Storage.settingsStorageStream,
        builder: (context, settingsBox, _) {
          final settings = Storage.getSettings();
          return SettingsList(
            sections: [
              // GENERAL
              SettingsSection(
                title: const Text('General'),
                tiles: [
                  if (UniversalPlatform.isDesktop)
                    SettingsTile.switchTile(
                      title: const Text('Launch on system startup'),
                      initialValue: settings.onStartup,
                      onToggle: (enabled) async {
                        if (await DesktopWindowManager.launchOnStartup(
                          enabled: enabled,
                        )) {
                          Storage.setSettings(
                            settings..onStartup = enabled,
                          );
                          enabled
                              ? await launchAtStartup.enable()
                              : await launchAtStartup.disable();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Couldn't set this option."),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      },
                    ),
                  if (UniversalPlatform.isDesktop)
                    SettingsTile.switchTile(
                      title: const Text('Minimized on close'),
                      initialValue: settings.closeMinimized,
                      onToggle: (enabled) async {
                        if (await DesktopWindowManager.minimizeOnClose(
                          enabled: enabled,
                        )) {
                          Storage.setSettings(
                            settings..closeMinimized = enabled,
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Couldn't set this option."),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      },
                    ),
                  if (UniversalPlatform.isDesktop)
                    SettingsTile.switchTile(
                      title: const Text('Start minimized'),
                      enabled: settings.closeMinimized,
                      initialValue: settings.launchMinimized,
                      onToggle: (enabled) => Storage.setSettings(
                        settings..launchMinimized = enabled,
                      ),
                    ),
                  SettingsTile.switchTile(
                    title: const Text('Enable notifications'),
                    initialValue: settings.notificationsEnabled,
                    onToggle: (enabled) => Storage.setSettings(
                      settings..notificationsEnabled = enabled,
                    ),
                  ),
                  SettingsTile.navigation(
                    title: const Text('Autosave memos'),
                    onPressed: (_) {
                      Navigator.push(
                        context,
                        _AutoSaveMemos.route(),
                      );
                    },
                  ),
                  SettingsTile.navigation(
                    title: const Text('Background sync'),
                    onPressed: (_) {
                      Navigator.push(
                        context,
                        _BackgroundSync.route(),
                      );
                    },
                  ),
                ],
              ),
              // Appearance
              SettingsSection(
                title: const Text('Appearance'),
                tiles: [
                  SettingsTile.switchTile(
                    initialValue: settings.darkMode,
                    onToggle: (isDark) =>
                        Storage.setSettings(settings..darkMode = isDark),
                    title: const Text('Dark theme'),
                  ),
                  SettingsTile(
                    value: Text(settings.locale ?? 'English'),
                    onPressed: (lang) {
                      // ignore: lines_longer_than_80_chars
                      // TODO(me): set locale as default or a list of available languages
                      final locale =
                          settings.locale == 'English' ? 'French' : 'English';
                      Storage.setSettings(settings..locale = locale);
                    },
                    title: const Text('Language'),
                  ),
                ],
              ),
              // Account
              SettingsSection(
                title: const Text('Account'),
                tiles: [
                  SettingsTile.navigation(
                    enabled: false,
                    title: const Text('Change password'),
                    onPressed: (_) {
                      // TODO(me): implement
                    },
                  ),
                ],
              ),
              // Privacy
              SettingsSection(
                title: const Text('Privacy'),
                tiles: [
                  SettingsTile.switchTile(
                    enabled: false,
                    initialValue: false,
                    onToggle: (enabled) {
                      // TODO(me): implement
                    },
                    title: const Text('Opt-in analytics reporting'),
                  ),
                ],
              ),
              // Security
              SettingsSection(
                title: const Text('Security'),
                tiles: [
                  SettingsTile.switchTile(
                    enabled: false,
                    initialValue: false,
                    onToggle: (enabled) {
                      // TODO(me): implement
                    },
                    title: const Text('Enable full data encryption'),
                  ),
                ],
              ),
              // Advanced
              SettingsSection(
                title: const Text('Advanced'),
                tiles: [
                  SettingsTile.switchTile(
                    enabled: false,
                    initialValue: false,
                    onToggle: (enabled) {
                      // TODO(me): implement
                    },
                    title: const Text('Get development updates'),
                  ),
                ],
              ),
              // Help
              SettingsSection(
                title: const Text('Help'),
                tiles: [
                  SettingsTile.navigation(
                    enabled: false,
                    onPressed: (enabled) {
                      // TODO(me): implement
                    },
                    title: const Text('Reporting inconveniences and errors'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ############################################### AUTO SAVE MEMOS
class _AutoSaveMemos extends _SubSettingPage {
  const _AutoSaveMemos({
    required SettingsList Function(SettingsObject) builder,
  }) : super(title: 'Auto-save memos', builder: builder);

  /// Settings page route
  static MaterialPageRoute<_AutoSaveMemos> route() =>
      MaterialPageRoute<_AutoSaveMemos>(
        builder: (context) => _AutoSaveMemos(
          builder: (SettingsObject settings) {
            final interval = Duration(seconds: settings.autoSaveInterval);
            return SettingsList(
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      initialValue: settings.autoSave,
                      onToggle: (enabled) =>
                          Storage.setSettings(settings..autoSave = enabled),
                      title: const Text('Enabled'),
                    ),
                    SettingsTile(
                      enabled: settings.autoSave,
                      value: Text(
                        '''
${interval.toString().split('.')[0].replaceFirst(RegExp(':'), 'h').replaceFirst(RegExp(':'), 'm')}s''',
                      ),
                      onPressed: (value) {
                        showDialog<Duration>(
                          context: context,
                          builder: (diagContext) {
                            final hours =
                                (settings.autoSaveInterval / 3600).floor();
                            final minutes =
                                ((settings.autoSaveInterval - (hours * 3600)) /
                                        60)
                                    .floor();
                            final seconds = settings.autoSaveInterval -
                                (minutes * 60) -
                                (hours * 3600);
                            final hoursController = TextEditingController();
                            final minutesController = TextEditingController();
                            final secondsController = TextEditingController();

                            void submit() {
                              Navigator.pop(
                                diagContext,
                                Duration(
                                  hours: int.parse(hoursController.text),
                                  minutes: int.parse(minutesController.text),
                                  seconds: int.parse(secondsController.text),
                                ),
                              );
                            }

                            return SimpleDialog(
                              title: const Text('Set auto-save frequency'),
                              children: [
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      NumberInputField(
                                        controller: hoursController
                                          ..text = hours.toString(),
                                        submit: submit,
                                        hint: 'Hours',
                                        width: 60,
                                      ),
                                      NumberInputField(
                                        controller: minutesController
                                          ..text = minutes.toString(),
                                        submit: submit,
                                        hint: 'Minutes',
                                        width: 70,
                                        upperBound: 60,
                                      ),
                                      NumberInputField(
                                        controller: secondsController
                                          ..text = seconds.toString(),
                                        submit: submit,
                                        hint: 'Seconds',
                                        width: 70,
                                        upperBound: 60,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(diagContext);
                                      },
                                      child: const Text('CANCEL'),
                                    ),
                                    TextButton(
                                      onPressed: submit,
                                      child: const Text('OK'),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                        right: 20,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            );
                          },
                        ).then((autoSaveFreq) {
                          if (autoSaveFreq == null) return;
                          Storage.setSettings(
                            settings..autoSaveInterval = autoSaveFreq.inSeconds,
                          );
                        });
                      },
                      title: const Text('Autosave frequency'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
}

// ############################################### BACKGROUND SYNC
class _BackgroundSync extends _SubSettingPage {
  const _BackgroundSync({
    required SettingsList Function(SettingsObject) builder,
  }) : super(title: 'Background sync', builder: builder);

  /// Settings page route
  static MaterialPageRoute<_BackgroundSync> route() =>
      MaterialPageRoute<_BackgroundSync>(
        builder: (context) => _BackgroundSync(
          builder: (SettingsObject settings) {
            return SettingsList(
              sections: [
                SettingsSection(
                  tiles: [
                    SettingsTile.switchTile(
                      initialValue: settings.bgSync,
                      onToggle: (enabled) =>
                          Storage.setSettings(settings..bgSync = enabled),
                      title: const Text('Enabled'),
                    ),
                    SettingsTile.switchTile(
                      enabled: settings.bgSync,
                      initialValue: settings.bgSyncWifiOnly,
                      onToggle: (enabled) => Storage.setSettings(
                        settings..bgSyncWifiOnly = enabled,
                      ),
                      title: const Text('Synchronize on wifi only'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
}

abstract class _SubSettingPage extends StatelessWidget {
  const _SubSettingPage({Key? key, required this.title, required this.builder})
      : super(key: key);

  final String title;
  final SettingsList Function(SettingsObject) builder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Flex(
          direction: Axis.horizontal,
          children: [
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<Box<SettingsObject>>(
        valueListenable: Storage.settingsStorageStream,
        builder: (context, settingsBox, _) {
          final settings = Storage.getSettings();
          return builder(settings);
        },
      ),
    );
  }
}
