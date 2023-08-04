import 'dart:convert';
import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';

import 'package:url_launcher/url_launcher.dart';

import '../logs/logging_manager.dart';
import '../storage/storage_repository.dart';

abstract class GoogleAuthIds {
  static const String linuxClientIdString =
      '478765689275-iobtsda2bcjl8ol9v51k4pi75abud639.apps.googleusercontent.com';
  static const String linuxClientSecret = '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';
  static final ClientId linuxClientId = ClientId(
    linuxClientIdString,
    linuxClientSecret,
  );

  static const String windowsClientIdString =
      '478765689275-vlsnua919pmsrh27gtgut52grv798goi.apps.googleusercontent.com';
  static const String windowsClientSecret = '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';
  static final ClientId windowsClientId = ClientId(
    windowsClientIdString,
    windowsClientSecret,
  );

  static const String androidClientIdString =
      '478765689275-2qneu0pfdhm2m4ej0lqdv69rm96shsg4.apps.googleusercontent.com';
  static final ClientId androidClientId = ClientId(androidClientIdString);

  static const String webClientId =
      '478765689275-553m3rlsl1j7lgb9dpqsqtajldr05b7d.apps.googleusercontent.com';
  static const String webClientSecret = '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';

  static ClientId get clientId {
    if (kIsWeb) {
      //
      return ClientId('');
    }

    switch (Platform.operatingSystem) {
      case 'linux':
        return linuxClientId;
      case 'windows':
        return windowsClientId;
      case 'android':
        return androidClientId;
      default:
        return ClientId('', '');
    }
  }
}

class GoogleAuth {
  final StorageRepository _storageRepository;

  const GoogleAuth(
    this._storageRepository,
  );

  static final scopes = [CalendarApi.calendarScope];

  /// Returns an `AuthClient` that can be used to make authenticated requests
  /// if the user is signed in, or `null` if the user is not signed in.
  Future<AuthClient?> getAuthClient() async {
    final credentials = await _storageRepository.get('accessCredentials');
    if (credentials == null) return null;

    final accessCredentials = AccessCredentials.fromJson(
      json.decode(credentials),
    );

    AuthClient? client;
    // `google_sign_in` can't get us a refresh token, so.
    if (accessCredentials.refreshToken != null) {
      client = autoRefreshingClient(
        GoogleAuthIds.clientId,
        accessCredentials,
        Client(),
      );
    } else {
      client = await refreshAuthClient();
    }

    return client;
  }

  Future<AccessCredentials?> signin() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return await _googleSignInAuth();
    } else {
      return await _googleApisAuth();
    }
  }

  /// Authenticates via the `googleapis_auth` package.
  ///
  /// Supports all platforms, but is not as stable or nice to use as the
  /// `google_sign_in` package.
  Future<AccessCredentials?> _googleApisAuth() async {
    log.i('Signing in via googleapis_auth...');
    AutoRefreshingAuthClient? client;
    try {
      client = await clientViaUserConsent(
        GoogleAuthIds.clientId,
        scopes,
        launchAuthUrl,
      );
    } catch (e) {
      log.w('Unable to sign in: $e');
    }

    return client?.credentials;
  }

  /// Authenticates via the `google_sign_in` package.
  ///
  /// Supports Android, iOS & Web.
  Future<AccessCredentials?> _googleSignInAuth() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

    try {
      await googleSignIn.signIn();
    } on PlatformException catch (e) {
      log.w('Failed to sign in with google_sign_in: $e');
      return null;
    }

    final AuthClient? client;
    try {
      client = await googleSignIn.authenticatedClient();
    } catch (e) {
      log.w('Unable to get AuthClient: $e');
      return null;
    }

    final googleAuth = await googleSignIn.currentUser?.authentication;
    if (googleAuth == null) return null;
    if (googleAuth.accessToken == null) return null;

    return client?.credentials;
  }

  /// google_sign_in doesn't provide us with a refresh token, so this is a
  /// workaround to refresh authentication for platforms that use google_sign_in
  Future<AuthClient?> refreshAuthClient() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);
    final GoogleSignInAccount? googleSignInAccount = await googleSignIn.signInSilently();

    if (googleSignInAccount == null) await signin();

    final AuthClient? client = await googleSignIn.authenticatedClient();

    return client;
  }

  Future<void> launchAuthUrl(String url) async {
    final authUrl = Uri.parse(url);
    try {
      log.i('Launching auth url: $authUrl');
      await launchUrl(authUrl);
    } catch (e) {
      log.e('Could not launch auth url: $authUrl');
    }
  }

  Future<void> signOut() async {
    // Specific signout only seems needed for the google_sign_in package.
    if (!Platform.isAndroid) return;

    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

    await googleSignIn.signOut();
  }
}

class GoogleHttpClient extends IOClient {
  final Map<String, String> _headers;

  GoogleHttpClient(this._headers);

  @override
  Future<IOStreamedResponse> send(BaseRequest request) =>
      super.send(request..headers.addAll(_headers));
}
