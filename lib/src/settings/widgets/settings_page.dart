import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/cubit/app_cubit.dart';
import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/sign_in_page.dart';
import '../../home_widget/home_widget.dart';
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
        contentPadding: const EdgeInsets.symmetric(vertical: 20),
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
    ];

    const integrationSection = [
      _CloseToTrayTile(),
      _CustomizeAndroidWidgetTile(),
    ];

    // const troubleshootingSection = [];

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
                  title: 'Integration',
                  children: integrationSection,
                ),
                // _SectionWidget(
                //   title: 'Troubleshooting',
                //   children: troubleshootingSection,
                // ),
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
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
      ],
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
          opacity: 0.8,
          child: ListTile(
            title: Row(
              children: [
                Text('Version ${state.appVersion}'),
                const SizedBox(width: 4),
                BlocBuilder<AppCubit, AppState>(
                  builder: (context, state) {
                    return Icon(
                      Icons.circle,
                      color: (state.updateAvailable)
                          ? Theme.of(context).colorScheme.secondary
                          : Colors.transparent,
                      size: 10,
                    );
                  },
                ),
              ],
            ),
            subtitle: (state.updateAvailable)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Update available: ${state.updateVersion}'),
                      Row(
                        children: const [
                          Text('Open download page'),
                          Icon(Icons.launch, size: 16),
                        ],
                      ),
                    ],
                  )
                : null,
            onTap: (state.updateAvailable)
                ? () => appCubit.launchAUrl(Uri.parse(
                      'https://github.com/Merrit/adventure_list/releases',
                    ))
                : null,
          ),
        );
      },
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                 Integration                                */
/* -------------------------------------------------------------------------- */

class _CloseToTrayTile extends StatelessWidget {
  const _CloseToTrayTile();

  @override
  Widget build(BuildContext context) {
    if (!Platform.isLinux && !Platform.isWindows) return const SizedBox();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          title: const Text('Close to tray'),
          value: state.closeToTray,
          onChanged: (value) => settingsCubit.updateCloseToTray(value),
        );
      },
    );
  }
}

class _CustomizeAndroidWidgetTile extends StatelessWidget {
  const _CustomizeAndroidWidgetTile();

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox();

    return ListTile(
      title: const Text('Android widget'),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => Navigator.pushNamed(context, HomeWidgetConfigPage.routeName),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                               Troubleshooting                              */
/* -------------------------------------------------------------------------- */

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

        await authCubit.signOut();
        navigator.pushReplacementNamed(SignInPage.routeName);
      },
      child: const Text('Sign Out'),
    );
  }
}
