import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_memosync/src/login/login.dart';
import 'package:flutter_memosync/src/services/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:universal_io/io.dart';
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
  'ServerUnreachable': (context) => Text(
        tr('authentication.server_unreachable'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
  'UserCreated': (context) => RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: tr('authentication.user_created.0'),
              style: const TextStyle(color: Colors.green),
            ),
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.login));
                },
                child: Text(
                  tr('authentication.user_created.1'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ),
            TextSpan(
              text: tr('authentication.user_created.2'),
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
  'UnqualifiedAddress': (context) => Text(
        tr('authentication.unqualified_address'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
  'NoUserFound': (context) => Text(
        tr('authentication.username_or_password_incorrect'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
  'WrongPass': (context) => Text(
        tr('authentication.username_or_password_incorrect'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
  'ResetPasswordMaybeSent': (context) => Text(
        tr('authentication.reset_password_maybe_sent'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.green),
      ),
  'MalformedLink': (context) => Text(
        tr('authentication.malformed_link'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.red),
      ),
  'PasswordChanged': (context) => Text(
        tr('authentication.malformed_link'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.green),
      ),
  'VerifLinkMaybeSent': (context) => Text(
        tr('authentication.verification_link_sent'),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.green),
      ),
  'UserAlreadyExists': (context) => RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: tr('authentication.user_already_exists.0'),
              style: const TextStyle(color: Colors.red),
            ),
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.login));
                },
                child: Text(
                  tr('authentication.user_already_exists.1'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ),
            TextSpan(
              text: tr('authentication.user_already_exists.2'),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
  'VerifEmail': (context) => RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: tr('authentication.verify_email.0'),
              style: const TextStyle(color: Colors.red),
            ),
            WidgetSpan(
              child: TextButton(
                style: const ButtonStyle(alignment: Alignment.bottomCenter),
                onPressed: () {
                  context
                      .read<LoginBloc>()
                      .add(const LoginChangeView(LoginViews.resendVerifEmail));
                },
                child: Text(
                  tr('authentication.verify_email.1'),
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
            ),
            TextSpan(
              text: tr('authentication.verify_email.2'),
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
  // 'OK': (context) => RichText(
  //       // TODO(me): Need to change that to verifSent or smthg
  //       textAlign: TextAlign.center,
  //       text: TextSpan(
  //         children: [
  //           const TextSpan(
  //             text: 'Verification email sent, check your emails and ',
  //             style: TextStyle(color: Colors.red),
  //           ),
  //           WidgetSpan(
  //             child: TextButton(
  //               style: const ButtonStyle(alignment: Alignment.bottomCenter),
  //               onPressed: () {
  //                 context
  //                     .read<LoginBloc>()
  //                     .add(const LoginChangeView(LoginViews.login));
  //               },
  //               child: const Text(
  //                 'log in',
  //                 style: TextStyle(color: Colors.orange),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
};

/// Repository used to handle user connection.
class AuthenticationRepository {
  /// Default constructor
  AuthenticationRepository() {
    if (kDebugMode) {
      // Seems needed for some emulators
      (_authDio.httpClientAdapter as DefaultHttpClientAdapter)
          .onHttpClientCreate = (HttpClient client) {
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      };
    }
  }

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
