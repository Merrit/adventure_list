import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../../logs/logging_manager.dart';
import '../../storage/storage_repository.dart';
import '../google_auth.dart';

part 'authentication_state.dart';
part 'authentication_cubit.freezed.dart';

late final AuthenticationCubit authCubit;

class AuthenticationCubit extends Cubit<AuthenticationState> {
  final GoogleAuth _googleAuth;

  AuthenticationCubit._(
    this._googleAuth, {
    required AuthenticationState initialState,
  }) : super(initialState) {
    authCubit = this;
  }

  static Future<AuthenticationCubit> initialize({
    required GoogleAuth googleAuth,
  }) async {
    final String? savedCredentials = await StorageRepository.instance.get(
      'accessCredentials',
    );

    AccessCredentials? credentials;
    if (savedCredentials != null) {
      credentials = AccessCredentials.fromJson(jsonDecode(savedCredentials));
    }

    return AuthenticationCubit._(
      googleAuth,
      initialState: AuthenticationState(
        accessCredentials: credentials,
        signedIn: (credentials != null),
      ),
    );
  }

  Future<void> signIn() async {
    assert(!state.signedIn);

    log.i('Signing in...');

    final accessCredentials = await _googleAuth.signin();
    if (accessCredentials == null) {
      log.w('Unable to sign in');
      return;
    } else {
      log.i('Signed in successfully.');
    }

    emit(state.copyWith(
      accessCredentials: accessCredentials,
      signedIn: true,
    ));

    await StorageRepository.instance.save(
      key: 'accessCredentials',
      value: jsonEncode(accessCredentials.toJson()),
    );
  }

  Future<void> signOut() async {
    await _googleAuth.signOut();
    await StorageRepository.instance.delete('accessCredentials');

    emit(state.copyWith(
      accessCredentials: null,
      signedIn: false,
    ));
  }
}
