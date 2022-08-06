import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_translate/flutter_translate.dart';
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
    final widget = BlocBuilder<AuthenticationBloc, AuthenticationState>(
      buildWhen: (previous, current) => previous.formInfo != current.formInfo,
      builder: (context, state) {
        return (state.formInfo == null || state.formInfo!.contains('error'))
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
                        translate('authentication.verifying'),
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
                  final result = formInfo['success'] as Map<String, dynamic>;
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
    return widget.createElement();
  }
}
