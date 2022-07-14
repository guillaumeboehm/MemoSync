import 'package:flutter/material.dart' show Widget;

class WM {
  static Widget windowWrapper({required Widget child}) => child;
  static Future<void> init() => Future(() {
        print('stubbing WM');
      });
}
