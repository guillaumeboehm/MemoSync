import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_memosync/src/authentication/repositories/authentication.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:flutter_memosync/src/services/models/models.dart';
import 'package:flutter_memosync/src/services/repositories/user.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

/// Bloc handling the authentication process.
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  /// Default constructor requiering the [AuthenticationRepository] for status
  /// change, and the [UserRepository].
  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
    required UserRepository userRepository,
  })  : _authenticationRepository = authenticationRepository,
        _userRepository = userRepository,
        super(const AuthenticationState.unknown()) {
    Logger.info('AuthBloc constructor');
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthFromStorage>(_onAuthFromStorage);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthSignupRequested>(_onAuthSignupRequested);
    on<AuthResendVerifRequested>(_onAuthResendVerifRequested);
    on<AuthVerifyEmail>(_onAuthVerifyEmail);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthChangePassword>(_onAuthChangePassword);
    on<AuthHideError>(_onAuthHideError);
    _authenticationStatusSubscription = _authenticationRepository.status.listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  final AuthenticationRepository _authenticationRepository;
  final UserRepository _userRepository;
  late StreamSubscription<AuthenticationStatus>
      _authenticationStatusSubscription;

  @override
  Future<void> close() {
    Logger.info('AuthBloc closed');
    _authenticationStatusSubscription.cancel();
    _authenticationRepository.dispose();
    return super.close();
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) async {
    switch (event.status) {
      case AuthenticationStatus.unauthenticated:
        return emit(const AuthenticationState.unauthenticated());
      case AuthenticationStatus.authenticated:
        await _tryGetUser().then(
          (UserObject? user) {
            return emit(
              user == null
                  ? const AuthenticationState.unauthenticated()
                  : AuthenticationState.authenticated(
                      user.email,
                      user.accessToken,
                    ),
            );
          },
        );
        break;
      case AuthenticationStatus.unknown:
        return emit(const AuthenticationState.unknown());
    }
  }

  Future<void> _onAuthFromStorage(
    AuthFromStorage event,
    Emitter<AuthenticationState> emit,
  ) async {
    await Logger.info('Look for stored credentials');
    await _tryGetUser().then(
      (UserObject? user) async {
        if (user != null) {
          await Logger.info(
            'Check for stored creds validity with ${user.refreshToken}',
          );
          final accessToken = await _canConnect(
            email: user.email,
            accessToken: user.accessToken,
            refreshToken: user.refreshToken,
          );

          if (accessToken == null) {
            user = null;
          } else {
            user.accessToken = accessToken;
          }
        }
        unawaited(Logger.info('AUTH FROM STORAGE user: $user'));
        // ignore: lines_longer_than_80_chars
        // TODO(me): auth after accessToken expiration doesn't seem to connect even tho the new token is pulled and saved
        emit(
          user == null
              ? const AuthenticationState.unauthenticated()
              : AuthenticationState.authenticated(
                  user.email,
                  user.accessToken,
                ),
        );
      },
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.unauthenticated());
    await _removeUser();
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.processing());
    final result = await _authenticationRepository.logIn(
      email: event.email,
      password: event.password,
    );
    if (result['error'] == null) {
      final data = result['success'] as Map<String, dynamic>;
      await Logger.info(result.toString());
      try {
        await _userRepository.saveUser(
          email: event.email,
          accessToken: data['accessToken']! as String,
          refreshToken: data['refreshToken']! as String,
        );
        emit(
          AuthenticationState.authenticated(
            event.email,
            data['accessToken']! as String,
          ),
        );
      } catch (e) {
        await Logger.error(e.toString());
        emit(
          AuthenticationState.formInfo(
            jsonEncode({
              'error': {'code': 'TokenMissing'}
            }),
          ),
        );
      }
    } else {
      emit(
        AuthenticationState.formInfo(jsonEncode(result)),
      );
    }
  }

  Future<void> _onAuthSignupRequested(
    AuthSignupRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.processing());
    final result = await _authenticationRepository.signUp(
      email: event.email,
      password: event.password,
    );
    emit(AuthenticationState.signedUp(event.email, jsonEncode(result)));
  }

  Future<void> _onAuthResendVerifRequested(
    AuthResendVerifRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.processing());
    emit(
      AuthenticationState.formInfo(
        jsonEncode({
          'success': {'code': 'VerifLinkMaybeSent'}
        }),
      ),
    );
    final result = await _authenticationRepository.resendVerifEmail(
      email: event.email,
    );
    unawaited(Logger.info(result.toString()));
    // emit(AuthenticationState.formInfo(jsonEncode(result)));
  }

  Future<void> _onAuthVerifyEmail(
    AuthVerifyEmail event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.processing());
    final result = await _authenticationRepository.verifyEmail(
      user: event.base64User,
      token: event.token,
    );
    unawaited(Logger.info(result.toString()));
    emit(AuthenticationState.formInfo(jsonEncode(result)));
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.processing());
    emit(
      AuthenticationState.formInfo(
        jsonEncode({
          'success': {'code': 'ResetPasswordMaybeSent'}
        }),
      ),
    );
    final result = await _authenticationRepository.forgotPassword(
      email: event.email,
    );
    unawaited(Logger.info(result.toString()));
  }

  Future<void> _onAuthChangePassword(
    AuthChangePassword event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.processing());
    final result = await _authenticationRepository.changePassword(
      user: event.base64User,
      password: event.password,
      token: event.token,
    );
    unawaited(Logger.info(result.toString()));
    emit(AuthenticationState.formInfo(jsonEncode(result)));
  }

  Future<void> _onAuthHideError(
    AuthHideError event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const AuthenticationState.hideFormInfo());
  }

  Future<UserObject?> _tryGetUser() async {
    try {
      return await _userRepository.getUser();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _canConnect({
    required String email,
    required String accessToken,
    required String refreshToken,
  }) async {
    if (!await _authenticationRepository.canConnect(
      email: email,
      accessToken: accessToken,
    )) {
      return _refreshAccessToken(
        email: email,
        refreshToken: refreshToken,
      );
    }
    return accessToken;
  }

  Future<String?> _refreshAccessToken({
    required String email,
    required String refreshToken,
  }) async {
    try {
      return await _authenticationRepository
          .refreshToken(
        refreshToken: refreshToken,
      )
          .then<String?>((result) async {
        await Logger.info(result.toString());
        if (result.keys.contains('success')) {
          final data = result['success'] as Map<String, dynamic>?;
          if (data == null || data['accessToken'] == null) return null;

          await _userRepository.saveUser(
            accessToken: data['accessToken'] as String,
          );
          return data['accessToken'] as String;
        } else {
          return null;
        }
      });
    } on Exception catch (e) {
      await Logger.errorFromException(e);
      return null;
    }
  }

  Future<void> _removeUser() async {
    try {
      await _userRepository.removeUser();
    } catch (_) {}
  }
}
