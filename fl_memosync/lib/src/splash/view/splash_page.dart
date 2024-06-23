import 'package:flutter/material.dart';

/// A simple splash [StatelessWidget]
/// with a centered [CircularProgressIndicator] in a [Scaffold]
///
/// A [MaterialPageRoute] is available with [SplashPage.route()]
class SplashPage extends StatelessWidget {
  /// Constructor for [SplashPage]
  const SplashPage({super.key});

  /// Returns a [MaterialPageRoute] building an instance of this class
  static Route<void> route() {
    return MaterialPageRoute<SplashPage>(builder: (_) => const SplashPage());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
