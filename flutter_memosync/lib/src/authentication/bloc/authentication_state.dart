part of 'authentication_bloc.dart';

/// State used for [AuthenticationState]
class AuthenticationState extends Equatable {
  const AuthenticationState._({
    this.status = AuthenticationStatus.unknown,
    this.processing = false,
    this.user,
    this.accessToken,
    this.formInfo,
    this.signedUpEmail,
  });

  /// Sets [this.status] to [AuthenticationStatus.unknown]
  /// and [this.user] to null.
  const AuthenticationState.unknown() : this._();

  /// Sets [this.status] to [AuthenticationStatus.authenticated]
  /// and [this.user] to [user]
  const AuthenticationState.authenticated(String user, String accessToken)
      : this._(
          status: AuthenticationStatus.authenticated,
          user: user,
          accessToken: accessToken,
          formInfo: null,
          processing: false,
        );

  /// Sets [this.status] to [AuthenticationStatus.unauthenticated]
  const AuthenticationState.unauthenticated()
      : this._(
          status: AuthenticationStatus.unauthenticated,
          processing: false,
        );

  /// Sets [this.status] to [AuthenticationStatus.unauthenticated]
  /// with the [formInfo] message
  const AuthenticationState.formInfo(String? formInfo)
      : this._(
          status: AuthenticationStatus.unauthenticated,
          formInfo: formInfo,
          processing: false,
        );

  /// Hides the form error message
  const AuthenticationState.hideFormInfo()
      : this._(
          status: AuthenticationStatus.unauthenticated,
          formInfo: null,
          processing: false,
        );

  /// Sets [this.processing] to true
  const AuthenticationState.processing()
      : this._(
          status: AuthenticationStatus.unauthenticated,
          processing: true,
        );

  /// Sets [this.signedUpEmail] to the last email successfully signed up
  const AuthenticationState.signedUp(String email, String? formInfo)
      : this._(
          status: AuthenticationStatus.unauthenticated,
          processing: false,
          formInfo: formInfo,
          signedUpEmail: email,
        );

  /// Authentication status.
  final AuthenticationStatus status;

  /// If a fetch or a storage action is happening
  final bool processing;

  /// User email
  final String? user;

  /// User's access token
  final String? accessToken;

  /// Last error from request
  final String? formInfo;

  /// Email from last successful signup
  final String? signedUpEmail;

  @override
  List<Object?> get props => [
        status,
        processing,
        user,
        accessToken,
        formInfo,
        signedUpEmail,
      ];
}
