import 'dart:convert';
import 'dart:developer';

import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../../preferences/preferences_repository.dart';
import '../auth_repository.dart';
import 'google_secret.dart';

class GoogleAuthRepository implements AuthRepository {
  final _GoogleCredentialsRepository _credentialsRepository;

  GoogleAuthRepository(PreferencesRepository prefsRepository)
      : _credentialsRepository = _GoogleCredentialsRepository(prefsRepository);

  /// The permission scopes requested on the user's calendars.
  static const _scopes = [CalendarApi.calendarScope];

  bool? _authenticated;

  bool get isAuthenticated {
    if (_authenticated == null) {
      final credentials = _credentialsRepository.getSaved();
      _authenticated = (credentials == null) ? false : true;
    }
    return _authenticated!;
  }

  Future<bool> signIn({required Future<void> Function(String) callback}) async {
    _authClient = await _getAuthClientViaUser(callback);
    _authenticated = (_authClient == null) ? false : true;
    if (_authenticated!) _credentialsRepository.save(_authClient!.credentials);
    return _authenticated!;
  }

  auth.AuthClient? _authClient;

  /// Used when making authenticated calls to the user's Google Calendar.
  Future<auth.AuthClient?> authenticatedClient() async {
    if (_authClient != null) return _authClient!;
    auth.AccessCredentials? credentials = _credentialsRepository.getSaved();
    if (credentials == null) {
      return null; // No saved credentials, user will have to sign-in.
    } else {
      _authClient = auth.autoRefreshingClient(
        clientId,
        credentials,
        http.Client(),
      );
    }
    assert(_authClient != null);
    _authenticated = true;
    await _credentialsRepository.save(_authClient!.credentials);
    return _authClient!;
  }

  Future<auth.AuthClient?> _getAuthClientViaUser(
      Future<void> Function(String) callback) async {
    auth.AuthClient? client;
    try {
      client = await auth.clientViaUserConsent(
        clientId,
        _scopes,
        callback,
      );
    } on Exception catch (e) {
      log(
        'Issue getting authenticated client: $e',
        name: 'Get google auth client',
      );
    }
    return client;
  }

  void logOut() {
    _authClient = null;
    _authenticated = false;
    _credentialsRepository.removeCredentials();
  }
}

/// Caches google credentials locally so the user doesn't
/// have to re-authenticate every time.
class _GoogleCredentialsRepository {
  final PreferencesRepository _prefs;

  const _GoogleCredentialsRepository(this._prefs);

  auth.AccessCredentials? getSaved() {
    final json = _prefs.getString('credentials');
    if (json == null) return null;
    final credentialsMap = jsonDecode(json) as Map<String, dynamic>;
    return auth.AccessCredentials.fromJson(credentialsMap);
  }

  Future<void> save(auth.AccessCredentials credentials) async {
    final json = jsonEncode(credentials.toJson());
    _prefs.setString('credentials', json);
  }

  void removeCredentials() => _prefs.remove('credentials');
}
