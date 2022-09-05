import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/login/login.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:validators/validators.dart';

/// View for the user sign up
class SignupView extends StatefulWidget {
  /// Default constructor
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
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
            AuthSignupRequested(
              _emailController.text,
              _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                tr('authentication.signup_title'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
              ),
              BlocBuilder<AuthenticationBloc, AuthenticationState>(
                buildWhen: (previous, current) =>
                    previous.processing != current.processing,
                builder: (context, state) {
                  return Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const ['username'],
                          maxLength: 1000, // If the user is stupid
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
                          onFieldSubmitted: (_) => _submit(_formKey, context),
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
                                    autofillHints: const ['new-password'],
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      labelText: tr(
                                        'authentication.hints.password',
                                      ),
                                      counterText: '',
                                      errorMaxLines: 3,
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
                                        return tr(
                                          '''
authentication.form_validation.password_too_short''',
                                        );
                                      }
                                      if (!matches(value, r'[#?!@$%^&*-]') ||
                                          !matches(value, '[A-Z]') ||
                                          !matches(value, '[a-z]')) {
                                        return tr(
                                          '''
authentication.form_validation.password_too_weak''',
                                        );
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) =>
                                        _submit(_formKey, context),
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
                              success =
                                  formInfo?['success'] as Map<String, dynamic>;
                            } else if (formInfo?.containsKey('error') ??
                                false) {
                              error =
                                  formInfo?['error'] as Map<String, dynamic>;
                            }
                            return Visibility(
                              visible: state.formInfo != null,
                              child: authenticationMessages["""
${error != null ? error['code'].toString() : success?['code'].toString()}"""]
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
                              ? () => _submit(_formKey, context)
                              : null,
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Text(
                              tr('authentication.signup'),
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
                  );
                },
              ),
              TextButton(
                onPressed: () => context
                    .read<LoginBloc>()
                    .add(const LoginChangeView(LoginViews.login)),
                child: Text(
                  tr('authentication.user_has_account'),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
