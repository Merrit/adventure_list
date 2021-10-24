import '../preferences/preferences_repository.dart';
import 'src/google_auth_repository.dart';

abstract class AuthRepository {
  const AuthRepository();

  static GoogleAuthRepository google(PreferencesRepository prefsRepository) =>
      GoogleAuthRepository(prefsRepository);
}
