import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memosync/src/home/views/memo_settings.dart';
import 'package:memosync/src/services/logger.dart';
import 'package:memosync/src/services/models/memo.dart';
import 'package:memosync/src/services/storage/storage.dart';
import 'package:settings_ui/settings_ui.dart';

/// Returns a notification [SettingsTile]
SettingsTile notificationTile({
  required String currentMemo,
  required Map<String, dynamic> settings,
  required String setting,
  required int ind,
  required Map<dynamic, dynamic> notifInfo,
}) {
  return SettingsTile(
    trailing: IconButton(
      icon: const Icon(Icons.delete),
      onPressed: () {
        (settings[setting] as List<dynamic>).removeAt(ind);
        Storage.setMemoSettings(
          memo: currentMemo,
          settings: settings,
        );
      },
    ),
    title: RichText(
      text: TextSpan(
        children: [
          const TextSpan(text: 'Every '),
          if (notifInfo['repeatEvery'] as NotificationRepeatEvery ==
              NotificationRepeatEvery.period)
            TextSpan(
              children: [
                if (notifInfo['repeatEveryHour'] as int > 0)
                  TextSpan(
                    text: """
${notifInfo['repeatEveryHour'].toString().padLeft(2, '0')}${tr('label.hour').characters.first}""",
                  ),
                if (notifInfo['repeatEveryMinute'] as int > 0)
                  TextSpan(
                    text: """
${notifInfo['repeatEveryMinute'].toString().padLeft(2, '0')}${tr('label.minute').characters.first}""",
                  ),
                if (notifInfo['repeatEverySecond'] as int > 0)
                  TextSpan(
                    text: """
${notifInfo['repeatEverySecond'].toString().padLeft(2, '0')}${tr('label.second').characters.first}""",
                  ),
              ],
            )
          else if (notifInfo['repeatEveryCount'] as int > 1)
            TextSpan(
              text: "${notifInfo['repeatEveryCount'].toString()} ",
            ),
          if (notifInfo['repeatEvery'] as NotificationRepeatEvery !=
              NotificationRepeatEvery.period)
            TextSpan(
              text: """
${SettingsView.repeatEveryToString[notifInfo['repeatEvery']]?.toLowerCase()}"""
                  """
${(notifInfo['repeatEveryCount'] as int > 1) ? 's' : ''}"""
                  """
 at ${notifInfo['repeatEveryHour'].toString().padLeft(2, '0')}:${notifInfo['repeatEveryMinute'].toString().padLeft(2, '0')}""",
            ),
        ],
      ),
    ),
    description: ((notifInfo['repeatEvery'] as NotificationRepeatEvery ==
                    NotificationRepeatEvery.period &&
                (notifInfo['ignoreOnDays'] as Map)
                    .values
                    .every((element) => element == false)) ||
            notifInfo['repeatEvery'] as NotificationRepeatEvery ==
                NotificationRepeatEvery.day)
        ? null
        : RichText(
            text: TextSpan(
              children: [
                if (notifInfo['repeatEvery'] as NotificationRepeatEvery ==
                    NotificationRepeatEvery.period)
                  TextSpan(
                    text: """
Except on ${(Map<String, bool>.from(notifInfo['ignoreOnDays'] as Map)..removeWhere((_, isIgnored) => !isIgnored)).keys.join(', ')}""",
                  )
                else
                  const TextSpan(text: 'On '),
                if (notifInfo['repeatEvery'] as NotificationRepeatEvery ==
                    NotificationRepeatEvery.week)
                  TextSpan(
                    text: (Map<String, bool>.from(
                      notifInfo['repeatOnDays'] as Map,
                    )..removeWhere((_, isActive) => !isActive))
                        .keys
                        .join(', '),
                  ),
                if (notifInfo['repeatEvery'] as NotificationRepeatEvery ==
                    NotificationRepeatEvery.month)
                  TextSpan(
                    text: """
the ${dateToDayString(notifInfo['repeatOnDate'] as DateTime)}""",
                  ),
                if (notifInfo['repeatEvery'] as NotificationRepeatEvery ==
                    NotificationRepeatEvery.year)
                  TextSpan(
                    text: """
the ${dateToDayOfMonthString(notifInfo['repeatOnDate'] as DateTime)}""",
                  ),
              ],
            ),
          ),
    onPressed: (context) async {
      await showNotificationDialog(
        context,
        data:
            (settings[setting] as List<dynamic>)[ind] as Map<dynamic, dynamic>?,
      ).then((data) {
        if (data == null) return;

        (settings[setting] as List<dynamic>)[ind] = data;
        Storage.setMemoSettings(
          memo: currentMemo,
          settings: settings,
        );
      });
    },
  );
}

