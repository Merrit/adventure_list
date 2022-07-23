import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:self_updater/self_updater.dart';

import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/login_page.dart';
import '../settings.dart';

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

/// Shown on non-mobile platforms, with larger screens.
class SettingsDialog extends StatelessWidget {
  const SettingsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const AlertDialog(
      // TODO: This padding.. should maybe be calculated?
      // Eg layoutbldr: maxWidth / 2    ?
      insetPadding: EdgeInsets.symmetric(horizontal: 300, vertical: 24),
      content: SettingsView(),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: double.maxFinite,
      width: double.maxFinite,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                _UpdateChannelTile(),
              ],
            ),
          ),
          const _SignOutButton(),
        ],
      ),
    );
  }
}

class _UpdateChannelTile extends StatelessWidget {
  const _UpdateChannelTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Center(child: Text('Update channel')),
      subtitle: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return Column(
            children: [
              ...UpdateChannel.values
                  .map((UpdateChannel channel) => SizedBox(
                        width: 150,
                        child: RadioListTile(
                          title: Text(channel.name.capitalized()),
                          value: channel,
                          groupValue: state.updateChannel,
                          onChanged: (UpdateChannel? value) {
                            settingsCubit.setUpdateChannel(value);
                          },
                        ),
                      ))
                  .toList(),
            ],
          );
        },
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
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
      child: const Text('Sign Out'),
    );
  }
}
