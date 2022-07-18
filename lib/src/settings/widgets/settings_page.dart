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

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      // TODO: This padding.. should maybe be calculated?
      // Eg layoutbldr: maxWidth / 2    ?
      insetPadding: EdgeInsets.symmetric(horizontal: 300, vertical: 24),
      child: SettingsView(),
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
          showDialog(
              context: context,
              builder: (context) {
                return const CircularProgressIndicator();
              });

          await authCubit.logout();
          navigator.pushReplacementNamed(LoginPage.routeName);
        },
        child: const Text('Log Out'),
      ),
    );
  }
}
