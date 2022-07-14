import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/login/login.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:validators/validators.dart';

/// Describes if the user is connected.
enum AuthenticationStatus {
  /// Status is not set or unknown.
  unknown,

  /// User is connected.
  authenticated,

  /// User is not connected.
  unauthenticated,
}

/// Map of all the error messages corresponding to error results
Map<String, Widget Function(BuildContext)> authenticationMessages = {
  'ServerUnreachable': (context) => const Text(
        '''
There seems to be an issue connecting to the memosync servers, please retry later.''',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
  'UserCreated': (context) => RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text:
                  'Your account has been created, verify your email and then ',
              style: TextStyle(color: Colors.green),
            ),
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.login));
                },
                child: const Text(
                  'log in',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      ),
  'UnqualifiedAddress': (context) => const Text(
        '''
Your email is not accessible, please use a valid email address.''',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
  'NoUserFound': (context) => const Text(
        'The username or password is incorrect',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
  'WrongPass': (context) => const Text(
        'The username or password is incorrect',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
  'ResetPasswordMaybeSent': (context) => const Text(
        '''
If a user is registered with this email, a reset link has been sent. Don't forget to check your spams.''',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green),
      ),
  'MalformedLink': (context) => const Text(
        '''
This link seems malformed, try asking for a link again.''',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.red),
      ),
  'PasswordChanged': (context) => const Text(
        '''
Password changed successfuly, you can now log in.''',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green),
      ),
  'VerifLinkMaybeSent': (context) => const Text(
        '''
If a user is registered with this email and it is not yet verified, a verification link has been sent. Don't forget to check your spams.''',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green),
      ),
  'UserAlreadyExists': (context) => RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'A user with this email already exists, ',
              style: TextStyle(color: Colors.red),
            ),
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.login));
                },
                child: const Text(
                  'try logging in',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      ),
  'VerifEmail': (context) => RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.resendVerifEmail));
                },
                child: const Text(
                  'Verify your email address',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
            const TextSpan(
              text:
                  """before trying to log in\n(don't forget to check your spam folder)""",
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
  'OK': (context) => RichText(
        // TODO(me): Need to change that to verifSent or smthg
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            const TextSpan(
              text: 'Verification email sent, check your emails and ',
              style: TextStyle(color: Colors.red),
            ),
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.login));
                },
                child: const Text(
                  'log in',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      ),
};

/// Repository used to handle user connection.
class AuthenticationRepository {
  final _controller = StreamController<AuthenticationStatus>();

  final _authBaseUri = Uri(
    scheme: 'https',
    host: 'auth.memosync.net',
  );
  final _authDio = Dio();

  /// Stream updated each time the [AuthenticationStatus] changes.
  Stream<AuthenticationStatus> get status async* {
    await Future<void>.delayed(const Duration(seconds: 1));
    yield AuthenticationStatus.unknown;
    yield* _controller.stream;
  }

  /// Checks if the user [email] can connect to the backend
  /// using the [accessToken]
  Future<bool> canConnect({
    required String email,
    required String accessToken,
  }) async {
    final result = <String, dynamic>{};
    await _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'newToken',
        ),
        options: Options(
          headers: <String, dynamic>{'Authorization': 'Bearer $accessToken'},
        ),
      ),
      result,
    );
    return result.keys.contains('success');
  }

  /// Try to log the user in with [email] and [password] and stores the user.
  Future<Map<String, dynamic>> logIn({
    required String email,
    required String password,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'login',
        ),
        data: {
          'email': email,
          'password': _hashPassword(password),
        },
      ),
      result,
    );
  }

  /// Try to refresh the accessToken with [refreshToken].
  Future<Map<String, dynamic>> refreshToken({
    required String refreshToken,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'newToken',
        ),
        data: {
          'token': refreshToken,
        },
      ),
      result,
    );
  }

  /// Try to register the user
  /// with [email] and [password].
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'signup',
        ),
        data: {
          'email': email,
          'password': _hashPassword(password),
        },
      ),
      result,
    );
  }

  /// Try to resend the verification email the account with the [email] username
  Future<Map<String, dynamic>> resendVerifEmail({
    required String email,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'resendVerif',
        ),
        data: {
          'email': email,
        },
      ),
      result,
    );
  }

  /// Try to verify [user] with [token]
  Future<Map<String, dynamic>> verifyEmail({
    required String user,
    required String token,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      // TODO(me): migrate to post ?
      () => _authDio.getUri<String>(
        _authBaseUri.replace(
          path: 'verifEmail',
          queryParameters: <String, dynamic>{'user': user, 'token': token},
        ),
      ),
      result,
    );
  }

  /// Try to resend the verification email the account with the [email] username
  Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'forgotPassword',
        ),
        data: {
          'email': email,
        },
      ),
      result,
    );
  }

  /// Try to change [user]'s password with [password] using [token]
  Future<Map<String, dynamic>> changePassword({
    required String user,
    required String password,
    required String token,
  }) async {
    final result = <String, dynamic>{};
    return _dioCall<String>(
      () => _authDio.postUri<String>(
        _authBaseUri.replace(
          path: 'changePassword',
        ),
        data: {
          'user': user,
          'password': _hashPassword(password),
          'resetToken': token,
        },
      ),
      result,
    );
  }

  /// Close [_controller] on dispose.
  void dispose() => _controller.close();

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  Future<Map<String, dynamic>> _dioCall<T>(
    Future<Response<T>> Function() fetch,
    Map<String, dynamic> result,
  ) async {
    try {
      final response = await fetch();
      unawaited(Logger.info(response.data.toString()));
      if (response.data != null && isJSON(response.data)) {
        result['success'] = jsonDecode(response.data! as String);
      } else {
        result['error'] = {'code': 'ResponseNotAJSON'};
      }
    } on DioError catch (e) {
      if (e.response?.data != null) {
        unawaited(Logger.error(e.response?.data.toString()));
        result['error'] = jsonDecode(e.response?.data as String);
      } else {
        unawaited(Logger.errorFromException(e));
        result['error'] = {'code': 'ServerUnreachable'};
      }
    }
    return result;
  }
}
