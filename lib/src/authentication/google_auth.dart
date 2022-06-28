import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logging/logging.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class GoogleAuthIds {
  static const String linuxClientId =
      '478765689275-iobtsda2bcjl8ol9v51k4pi75abud639.apps.googleusercontent.com';
  static const String linuxClientSecret = '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';

  static ClientId get clientId {
    if (kIsWeb) {
      //
      return ClientId('', '');
    }

    switch (Platform.operatingSystem) {
      case 'linux':
        return ClientId(linuxClientId, linuxClientSecret);
      default:
        return ClientId('', '');
    }
  }
}

class GoogleAuth {
  final _log = Logger('GoogleAuth');

  // final _clientId = ClientId(
  //   '478765689275-iobtsda2bcjl8ol9v51k4pi75abud639.apps.googleusercontent.com',
  //   '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',
  // );

  final _scopes = [CalendarApi.calendarScope];

  Future<AccessCredentials?> login() async {
    AutoRefreshingAuthClient? client;
    try {
      client = await clientViaUserConsent(
        GoogleAuthIds.clientId,
        _scopes,
        launchAuthUrl,
      );
    } catch (e) {
      _log.warning('Unable to login: $e');
    }

    return client?.credentials;
  }

  Future<void> launchAuthUrl(String url) async {
    final authUrl = Uri.parse(url);
    if (await canLaunchUrl(authUrl)) launchUrl(authUrl);
  }
}
