part of 'authentication_bloc.dart';

/// Event class for the [AuthenticationBloc].
abstract class AuthenticationEvent extends Equatable {
  /// Default constructor.
  const AuthenticationEvent();

  @override
  List<Object> get props => [];
}

/// [AuthenticationEvent] called on any [AuthenticationStatus] change.
class AuthStatusChanged extends AuthenticationEvent {
  /// Default constructor.
  const AuthStatusChanged(this.status);

  /// Updated status
  final AuthenticationStatus status;

  @override
  List<Object> get props => [status];
}

/// [AuthenticationEvent] called when application starts
class AuthFromStorage extends AuthenticationEvent {}

/// [AuthenticationEvent] called when login is requested, takes
/// two [String] username and password as parameters.
class AuthLoginRequested extends AuthenticationEvent {
  /// Default constructor.
  const AuthLoginRequested(this.email, this.password);

  /// Email of the user attempting to log in.
  final String email;

  /// Password of the user attempting to log in.
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// [AuthenticationEvent] called when user sign up is requested, takes
/// two [String] username and password as parameters.
class AuthSignupRequested extends AuthenticationEvent {
  /// Default constructor.
  const AuthSignupRequested(this.email, this.password);

  /// Email of the user attempting to sign up.
  final String email;

  /// Password of the user attempting to sign up.
  final String password;

  @override
  List<Object> get props => [email, password];
}

/// [AuthenticationEvent] called to attempt sending an email verification link.
class AuthResendVerifRequested extends AuthenticationEvent {
  /// Default constructor.
  const AuthResendVerifRequested(this.email);

  /// Email of the user.
  final String email;

  @override
  List<Object> get props => [email];
}

/// [AuthenticationEvent] called to attempt sending an email verification link.
class AuthVerifyEmail extends AuthenticationEvent {
  /// Default constructor.
  const AuthVerifyEmail(this.base64User, this.token);

  /// Email of the user encoded in base64.
  final String base64User;

  /// Verification token
  final String token;

  @override
  List<Object> get props => [base64User, token];
}

/// [AuthenticationEvent] called to send a reset link for
/// the [email] account's password.
class AuthForgotPasswordRequested extends AuthenticationEvent {
  /// Default constructor.
  const AuthForgotPasswordRequested(this.email);

  /// Email of the user.
  final String email;

  @override
  List<Object> get props => [email];
}

/// [AuthenticationEvent] called to attempt sending an email verification link.
class AuthChangePassword extends AuthenticationEvent {
  /// Default constructor.
  const AuthChangePassword(this.base64User, this.password, this.token);

  /// Email of the user encoded in base64.
  final String base64User;

  /// Verification token
  final String password;

  /// Verification token
  final String token;

  @override
  List<Object> get props => [base64User, token];
}

/// [AuthenticationEvent] called when the user has to me logged out.
class AuthLogoutRequested extends AuthenticationEvent {}

/// [AuthenticationEvent] called to hide the form error message.
class AuthHideError extends AuthenticationEvent {}
