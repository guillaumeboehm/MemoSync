import 'package:sentry_flutter/sentry_flutter.dart';

/// Wraps Sentry.captureException for analytics option
Future<void> sentryCaptureException(Object e, StackTrace st) async {
  //TODO if option set
  await Sentry.captureException(e, stackTrace: st);
}

/// Wraps Sentry.captureMessage for analytics option
Future<void> sentryCaptureMessage(String msg) async {
  //TODO if option set
  await Sentry.captureMessage(msg);
}