/// Opens the dialog to configure a notifacation
///
/// [data] takes the previous notification data
/// and returns the new data in a future
Future<Map<dynamic, dynamic>?> showNotificationDialog(
  BuildContext context, {
  Map<dynamic, dynamic>? data,
}) async {
  unawaited(Logger.info(data.toString()));
  final _data = data ??
      <String, dynamic>{
        'repeatEveryCount': 1,
        'repeatEvery': NotificationRepeatEvery.day,
        'repeatEveryHour': TimeOfDay.now().hour,
        'repeatEveryMinute': TimeOfDay.now().minute,
        'repeatEverySecond': 0,
        'repeatOnDays': <String, bool>{
          (tr('label.monday').length > 3)
              ? tr('label.monday').substring(0, 3)
              : tr('label.monday'): false,
          (tr('label.tuesday').length > 3)
              ? tr('label.tuesday').substring(0, 3)
              : tr('label.tuesday'): false,
          (tr('label.wednsday').length > 3)
              ? tr('label.wednsday').substring(0, 3)
              : tr('label.wednsday'): false,
          (tr('label.thursday').length > 3)
              ? tr('label.thursday').substring(0, 3)
              : tr('label.thursday'): false,
          (tr('label.friday').length > 3)
              ? tr('label.friday').substring(0, 3)
              : tr('label.friday'): false,
          (tr('label.saturday').length > 3)
              ? tr('label.saturday').substring(0, 3)
              : tr('label.saturday'): false,
          (tr('label.sunday').length > 3)
              ? tr('label.sunday').substring(0, 3)
              : tr('label.sunday'): false,
        },
        'ignoreOnDays': <String, bool>{
          (tr('label.monday').length > 3)
              ? tr('label.monday').substring(0, 3)
              : tr('label.monday'): false,
          (tr('label.tuesday').length > 3)
              ? tr('label.tuesday').substring(0, 3)
              : tr('label.tuesday'): false,
          (tr('label.wednsday').length > 3)
              ? tr('label.wednsday').substring(0, 3)
              : tr('label.wednsday'): false,
          (tr('label.thursday').length > 3)
              ? tr('label.thursday').substring(0, 3)
              : tr('label.thursday'): false,
          (tr('label.friday').length > 3)
              ? tr('label.friday').substring(0, 3)
              : tr('label.friday'): false,
          (tr('label.saturday').length > 3)
              ? tr('label.saturday').substring(0, 3)
              : tr('label.saturday'): false,
          (tr('label.sunday').length > 3)
              ? tr('label.sunday').substring(0, 3)
              : tr('label.sunday'): false,
        },
        'repeatOnDate': DateTime.now(),
      };
  final focusNode = FocusNode();
  const helperOffset = 13.0;

  bool validate(
    dynamic data, {
    void Function()? validCallback,
  }) {
    var valid = true;
    String? errMsg;

    // Validate weeks
    if ((data as Map)['repeatEvery'] == NotificationRepeatEvery.week) {
      if ((data['repeatOnDays'] as Map).values.every((el) => el == false)) {
        valid = false;
        errMsg = tr(
          'memo.settings.recurrent_notifications.select_one_day',
        );
      }
    }

    if (valid) {
      if (validCallback != null) validCallback();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade400,
          content: Text(errMsg ?? tr('general.unknown_error')),
        ),
      );
    }
    return valid;
  }

  return showDialog<Map<dynamic, dynamic>>(
    context: context,
    // barrierDismissible: true,
    builder: (diagContext) {
      return RawKeyboardListener(
        focusNode: focusNode,
        onKey: (event) {
          if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
            validate(
              _data,
              validCallback: () => Navigator.pop(diagContext, _data),
            );
          }
        },
        child: SimpleDialog(
          contentPadding: const EdgeInsets.all(10),
          children: [
            StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                void setData(Map<String, dynamic> data) => setState(() {
                      data.forEach((key, value) {
                        _data[key] = value;
                      });
                    });
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(
                        'memo.settings.recurrent_notifications.repeat_every',
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // EVERY X DAYS/WEEKS
                        if (_data['repeatEvery'] !=
                            NotificationRepeatEvery.period)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                controller: TextEditingController(
                                  text: _data['repeatEveryCount'].toString(),
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                onChanged: (repeatEveryCount) => setData(
                                  {
                                    'repeatEveryCount': int.parse(
                                      repeatEveryCount.isEmpty
                                          ? '0'
                                          : repeatEveryCount,
                                    ),
                                  },
                                ),
                              ),
                            ),
                          )

                        // EVERY X:X:X Hours
                        else
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(0, helperOffset),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: TextEditingController(
                                        text: _data['repeatEveryHour']
                                            .toString()
                                            .padLeft(2, '0'),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        helperText: 'hours',
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (repeatEveryHour) => setData(
                                        {
                                          'repeatEveryHour': int.parse(
                                            repeatEveryHour.isEmpty
                                                ? '00'
                                                : repeatEveryHour,
                                          ),
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(':'),
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(0, helperOffset),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: TextEditingController(
                                        text: _data['repeatEveryMinute']
                                            .toString()
                                            .padLeft(2, '0'),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        helperText: 'min',
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (repeatEveryMinute) => setData(
                                        {
                                          'repeatEveryMinute': int.parse(
                                            repeatEveryMinute.isEmpty
                                                ? '00'
                                                : repeatEveryMinute,
                                          ),
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                const Text(':'),
                                Expanded(
                                  child: Transform.translate(
                                    offset: const Offset(0, helperOffset),
                                    child: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      controller: TextEditingController(
                                        text: _data['repeatEverySecond']
                                            .toString()
                                            .padLeft(2, '0'),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        helperText: 'sec',
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (repeatEverySecond) => setData(
                                        {
                                          'repeatEverySecond': int.parse(
                                            repeatEverySecond.isEmpty
                                                ? '00'
                                                : repeatEverySecond,
                                          ),
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // EVERY Days/Weeks/Months
                        DropdownButton<NotificationRepeatEvery>(
                          value: _data['repeatEvery']
                                  as NotificationRepeatEvery? ??
                              NotificationRepeatEvery.day,
                          items: [
                            DropdownMenuItem(
                              value: NotificationRepeatEvery.day,
                              child: Text(
                                SettingsView.repeatEveryToString[
                                    NotificationRepeatEvery.day]!,
                              ),
                            ),
                            DropdownMenuItem(
                              value: NotificationRepeatEvery.week,
                              child: Text(
                                SettingsView.repeatEveryToString[
                                    NotificationRepeatEvery.week]!,
                              ),
                            ),
                            DropdownMenuItem(
                              value: NotificationRepeatEvery.month,
                              child: Text(
                                SettingsView.repeatEveryToString[
                                    NotificationRepeatEvery.month]!,
                              ),
                            ),
                            DropdownMenuItem(
                              value: NotificationRepeatEvery.year,
                              child: Text(
                                SettingsView.repeatEveryToString[
                                    NotificationRepeatEvery.year]!,
                              ),
                            ),
                            DropdownMenuItem(
                              value: NotificationRepeatEvery.period,
                              child: Text(
                                SettingsView.repeatEveryToString[
                                    NotificationRepeatEvery.period]!,
                              ),
                            ),
                          ],
                          onChanged: (repeatEvery) {
                            setData({'repeatEvery': repeatEvery});
                          },
                        ),

                        // AT X:X HOUR
                        if (_data['repeatEvery'] !=
                            NotificationRepeatEvery.period)
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  """at ${(_data['repeatEveryHour'] ?? TimeOfDay.now().hour).toString().padLeft(2, '0')}:"""
                                  """${(_data['repeatEveryMinute'] ?? TimeOfDay.now().minute).toString().padLeft(2, '0')}""",
                                ),
                                IconButton(
                                  onPressed: () {
                                    showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                    ).then((time) {
                                      if (time == null) return;
                                      setData({
                                        'repeatEveryHour': time.hour,
                                        'repeatEveryMinute': time.minute,
                                      });
                                    });
                                  },
                                  icon: const Icon(Icons.alarm),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Padding(padding: EdgeInsets.only(top: 10)),
                    if (_data['repeatEvery'] == NotificationRepeatEvery.week)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          """
Repeat on: ${(Map<String, bool>.from(_data['repeatOnDays'] as Map)..removeWhere((key, value) => !value)).keys.join(', ')}""",
                        ),
                      ),
                    if (_data['repeatEvery'] == NotificationRepeatEvery.week)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(
                            (_data['repeatOnDays'] as Map).keys.length,
                            (index) {
                              final day = (_data['repeatOnDays'] as Map)
                                  .keys
                                  .elementAt(index) as String;
                              final isOn = (_data['repeatOnDays'] as Map)
                                  .values
                                  .elementAt(index) as bool;
                              return isOn
                                  ? ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          (_data['repeatOnDays'] as Map)[day] =
                                              false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                      ),
                                      child: Text(
                                        day.characters.first.toUpperCase(),
                                      ),
                                    )
                                  : OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          (_data['repeatOnDays'] as Map)[day] =
                                              true;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        shape: const CircleBorder(),
                                      ),
                                      child: Text(
                                        day.characters.first.toUpperCase(),
                                      ),
                                    );
                            },
                          ),
                        ),
                      ),
                    if (_data['repeatEvery'] == NotificationRepeatEvery.month ||
                        _data['repeatEvery'] == NotificationRepeatEvery.year)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_data['repeatEvery'] ==
                              NotificationRepeatEvery.month)
                            // Occurs on this day of the month
                            Text(
                              tr(
                                '''
memo.settings.recurrent_notifications.repeat_on_day''',
                                namedArgs: {
                                  'day': dateToDayString(
                                    (_data['repeatOnDate'] as DateTime)
                                        .toLocal(),
                                  ),
                                  'monthOrYear': tr('label.month'),
                                },
                              ),
                            )
                          else
                            // Occurs on this day of the year
                            Text(
                              tr(
                                '''
memo.settings.recurrent_notifications.repeat_on_day''',
                                namedArgs: {
                                  'day': dateToDayOfMonthString(
                                    (_data['repeatOnDate'] as DateTime)
                                        .toLocal(),
                                  ),
                                  'monthOrYear': tr('label.year'),
                                },
                              ),
                            ),
                          IconButton(
                            onPressed: () {
                              (_data['repeatEvery'] ==
                                          NotificationRepeatEvery.month
                                      ? showDatePicker(
                                          context: context,
                                          firstDate: DateTime(
                                            (_data['repeatOnDate'] as DateTime)
                                                .year,
                                            (_data['repeatOnDate'] as DateTime)
                                                .month,
                                          ),
                                          lastDate: DateTime(
                                            (_data['repeatOnDate'] as DateTime)
                                                .year,
                                            (_data['repeatOnDate'] as DateTime)
                                                    .month +
                                                1,
                                          ).subtract(const Duration(days: 1)),
                                          initialDate:
                                              _data['repeatOnDate'] as DateTime,
                                        )
                                      : showDatePicker(
                                          context: context,
                                          firstDate: DateTime(
                                            (_data['repeatOnDate'] as DateTime)
                                                .year,
                                          ),
                                          lastDate: DateTime(
                                            (_data['repeatOnDate'] as DateTime)
                                                    .year +
                                                1,
                                          ).subtract(const Duration(days: 1)),
                                          initialDate:
                                              _data['repeatOnDate'] as DateTime,
                                        ))
                                  .then((date) {
                                // Save date
                                if (date == null) return;
                                setData({'repeatOnDate': date.toUtc()});
                              });
                            },
                            icon: const Icon(Icons.timer),
                          ),
                        ],
                      ),
                    if (_data['repeatEvery'] == NotificationRepeatEvery.period)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, top: 20),
                        child: Text(
                          tr(
                            'memo.settings.recurrent_notifications.ignore_on',
                            namedArgs: {
                              'dayList': (Map<String, bool>.from(
                                _data['ignoreOnDays'] as Map,
                              )..removeWhere((key, value) => !value))
                                  .keys
                                  .join(', '),
                            },
                          ),
                        ),
                      ),
                    if (_data['repeatEvery'] == NotificationRepeatEvery.period)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(
                            (_data['ignoreOnDays'] as Map).keys.length,
                            (index) {
                              final day = (_data['ignoreOnDays'] as Map)
                                  .keys
                                  .elementAt(index) as String;
                              final isOn = (_data['ignoreOnDays'] as Map)
                                  .values
                                  .elementAt(index) as bool;
                              return isOn
                                  ? ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          (_data['ignoreOnDays'] as Map)[day] =
                                              false;
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        shape: const CircleBorder(),
                                      ),
                                      child: Text(
                                        day.characters.first.toUpperCase(),
                                      ),
                                    )
                                  : OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          (_data['ignoreOnDays']
                                              as Map<String, bool>)[day] = true;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        shape: const CircleBorder(),
                                      ),
                                      child: Text(
                                        day.characters.first.toUpperCase(),
                                      ),
                                    );
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const Padding(padding: EdgeInsets.only(bottom: helperOffset)),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(diagContext),
                  child: Text(tr('label.cancel').toUpperCase()),
                ),
                TextButton(
                  onPressed: () => validate(
                    _data,
                    validCallback: () => Navigator.pop(diagContext, _data),
                  ),
                  child: Text(tr('label.ok').toUpperCase()),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// Returns the day of [date] as <day>[st|nd|rd|th]
String dateToDayString(DateTime date) {
  final day = date.day;
  switch (day.toString().characters.last) {
    case '1':
      return '${day.toString()}st';
    case '2':
      return '${day.toString()}nd';
    case '3':
      return '${day.toString()}rd';
    default:
      return '${day.toString()}th';
  }
}

/// Returns the day of [date] as <day>[st|nd|rd|th] of <month>
String dateToDayOfMonthString(DateTime date) {
  const months = [
    'January',
    'Febuary',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  return '${dateToDayString(date)} of ${months[date.month]}';
}
