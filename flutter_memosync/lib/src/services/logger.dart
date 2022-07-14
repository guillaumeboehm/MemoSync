import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_memosync/app.dart';

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
  // TODO(me): not working
  static void graphic(String? str) {
    Future.doWhile(
      () async {
        if (App.context == null) {
          return Future.delayed(
            const Duration(milliseconds: 300),
            () => true,
          );
        }
        final time = DateTime.now();
        final value = '[${time.year}-${time.month}-${time.day} '
            '${time.hour}:${time.minute}:${time.second}] $str $_file';
        unawaited(
          showDialog(
            context: App.context!,
            builder: (BuildContext context) {
              return Text(value);
            },
          ),
        );
        return false;
      },
    );
  }
}
