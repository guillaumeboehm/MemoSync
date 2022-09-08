import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/login/login.dart';
import 'package:flutter_memosync/src/services/storage/storage.dart';
import 'package:validators/validators.dart';

/// View for the user login
class ResendVerifEmailView extends StatefulWidget {
  /// Default constructor
  const ResendVerifEmailView({super.key});

  @override
  State<ResendVerifEmailView> createState() => _ResendVerifEmailViewState();
}

class _ResendVerifEmailViewState extends State<ResendVerifEmailView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  void _submit(
    GlobalKey<FormState> formKey,
    BuildContext context,
  ) {
    if (!context.read<AuthenticationBloc>().state.processing &&
        formKey.currentState!.validate()) {
      context.read<AuthenticationBloc>().add(
            AuthResendVerifRequested(
              _emailController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: Storage.settingsStorageStream(),
        builder: (context, val, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                constraints: BoxConstraints.loose(
                  Size.fromWidth(constraints.maxWidth * 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr('authentication.resend_verification'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                    ),
                    Form(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          TextFormField(
                            controller: _emailController,
                            autofillHints: const ['username'],
                            maxLength: 1000, // If the user is stupid
                            keyboardType: TextInputType.emailAddress,
                            toolbarOptions: const ToolbarOptions(
                              copy: true,
                              cut: true,
                              paste: true,
                            ),
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: tr('authentication.hints.email'),
                              counterText: '',
                            ),
                            validator: (value) {
                              if (!isEmail(value ?? '')) {
                                return tr(
                                  'authentication.form_validation.email_invalid',
                                );
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(_formKey, context),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          BlocBuilder<AuthenticationBloc, AuthenticationState>(
                            buildWhen: (previous, current) =>
                                previous.formInfo != current.formInfo,
                            builder: (context, state) {
                              final formInfo = state.formInfo != null
                                  ? jsonDecode(state.formInfo ?? '')
                                      as Map<String, dynamic>
                                  : null;
                              Map<String, dynamic>? success, error;
                              if (formInfo?.containsKey('success') ?? false) {
                                success = formInfo?['success']
                                    as Map<String, dynamic>;
                              } else if (formInfo?.containsKey('error') ??
                                  false) {
                                error =
                                    formInfo?['error'] as Map<String, dynamic>;
                              }
                              return Visibility(
                                visible: state.formInfo != null,
                                child: authenticationMessages[error != null
                                            ? error['code'].toString()
                                            : success?['code'].toString()]
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
                          BlocBuilder<AuthenticationBloc, AuthenticationState>(
                            buildWhen: (previous, current) =>
                                previous.processing != current.processing,
                            builder: (context, state) {
                              return ElevatedButton(
                                onPressed: !state.processing
                                    ? () => _submit(_formKey, context)
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Text(
                                    tr('authentication.resend_link'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                              );
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => context
                          .read<LoginBloc>()
                          .add(const LoginChangeView(LoginViews.login)),
                      child: Text(tr('authentication.login')),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    TextButton(
                      onPressed: () => context
                          .read<LoginBloc>()
                          .add(const LoginChangeView(LoginViews.signup)),
                      child: Text(
                        tr('authentication.create_account'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        });
  }
}
