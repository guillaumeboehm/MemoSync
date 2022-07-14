// ignore_for_file: public_member_api_docs
part of 'login_bloc.dart';

enum LoginViews {
  login,
  signup,
  forgotPassword,
  resendVerifEmail,
}

class LoginState extends Equatable {
  const LoginState({
    this.view = LoginViews.login,
  });
  LoginState.fromState(
    LoginState prevState, {
    LoginViews? view,
  }) : view = view ?? prevState.view;

  factory LoginState.changeView(LoginState prevState, LoginViews view) {
    return LoginState.fromState(
      prevState,
      view: view,
    );
  }

  final LoginViews view;

  @override
  List<Object> get props => [
        view,
      ];
}
