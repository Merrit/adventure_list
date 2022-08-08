import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:helpers/helpers.dart';
import 'package:self_updater/self_updater.dart';

import '../../app/cubit/app_cubit.dart';
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
    return LayoutBuilder(builder: (context, constraints) {
      return AlertDialog(
        contentPadding: const EdgeInsets.only(
          top: 20,
          left: 10,
          right: 10,
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: constraints.maxWidth / 8,
          vertical: 24,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Settings'),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close),
            )
          ],
        ),
        content: const SettingsView(),
      );
    });
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const updatesSection = [
      _VersionTile(),
      _UpdateChannelTile(),
    ];

    const troubleshootingSection = [
      _LogToFileWidget(),
    ];

    return SizedBox(
      height: double.maxFinite,
      width: 400,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: const [
                _SectionWidget(
                  title: 'Version and updates',
                  children: updatesSection,
                ),
                _SectionWidget(
                  title: 'Troubleshooting',
                  children: troubleshootingSection,
                ),
              ],
            ),
          ),
          const _SignOutButton(),
        ],
      ),
    );
  }
}

class _SectionWidget extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionWidget({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             Version and updates                            */
/* -------------------------------------------------------------------------- */

class _VersionTile extends StatelessWidget {
  const _VersionTile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Opacity(
          opacity: 0.6,
          child: ListTile(
            title: Text('Version ${state.appVersion}'),
            subtitle: (state.updateAvailable)
                ? Text('Update available: ${state.updateVersion}')
                : null,
          ),
        );
      },
    );
  }
}

class _UpdateChannelTile extends StatelessWidget {
  const _UpdateChannelTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return Column(
          children: [
            const ListTile(title: Text('Update channel')),
            ...UpdateChannel.values
                .map((UpdateChannel channel) => RadioListTile(
                      title: Text(channel.name.capitalized()),
                      value: channel,
                      groupValue: state.updateChannel,
                      onChanged: (UpdateChannel? value) async {
                        if (value == UpdateChannel.dev) {
                          await _showConfirmDevDialog(context);
                        } else {
                          settingsCubit.setUpdateChannel(value);
                        }
                      },
                    ))
                .toList(),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmDevDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('''
Development builds are untested and may (probably will) BREAK ALL THE THINGS and/or LOSE ALL YOUR DATA.

Please do not choose Dev unless you can accept these risks.'''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await settingsCubit.setUpdateChannel(UpdateChannel.dev);
              navigator.pop();
            },
            child: const Text('My middle name is "risk".'),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               Troubleshooting                              */
/* -------------------------------------------------------------------------- */

class _LogToFileWidget extends StatelessWidget {
  const _LogToFileWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          title: const Text('Save logs to disk'),
          value: state.logToFile,
          onChanged: (value) => settingsCubit.updateLogToFile(value),
        );
      },
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
