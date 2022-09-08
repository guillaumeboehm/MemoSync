import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Wraps Sentry.captureException for analytics option
Future<void> sentryCaptureException(Object e, StackTrace st) async {
  if (Storage.getSettings().analytics) {
    await Sentry.captureException(e, stackTrace: st);
  }
}

/// Wraps Sentry.captureMessage for analytics option
Future<void> sentryCaptureMessage(String msg) async {
  if (Storage.getSettings().analytics) {
    await Sentry.captureMessage(msg);
  }
}
