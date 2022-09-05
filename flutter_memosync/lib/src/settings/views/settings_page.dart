import 'package:flutter/material.dart';
import 'package:flutter_memosync/src/services/background_handlers/desktop_window_manager.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/notification_service.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:flutter_memosync/src/utilities/string_extenstion.dart';
import 'package:flutter_memosync/src/widgets/number_input.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:universal_platform/universal_platform.dart';

/// Page showing the app settings
class SettingsPage extends StatelessWidget {
  /// Default constructor
  const SettingsPage({super.key});

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
          children: [
            Flexible(
              child: Text(
                tr('settings.title'),
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        ),
      ),
      body: ValueListenableBuilder<SettingsObject>(
        valueListenable: Storage.settingsStorageStream(),
        builder: (context, settings, _) {
          return SettingsList(
            sections: [
              // GENERAL
              SettingsSection(
                title: Text(tr('settings.general.section_title')),
                tiles: [
                  if (UniversalPlatform.isDesktop)
                    SettingsTile.switchTile(
                      title: Text(
                        tr('settings.general.launch_on_startup'),
                      ),
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
                              content: Text(
                                tr('settings.option_set_error_msg'),
                              ),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      },
                    ),
                  if (UniversalPlatform.isDesktop)
                    SettingsTile.switchTile(
                      title: Text(
                        tr('settings.general.minimize_on_close'),
                      ),
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
                              content: Text(
                                tr('settings.option_set_error_msg'),
                              ),
                              backgroundColor: Colors.red.shade400,
                            ),
                          );
                        }
                      },
                    ),
                  if (UniversalPlatform.isDesktop)
                    SettingsTile.switchTile(
                      title: Text(tr('settings.general.start_minimized')),
                      enabled: settings.closeMinimized,
                      initialValue: settings.launchMinimized,
                      onToggle: (enabled) => Storage.setSettings(
                        settings..launchMinimized = enabled,
                      ),
                    ),
                  SettingsTile.switchTile(
                    title: Text(
                      tr('settings.general.enable_notifications'),
                    ),
                    initialValue: settings.notificationsEnabled,
                    onToggle: (enabled) {
                      Storage.setSettings(
                        settings..notificationsEnabled = enabled,
                      );
                      if (enabled) {
                        NotificationService
                            .setPermanentNotificationFromOldState();
                      } else {
                        NotificationService.disablePermanentNotification();
                      }
                    },
                  ),
                  SettingsTile.navigation(
                    title: Text(
                      tr('settings.general.autosave.section_title'),
                    ),
                    onPressed: (_) {
                      Navigator.push(
                        context,
                        _AutoSaveMemos.route(),
                      );
                    },
                  ),
                  SettingsTile.navigation(
                    title: Text(
                      tr(
                        'settings.general.background_sync.section_title',
                      ),
                    ),
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
                title: Text(tr('settings.appearance.section_title')),
                tiles: [
                  SettingsTile.switchTile(
                    initialValue: settings.darkMode,
                    onToggle: (isDark) =>
                        Storage.setSettings(settings..darkMode = isDark),
                    title: Text(
                      tr('settings.appearance.dark_theme'),
                    ),
                  ),
                  SettingsTile(
                    title: Text(
                      tr('settings.appearance.language'),
                    ),
                    value: Text(
                      tr(
                        '''
language.name.${context.locale.languageCode}''',
                      ),
                    ),
                    onPressed: (_) {
                      showDialog<Locale?>(
                        context: context,
                        builder: (diagContext) {
                          // final delegate = LocalizedApp.of(context).delegate;
                          // final langs = delegate.supportedLocales;
                          return AlertDialog(
                            title: Text(
                              tr(
                                'language.selected_message',
                                namedArgs: {
                                  'language': tr(
                                    '''
language.name.${context.locale.languageCode}''',
                                  ),
                                },
                              ),
                            ),
                            content: SizedBox(
                              height: 400,
                              width: 400,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount:
                                          context.supportedLocales.length,
                                      itemBuilder: (context, index) {
                                        return ListTile(
                                          title: Text(
                                            tr(
                                              '''
language.name.${context.supportedLocales[index].languageCode}''',
                                            ),
                                          ),
                                          onTap: () => Navigator.pop(
                                            diagContext,
                                            context.supportedLocales[index],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ).then((locale) {
                        context.setLocale(
                          locale ??
                              context.fallbackLocale ??
                              context.deviceLocale,
                        );
                        // Storage.setSettings(
                        //   Storage.getSettings()
                        //     ..locale = tr(
                        //       'language.name.${locale?.languageCode}',
                        //     ),
                        // );
                      });
                    },
                  ),
                ],
              ),
              // Account
              SettingsSection(
                title: Text(
                  tr('settings.account.section_title'),
                ),
                tiles: [
                  SettingsTile.navigation(
                    enabled: false,
                    title: Text(
                      tr('settings.account.change_password'),
                    ),
                    onPressed: (_) {
                      // TODO(me): implement
                    },
                  ),
                ],
              ),
              // Privacy
              SettingsSection(
                title: Text(
                  tr('settings.privacy.section_title'),
                ),
                tiles: [
                  SettingsTile.switchTile(
                    enabled: false,
                    initialValue: false,
                    onToggle: (enabled) {
                      // TODO(me): implement
                    },
                    title: Text(
                      tr('settings.privacy.optin_analytics'),
                    ),
                  ),
                ],
              ),
              // Security
              SettingsSection(
                title: Text(
                  tr('settings.security.section_title'),
                ),
                tiles: [
                  SettingsTile.switchTile(
                    enabled: false,
                    initialValue: false,
                    onToggle: (enabled) {
                      // TODO(me): implement
                    },
                    title: Text(
                      tr('settings.security.data_encryption'),
                    ),
                  ),
                ],
              ),
              // Advanced
              SettingsSection(
                title: Text(
                  tr('settings.advanced.section_title'),
                ),
                tiles: [
                  SettingsTile.switchTile(
                    enabled: false,
                    initialValue: false,
                    onToggle: (enabled) {
                      // TODO(me): implement
                    },
                    title: Text(
                      tr('settings.advanced.devel_updates'),
                    ),
                  ),
                ],
              ),
              // Help
              SettingsSection(
                title: Text(
                  tr('settings.help.section_title'),
                ),
                tiles: [
                  SettingsTile.navigation(
                    enabled: false,
                    onPressed: (enabled) {
                      // TODO(me): implement
                    },
                    title: Text(
                      tr('settings.help.reporting'),
                    ),
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
  _AutoSaveMemos({
    required super.builder,
  }) : super(
          title: tr('settings.general.autosave.section_title'),
        );

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
                      title: Text(tr('label.enabled')),
                    ),
                    SettingsTile(
                      enabled: settings.autoSave,
                      value: Text(
                        '''
${interval.toString().split('.')[0].replaceFirst(RegExp(':'), tr('label.hour').characters.first).replaceFirst(RegExp(':'), tr('label.minute').characters.first)}${tr('label.seconds').characters.first}''',
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
                              title: Text(
                                tr(
                                  'settings.general.autosave.frequency',
                                ),
                              ),
                              children: [
                                Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      NumberInputField(
                                        controller: hoursController
                                          ..text = hours.toString(),
                                        submit: submit,
                                        hint: tr('label.hours').capitalize(),
                                        width: 60,
                                      ),
                                      NumberInputField(
                                        controller: minutesController
                                          ..text = minutes.toString(),
                                        submit: submit,
                                        hint: tr('label.minutes').capitalize(),
                                        width: 70,
                                        upperBound: 60,
                                      ),
                                      NumberInputField(
                                        controller: secondsController
                                          ..text = seconds.toString(),
                                        submit: submit,
                                        hint: tr('label.seconds').capitalize(),
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
                                      child: Text(
                                        tr('label.cancel').toUpperCase(),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: submit,
                                      child: Text(
                                        tr('label.ok').toUpperCase(),
                                      ),
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
                      title: Text(
                        tr('settings.general.autosave.frequency_label'),
                      ),
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
  _BackgroundSync({
    required super.builder,
  }) : super(title: tr('settings.general.background_sync.section_title'));

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
                      title: Text(tr('label.enabled')),
                    ),
                    if (!UniversalPlatform.isDesktopOrWeb)
                      SettingsTile.switchTile(
                        enabled: settings.bgSync,
                        initialValue: settings.bgSyncWifiOnly,
                        onToggle: (enabled) => Storage.setSettings(
                          settings..bgSyncWifiOnly = enabled,
                        ),
                        title: Text(
                          tr(
                            'settings.general.background_sync.wifi_only',
                          ),
                        ),
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
  const _SubSettingPage({
    required this.title,
    required this.builder,
  });

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
      body: ValueListenableBuilder<SettingsObject>(
        valueListenable: Storage.settingsStorageStream(),
        builder: (context, settings, _) {
          return builder(settings);
        },
      ),
    );
  }
}
