import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../storage/storage_service.dart';
import '../google_auth.dart';

part 'authentication_state.dart';

late final AuthenticationCubit authCubit;

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final GoogleAuth _googleAuth;
  final StorageService _storageService;

  AuthenticationCubit._(
    this._googleAuth,
    this._storageService, {
    required AuthenticationState initialState,
  }) : super(initialState) {
    authCubit = this;
  }

  static Future<AuthenticationCubit> initialize({
    required GoogleAuth googleAuth,
    required StorageService storageService,
  }) async {
    final String? savedCredentials = await storageService.getValue(
      'accessCredentials',
    );

    AccessCredentials? credentials;
    if (savedCredentials != null) {
      credentials = AccessCredentials.fromJson(jsonDecode(savedCredentials));
      assert(!credentials.accessToken.hasExpired);
    }

    return AuthenticationCubit._(
      googleAuth,
      storageService,
      initialState: AuthenticationState(
        accessCredentials: credentials,
        signedIn: (credentials != null),
      ),
    );
  }

  Future<void> login() async {
    assert(!state.signedIn);

    final accessCredentials = await _googleAuth.login();
    if (accessCredentials == null) return;

    emit(state.copyWith(
      accessCredentials: accessCredentials,
      signedIn: true,
    ));

    await _storageService.saveValue(
      key: 'accessCredentials',
      value: jsonEncode(accessCredentials.toJson()),
    );
  }
}
