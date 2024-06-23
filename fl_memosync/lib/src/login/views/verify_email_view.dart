import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memosync/src/authentication/authentication.dart';
import 'package:memosync/src/services/models/models.dart';
import 'package:memosync/src/services/storage/storage.dart';
import 'package:universal_html/html.dart' show window;

/// Returns
class VerifyEmail extends Widget {
  /// Default constructor
  const VerifyEmail({
    super.key,
    required this.args,
    // required this.context,
  });

  /// route and query arguments
  final Map<String, String> args;

  @override
  Element createElement() {
    final widget = ValueListenableBuilder<SettingsObject>(
        valueListenable: Storage.settingsStorageStream(),
        builder: (context, val, _) {
          return BlocBuilder<AuthenticationBloc, AuthenticationState>(
            buildWhen: (previous, current) =>
                previous.formInfo != current.formInfo,
            builder: (context, state) {
              return (state.formInfo == null ||
                      state.formInfo!.contains('error'))
                  ? Builder(
                      builder: (context) {
                        context.read<AuthenticationBloc>().add(
                              AuthVerifyEmail(
                                args['user']!,
                                args['token']!,
                              ),
                            );
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tr('authentication.verifying'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 50),
                            ),
                            const Padding(padding: EdgeInsets.all(10)),
                            const CircularProgressIndicator(),
                          ],
                        );
                      },
                    )
                  : Builder(
                      builder: (context) {
                        final formInfo =
                            jsonDecode(state.formInfo!) as Map<String, dynamic>;
                        final result =
                            formInfo['success'] as Map<String, dynamic>;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              result['text'] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const Padding(padding: EdgeInsets.all(10)),
                            ElevatedButton(
                              onPressed: () {
                                window.location.href = '/';
                              },
                              child: Text(result['button'] as String),
                            ),
                          ],
                        );
                      },
                    );
            },
          );
        });
    return widget.createElement();
  }
}
