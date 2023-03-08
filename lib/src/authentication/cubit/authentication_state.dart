part of 'authentication_cubit.dart';

@freezed
class AuthenticationState with _$AuthenticationState {
  const factory AuthenticationState({
    required AccessCredentials? accessCredentials,
    required bool signedIn,
  }) = _AuthenticationState;
}
