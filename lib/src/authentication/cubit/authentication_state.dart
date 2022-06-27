part of 'authentication_cubit.dart';

class AuthenticationState extends Equatable {
  final AccessCredentials? accessCredentials;
  final bool signedIn;

  const AuthenticationState({
    required this.accessCredentials,
    required this.signedIn,
  });

  @override
  List<Object?> get props => [accessCredentials, signedIn];

  AuthenticationState copyWith({
    AccessCredentials? accessCredentials,
    bool? signedIn,
  }) {
    return AuthenticationState(
      accessCredentials: accessCredentials ?? this.accessCredentials,
      signedIn: signedIn ?? this.signedIn,
    );
  }
}
