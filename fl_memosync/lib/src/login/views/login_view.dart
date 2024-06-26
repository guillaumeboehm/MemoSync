import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memosync/src/authentication/authentication.dart';
import 'package:memosync/src/login/login.dart';
import 'package:memosync/src/services/logger.dart';
import 'package:memosync/src/services/models/models.dart';
import 'package:memosync/src/services/storage/storage.dart';
import 'package:validators/validators.dart';

/// View for the user login
class LoginView extends StatefulWidget {
  /// Default constructor
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _passwordVisible = ValueNotifier<bool>(false);

  void _submit(
    GlobalKey<FormState> formKey,
    BuildContext context,
  ) {
    if (!context.read<AuthenticationBloc>().state.processing &&
        formKey.currentState!.validate()) {
      context.read<AuthenticationBloc>().add(
            AuthLoginRequested(
              _emailController.text,
              _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SettingsObject>(
        valueListenable: Storage.settingsStorageStream(),
        builder: (context, val, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              if (context.read<AuthenticationBloc>().state.signedUpEmail !=
                  null) {
                _emailController.text =
                    context.read<AuthenticationBloc>().state.signedUpEmail ??
                        '';
              }
              return Container(
                constraints: BoxConstraints.loose(
                  Size.fromWidth(constraints.maxWidth * 0.8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr('authentication.login'),
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
                              labelText: tr('authentication.hints.email'),
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
                            onFieldSubmitted: (_) => _submit(
                              _formKey,
                              context,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _passwordVisible,
                            builder: (context, visible, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _passwordController,
                                      obscureText: !visible,
                                      maxLength: 1000, // If the user is stupid
                                      toolbarOptions: const ToolbarOptions(
                                        copy: true,
                                        cut: true,
                                        paste: true,
                                      ),
                                      autofillHints: const ['current-password'],
                                      decoration: InputDecoration(
                                        border: const OutlineInputBorder(),
                                        labelText: tr(
                                          'authentication.hints.password',
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
                                      onFieldSubmitted: (_) => _submit(
                                        _formKey,
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
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
                                    ? () => _submit(
                                          _formKey,
                                          context,
                                        )
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: !state.processing
                                      ? Text(
                                          tr('authentication.login'),
                                          style: const TextStyle(fontSize: 20),
                                        )
                                      : const CircularProgressIndicator(),
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
                      onPressed: () => context.read<LoginBloc>().add(
                          const LoginChangeView(LoginViews.forgotPassword)),
                      child: Text(
                        tr('authentication.forgot_password'),
                        textAlign: TextAlign.center,
                      ),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5),
                    ),
                    TextButton(
                      onPressed: () => context.read<LoginBloc>().add(
                          const LoginChangeView(LoginViews.resendVerifEmail)),
                      child: Text(
                        tr('authentication.resend_verification'),
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
