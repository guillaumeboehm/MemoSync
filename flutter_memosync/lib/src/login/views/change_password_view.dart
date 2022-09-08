import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:universal_html/html.dart' show window;
import 'package:validators/validators.dart';

/// Returns
class ChangePassword extends Widget {
  /// Default constructor
  ChangePassword({
    super.key,
    required this.args,
    // required this.context,
  });

  /// route and query arguments
  final Map<String, String> args;

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  final _passwordVisible = ValueNotifier<bool>(false);

  void _submit(
    GlobalKey<FormState> formKey,
    BuildContext context,
  ) {
    if (!context.read<AuthenticationBloc>().state.processing &&
        formKey.currentState!.validate()) {
      context.read<AuthenticationBloc>().add(
            AuthChangePassword(
              args['user']!,
              _passwordController.text,
              args['token']!,
            ),
          );
    }
  }

  @override
  Element createElement() {
    final widget = ValueListenableBuilder(
      valueListenable: Storage.settingsStorageStream(),
      builder: (context, val, _) {
        return BlocBuilder<AuthenticationBloc, AuthenticationState>(
          buildWhen: (previous, current) => previous.formInfo != current.formInfo,
          builder: (context, state) {
            return state.formInfo == null
                ? Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ValueListenableBuilder<bool>(
                          valueListenable: _passwordVisible,
                          builder: (context, visible, child) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: !visible,
                                maxLength: 1000, // If the user is stupid
                                toolbarOptions: const ToolbarOptions(
                                  copy: true,
                                  cut: true,
                                  paste: true,
                                ),
                                autofillHints: const ['new-password'],
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  labelText: tr(
                                    'authentication.hints.new_password',
                                  ),
                                  counterText: '',
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      _passwordVisible.value = !visible;
                                    },
                                    icon: Icon(
                                      visible
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  value ??= '';
                                  if (!isLength(value, 8)) {
                                    return 'Your password must be at '
                                        'least 8 characters long';
                                  }
                                  if (!matches(value, r'[#?!@$%^&*-]') ||
                                      !matches(value, '[A-Z]') ||
                                      !matches(value, '[a-z]')) {
                                    return 'Your password must contain at '
                                        'least one special character, '
                                        'one lower case letter and '
                                        'one capital letter.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _submit(
                                  _formKey,
                                  context,
                                ),
                              ),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        BlocBuilder<AuthenticationBloc, AuthenticationState>(
                          buildWhen: (previous, current) =>
                              previous.formInfo != current.formInfo,
                          builder: (context, state) {
                            final result = state.formInfo != null
                                ? jsonDecode(state.formInfo ?? '')
                                    as Map<String, dynamic>
                                : null;
                            return Visibility(
                              visible: state.formInfo != null,
                              child:
                                  authenticationMessages[result?['code'].toString()]
                                          ?.call(
                                        context,
                                      ) ??
                                      const Center(),
                            );
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        ElevatedButton(
                          onPressed: !state.processing
                              ? () => _submit(
                                    _formKey,
                                    context,
                                  )
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              tr('authentication.change_password'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      Logger.info(state.formInfo);
                      final formInfo = state.formInfo != null
                          ? jsonDecode(state.formInfo ?? '') as Map<String, dynamic>
                          : null;

                      Map<String, dynamic>? success, error;
                      if (formInfo?.containsKey('success') ?? false) {
                        success = formInfo?['success'] as Map<String, dynamic>;
                      } else if (formInfo?.containsKey('error') ?? false) {
                        error = formInfo?['error'] as Map<String, dynamic>;
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          authenticationMessages["""
${error != null ? error['code'].toString() : success?['code'].toString()}"""]
                                  ?.call(
                                context,
                              ) ??
                              const Center(),
                          const Padding(padding: EdgeInsets.all(10)),
                          ElevatedButton(
                            onPressed: () {
                              window.location.href = '/';
                            },
                            child: Text(tr('authentication.login')),
                          ),
                        ],
                      );
                    },
                  );
          },
        );
      }
    );
    return widget.createElement();
  }
}
