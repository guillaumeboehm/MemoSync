import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// The material page route for a 404 page
MaterialPageRoute<void> route404 = MaterialPageRoute<void>(
  builder: (_) => Scaffold(
    body: page404,
  ),
);

/// The body of a 404 page
Widget page404 = SingleChildScrollView(
  child: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(padding: EdgeInsets.all(100)),
        const Text(
          '404',
          style: TextStyle(fontSize: 100),
        ),
        const Padding(padding: EdgeInsets.all(30)),
        Text(tr('general.404')),
      ],
    ),
  ),
);
