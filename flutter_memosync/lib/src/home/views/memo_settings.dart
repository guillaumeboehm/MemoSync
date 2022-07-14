import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/home/bloc/home_bloc.dart';
import 'package:flutter_memosync/src/home/widgets/widgets.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:universal_platform/universal_platform.dart';

/// Different memo setting sections
enum Sections {
  /// Section handling notifications
  notifications,

  /// Section redirecting to widget creation
  ///
  /// On android would return to the widget creation screen if possible

  widget,

  /// Section to set the memo as background or lock screen
  background,
}

/// Memo settings view
class SettingsView extends StatefulWidget {
  /// Default constructor
  const SettingsView({
    Key? key,
    required this.constraints,
    required this.isWide,
  }) : super(key: key);

  /// Maps a [NotificationRepeatEvery] to a [String]
  static final repeatEveryToString = <NotificationRepeatEvery, String>{
    NotificationRepeatEvery.day: 'Day',
    NotificationRepeatEvery.week: 'Week',
    NotificationRepeatEvery.month: 'Month',
    NotificationRepeatEvery.year: 'Year',
    NotificationRepeatEvery.period: 'Period',
  };

  /// The size constraints for this view
  final BoxConstraints constraints;

  /// True if the application is in wide screen mode
  final bool isWide;

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final notificationTypeToString = <NotificationTypes, String>{
    NotificationTypes.fixedTime: 'Fixed time',
    NotificationTypes.timePeriod: 'Time period',
  };
  final notificationTypeToIcon = <NotificationTypes, Icon>{
    NotificationTypes.fixedTime: const Icon(Icons.calendar_month),
    NotificationTypes.timePeriod: const Icon(Icons.timer),
  };
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.constraints.maxWidth,
      child: BlocBuilder<HomeBloc, HomeState>(
        buildWhen: (previous, current) =>
            previous.currentMemo != current.currentMemo,
        builder: (context, state) {
          return Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Visibility(
                    visible: widget.isWide,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () {
                          context.read<HomeBloc>().add(
                                const ChangeViewPage(
                                  viewPage: ViewPage.memo,
                                ),
                              );
                        },
                        icon: Icon(Icons.adaptive.arrow_forward),
                        iconSize: 30,
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 60, vertical: 5),
                    child: Text(
                      '${state.currentMemo} settings',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ValueListenableBuilder<dynamic>(
                  valueListenable:
                      Storage.memoSettingsStorageStream(state.currentMemo),
                  builder: (context, dynamic dynSettings, _) {
                    final settings = dynSettings as Map<String, dynamic>;
                    return settingsList(settings, state.currentMemo);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  //########################### SETTINGS LIST ##################################
  SettingsList settingsList(
    Map<String, dynamic> settings,
    String currentMemo,
  ) {
    final sectionToString = <Sections, String>{
      Sections.notifications: 'Notification',
      Sections.widget: 'Widget',
      Sections.background: 'Background',
    };

    final sectionsList = <SettingsSection>[];

    for (final section in Sections.values) {
      // build the tiles
      final tiles = <AbstractSettingsTile>[];
      if (section == Sections.notifications &&
          (UniversalPlatform.isAndroid || UniversalPlatform.isIOS)) {
        // Permanent notifications
        const setting = 'permanent_notification';
        tiles.add(
          SettingsTile.switchTile(
            onToggle: (value) {
              settings[setting] = !(settings[setting] as bool? ?? false);
              Storage.setMemoSettings(
                memo: currentMemo,
                settings: settings,
              );
            },
            initialValue: (settings[setting] as bool?) ?? false,
            leading: const Icon(Icons.notification_important),
            title: const Text('Pinned notification'),
            description: const Text(
              '''Pins a non-discardlable notification with the content of the memo''',
            ),
          ),
        );
      }
      if (section == Sections.notifications) {
        // recurrent notifications
        const setting = 'notifications_on';
        tiles.add(
          SettingsTile.switchTile(
            onToggle: (value) {
              settings[setting] = !(settings[setting] as bool? ?? false);
              Storage.setMemoSettings(
                memo: currentMemo,
                settings: settings,
              );
            },
            initialValue: (settings[setting] as bool?) ?? false,
            leading: const Icon(Icons.notifications_on),
            title: const Text('Recurrent notifications'),
          ),
        );
      }
      if (section == Sections.notifications &&
          (settings['notifications_on'] as bool? ?? false)) {
        // Add notifications
        tiles.add(
          SettingsTile(
            enabled: settings['notifications_on'] as bool? ?? false,
            trailing: const Icon(Icons.add),
            title: const Text('Add notification'),
            onPressed: (context) async {
              // ignore: avoid_dynamic_calls
              if (settings['notifications'].runtimeType != List<dynamic>) {
                settings['notifications'] = <dynamic>[];
              }
              await showNotificationDialog(context).then((data) {
                Logger.info(data.toString());
                if (data == null) return;

                (settings['notifications'] as List<dynamic>).add(data);
                Storage.setMemoSettings(
                  memo: currentMemo,
                  settings: settings,
                );
              });
            },
          ),
        );

        //  notifications
        const setting = 'notifications';
        // ignore: avoid_dynamic_calls
        if (settings[setting].runtimeType == List) {
          var index = 0;
          for (final notifDyn in settings[setting] as List<dynamic>) {
            final ind = index;
            final notif = notifDyn as Map<dynamic, dynamic>;

            tiles.add(
              notificationTile(
                currentMemo: currentMemo,
                settings: settings,
                setting: setting,
                ind: ind,
                notifInfo: notif,
              ),
            );
            index++;
          }
        }
      }
      if (section == Sections.widget &&
          (UniversalPlatform.isAndroid || UniversalPlatform.isIOS || true)) {
        tiles.add(
          SettingsTile(
            title: const Text('Set widgets'),
          ),
        );
      }
      if (section == Sections.background &&
          (UniversalPlatform.isAndroid || UniversalPlatform.isIOS || true)) {
        tiles
          ..add(
            SettingsTile(
              title: const Text('Set as home page background'),
              onPressed: (context) {},
            ),
          )
          ..add(
            SettingsTile(
              title: const Text('Set as lock screen background'),
              onPressed: (context) {},
            ),
          );
      }

      // build the sections with the tiles
      if (tiles.isNotEmpty) {
        sectionsList.add(
          SettingsSection(
            title: Text(sectionToString[section]!),
            tiles: tiles,
          ),
        );
      }
    }

    return SettingsList(
      // platform: DevicePlatform.web,
      sections: sectionsList,
    );
  }
}
