import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/app.dart';
import 'package:flutter_memosync/src/authentication/authentication.dart';
import 'package:flutter_memosync/src/login/login.dart';
import 'package:flutter_memosync/src/login/views/views.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/widgets/language_dialog.dart';
import 'package:flutter_memosync/src/widgets/route_404.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../services/storage/storage.dart';

/// The top level login page
class LoginPage extends StatefulWidget {
  /// Default constructor
  const LoginPage({super.key, this.args});

  /// Quite dirty, used for special routes such as verifEmail
  final Map<String, String>? args;

  /// Route to the login page
  static MaterialPageRoute<LoginPage> route({Map<String, String>? args}) =>
      MaterialPageRoute<LoginPage>(
        builder: (context) => LoginPage(args: args),
      );

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    Logger.info('Building login page.');
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: BlocConsumer<LoginBloc, LoginState>(
                  listener: (context, state) {},
                  buildWhen: (previous, current) =>
                      previous.view != LoginViews.login,
                  builder: (context, state) {
                    return InkWell(
                      onTap: () {
                        context
                            .read<LoginBloc>()
                            .add(const LoginChangeView(LoginViews.login));
                      },
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: SvgPicture.asset(
                              'assets/resources/logos/svg/Full_logo.svg',
                              height: 40,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 5),
                          ),
                          Flexible(
                            child: Text(
                              tr('general.app_title'),
                              overflow: TextOverflow.fade,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  showLanguageDialog(context).then((locale) {
                    if (locale != null) {
                      context.setLocale(locale);
                      setState(() {});

                      Storage.setSettings(
                        Storage.getSettings()
                          ..locale = tr(
                            'language.name.${locale.languageCode}',
                          ),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.language),
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: ColoredBox(
            color: Colors.blueGrey,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final view = Builder(
                      builder: (context) {
                        if (widget.args != null) {
                          switch (widget.args?['route']) {
                            case '/verifEmail':
                              return VerifyEmail(
                                args: widget.args!,
                              );
                            case '/changePassword':
                              return ChangePassword(
                                args: widget.args!,
                              );
                            default:
                              Navigator.of(context).pushAndRemoveUntil<void>(
                                route404,
                                (route) => false,
                              );
                          }
                        }
                        return BlocBuilder<LoginBloc, LoginState>(
                          buildWhen: (previous, current) {
                            return previous.view != current.view;
                          },
                          builder: (context, state) {
                            context
                                .read<AuthenticationBloc>()
                                .add(AuthHideError());
                            if (context
                                    .read<AuthenticationBloc>()
                                    .state
                                    .status ==
                                AuthenticationStatus.unknown) {
                              context
                                  .read<AuthenticationBloc>()
                                  .add(AuthFromStorage());
                              return const CircularProgressIndicator();
                            } else if (context
                                    .read<AuthenticationBloc>()
                                    .state
                                    .status ==
                                AuthenticationStatus.authenticated) {
                              return const CircularProgressIndicator();
                            } else {
                              switch (state.view) {
                                case LoginViews.login:
                                  return const LoginView();
                                case LoginViews.signup:
                                  return const SignupView();
                                case LoginViews.forgotPassword:
                                  return const ForgotPasswordView();
                                case LoginViews.resendVerifEmail:
                                  return const ResendVerifEmailView();
                              }
                            }
                          },
                        );
                      },
                    );
                    if (constraints.maxWidth < App.maxWidth) {
                      return Center(child: view);
                    } else {
                      const maxViewSize = Size(500, 700);
                      return Center(
                        child: Container(
                          alignment: Alignment.center,
                          constraints: BoxConstraints(
                            maxWidth: maxViewSize.width,
                            maxHeight: maxViewSize.height,
                          ),
                          color: Colors.blue,
                          child: view,
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
