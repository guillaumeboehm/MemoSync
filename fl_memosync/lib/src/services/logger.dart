import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quick_notify/quick_notify.dart';

/// Static class used to log information in the console.
class Logger {
  static const String _errorPrefix = '[Error]';
  static const String _infoPrefix = '[Info]';
  static String get _file =>
      '(${RegExp(r'(?<=#2)(?:[^\(]+\()([^\)]+)').firstMatch(
            StackTrace.current.toString(),
          )?.group(1)})';

  /// Are info logs printed.
  static bool printInfoLogs = true;

  /// Prints an error log to the console.
  static Future<void> error(String? str) async {
    if (!kDebugMode) return;
    final time = DateTime.now();
    final value = '$_errorPrefix [${time.year}-${time.month}-${time.day} '
        '${time.hour}:${time.minute}:${time.second}] $str $_file';
    // ignore: avoid_print
    print(value);
  }

  /// Prints an error log to the console using an [Exception] as parameter.
  static Future<void> errorFromException(Exception e) async {
    if (!kDebugMode) return;
    final time = DateTime.now();
    final value = '$_errorPrefix [${time.year}-${time.month}-${time.day} '
        '${time.hour}:${time.minute}:${time.second}] ${e.toString()} $_file';
    // ignore: avoid_print
    print(value);
  }

  /// Prints an info log to the console.
  static Future<void> info(String? str) async {
    if (!kDebugMode || !printInfoLogs) return;
    final time = DateTime.now();
    final value = '$_infoPrefix [${time.year}-${time.month}-${time.day} '
        '${time.hour}:${time.minute}:${time.second}] $str $_file';
    // ignore: avoid_print
    print(value);
  }

  /// Displays a debug message on the screen.
  static Future<bool> notify(String? str) async {
    if (!kDebugMode || !printInfoLogs) return false;
    if (!await QuickNotify.hasPermission()) {
      if (!await QuickNotify.requestPermission()) return false;
    }
    final time = DateTime.now();
    QuickNotify.notify(
      title: '''
[${time.year}-${time.month}-${time.day} ${time.hour}:${time.minute}:${time.second}]''',
      content: str,
    );
    return true;
  }
}
