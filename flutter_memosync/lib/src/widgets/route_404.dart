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
      children: const [
        Padding(padding: EdgeInsets.all(100)),
        Text(
          '404',
          style: TextStyle(fontSize: 100),
        ),
        Padding(padding: EdgeInsets.all(30)),
        Text("Dude I don't know what to do here."),
      ],
    ),
  ),
);
