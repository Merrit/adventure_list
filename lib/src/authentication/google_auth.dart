import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const String windowsClientSecret =
      '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';
  static final ClientId windowsClientId = ClientId(
    windowsClientIdString,
    windowsClientSecret,
  );

  static const String androidClientDebugId =
      '478765689275-2qneu0pfdhm2m4ej0lqdv69rm96shsg4.apps.googleusercontent.com';

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
        return kDebugMode ? ClientId(androidClientDebugId) : ClientId('');
      default:
        return ClientId('', '');
    }
  }
}

class GoogleAuth {
  final _log = Logger('GoogleAuth');

  static final scopes = [CalendarApi.calendarScope];

  Future<AccessCredentials?> login() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return await _googleSignInAuth();
    } else {
      return await _googleApisAuth();
    }
  }

  ///
  Future<AccessCredentials?> _googleApisAuth() async {
    AutoRefreshingAuthClient? client;
    try {
      client = await clientViaUserConsent(
        GoogleAuthIds.clientId,
        scopes,
        launchAuthUrl,
      );
    } catch (e) {
      _log.warning('Unable to login: $e');
    }

    return client?.credentials;
  }

  ///
  Future<AccessCredentials?> _googleSignInAuth() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

    try {
      await googleSignIn.signIn();
    } on PlatformException catch (e) {
      _log.warning('Failed to sign in with google_sign_in: $e');
    }

    final client = await googleSignIn.authenticatedClient();
    final googleAuth = await googleSignIn.currentUser?.authentication;
    if (googleAuth == null) return null;
    if (googleAuth.accessToken == null) return null;

    return client?.credentials;
  }

  static Future<AuthClient> refreshAuthClient() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);
    await googleSignIn.signInSilently();
    final client = await googleSignIn.authenticatedClient();

    // assert(googleSignIn.currentUser != null);
    // final authHeaders = await googleSignIn.currentUser!.authHeaders;

    // // custom IOClient from below
    // final GoogleHttpClient client = GoogleHttpClient(authHeaders);
    return client!;
  }

  static Future<String?> refreshAccessToken() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(scopes: scopes);

    assert(googleSignIn.currentUser != null);
    final authHeaders = await googleSignIn.currentUser!.authHeaders;

    // custom IOClient from below
    final GoogleHttpClient client = GoogleHttpClient(authHeaders);

    print("Token Refresh");
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signInSilently();
    if (googleSignInAccount == null) return null;

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );
    // final authResult = await signInWithCredential(credential);

    return credential.accessToken;
    return googleSignInAuthentication.accessToken; // New refreshed token
  }

  Future<void> launchAuthUrl(String url) async {
    final authUrl = Uri.parse(url);
    if (await canLaunchUrl(authUrl)) launchUrl(authUrl);
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
