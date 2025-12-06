import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memosync/src/authentication/authentication.dart';
import 'package:memosync/src/services/logger.dart';

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
    Logger.info(
      '[Splash] Fetching credentials from storage',
    );
    context.read<AuthenticationBloc>().add(AuthFromStorage());
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
