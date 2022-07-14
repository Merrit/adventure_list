import 'package:flutter/material.dart';

import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/login_page.dart';

class SettingsPage extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OutlinedButton(
        onPressed: () async {
          final navigator = Navigator.of(context);

          await authCubit.logout();

          navigator.pushReplacementNamed(LoginPage.routeName);
        },
        child: const Text('Log Out'),
      ),
    );
  }
}
