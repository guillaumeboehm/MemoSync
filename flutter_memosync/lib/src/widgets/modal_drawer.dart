import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/services/background_handlers/desktop_window_manager.dart';
import 'package:flutter_memosync/src/settings/settings.dart';

/// Drawer widget used in wide screen mode
class ModalDrawer extends StatefulWidget {
  /// Default constructor
  const ModalDrawer({super.key});

  @override
  State<ModalDrawer> createState() => _ModalDrawerState();

  /// Show the modal drawer menu using the parent context
  static void show(BuildContext context) {
    showDialog<ModalDrawer>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const ModalDrawer(),
    );
  }
}

class _ModalDrawerState extends State<ModalDrawer> {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return Dialog(
          alignment: const Alignment(1.1, -.95),
          child: Container(
            constraints: BoxConstraints.loose(const Size.fromWidth(100)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context)
                      ..pop()
                      ..push<void>(SettingsPage.route());
                  },
                  child: const Text('Settings'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context
                        .read<AuthenticationBloc>()
                        .add(AuthLogoutRequested());
                  },
                  child: const Text('Logout'),
                ),
                const ElevatedButton(
                  onPressed: DesktopWindowManager.forceExit,
                  child: Text('Exit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
