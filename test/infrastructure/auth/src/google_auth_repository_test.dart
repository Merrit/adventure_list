// import 'package:flutter_test/flutter_test.dart';
// import 'package:googleapis_auth/src/auth_http_utils.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:adventure_list/infrastructure/auth/src/google_auth_repository.dart';
// import 'package:adventure_list/infrastructure/preferences/preferences_repository.dart';

// class MockPreferencesRepository extends Mock implements PreferencesRepository {}

// const mockCredentials =
//     '{"accessToken":{"type":"Bearer","data":"ya29.a0ARrdaM_SAxWzFBiheYvVuQP4gWuc5zKF2xA7NkRmkIPQ7JY8tST1Z6uyaA7xAVTx_Al1lwLLnylbvLey3b3LB9KfjN75AQ7pYzp1BsYXyOJ4TO8KsF-BdMTW7tQT2jI6QN1oQg--ojs5UQ0w_2lXbcwm8QAa","expiry":"2021-08-29T18:59:17.457932Z"},"refreshToken":"1//04U5CTIADUdXoCgYIARAAGAQSNwF-L9Irpy6uMAoqJb00ufprtMz7UmHRmI87k3e_A5twukglGEIxLue-Vvv1BtfWBRpKsOW1PLg","idToken":null,"scopes":["https://www.googleapis.com/auth/calendar"]}';

// Future<void> _authPromptCallback(String url) async {}
// void main() {
//   MockPreferencesRepository _prefs = MockPreferencesRepository();

//   setUp(() {
//     _prefs = MockPreferencesRepository();
//   });

//   void saveValidCredentials() {
//     when(() => _prefs.getString('credentials')).thenReturn(mockCredentials);
//     when(() => _prefs.setString(any(), any())).thenAnswer(
//       (_) => Future.value(true),
//     );
//   }

//   test('Returns an auth client', () async {
//     saveValidCredentials();
//     // TODO: Mock GoogleAuthRepository's calendarApi calls.
//     final client = await GoogleAuthRepository(_prefs).authenticatedClient();
//     expect(client.runtimeType, AutoRefreshingClient);
//   });
// }
