import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/cubit/app_cubit.dart';
import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/sign_in_page.dart';
import '../../core/core.dart';
import '../../home_widget/home_widget.dart';
import '../../theme/theme.dart';
import '../settings.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const SafeArea(
        child: _SettingsView(),
      ),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double horizontalPadding = 0;
        if (constraints.maxWidth > 600) {
          horizontalPadding = (constraints.maxWidth - 600) / 2;
        }

        const versionSection = _SectionCard(
          title: 'Version',
          children: [
            _CurrentVersionTile(),
            _UpdateTile(),
          ],
        );

        const appearanceSection = _SectionCard(
          title: 'Appearance',
          children: [
            _ThemeTile(),
          ],
        );

        const integrationSection = _SectionCard(
          title: 'Integration',
          children: [
            _CloseToTrayTile(),
            _CustomizeAndroidWidgetTile(),
          ],
        );

        const syncSection = _SectionCard(
          title: 'Sync',
          children: [
            _SignOutTile(),
          ],
        );

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          children: const [
            versionSection,
            appearanceSection,
            integrationSection,
            syncSection,
          ],
        );
      },
    );
  }
}

/// A card with a title and a list of tiles related to that section.
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    Key? key,
    required this.title,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// A tile that shows the current version of the app.
class _CurrentVersionTile extends StatelessWidget {
  const _CurrentVersionTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return ListTile(
          title: Text('Current version: ${state.runningVersion}'),
        );
      },
    );
  }
}

/// A tile that shows the latest version of the app, and a button to
/// open the download url in the browser (only on desktop).
///
/// If an update is available, a badge is shown on the tile to match the
/// badge on the Settings button in the side bar.
class _UpdateTile extends StatelessWidget {
  const _UpdateTile();

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        kIsWeb) {
      return const SizedBox();
    }

    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.updateAvailable) {
          return ListTile(
            title: badges.Badge(
              showBadge: state.showUpdateButton,
              position: badges.BadgePosition.topStart(),
              badgeStyle: const badges.BadgeStyle(
                badgeColor: Colors.lightBlue,
              ),
              child: Text('Update available: ${state.updateVersion}'),
            ),
            trailing: kIsWeb
                ? null
                : IconButton(
                    icon: const Icon(Icons.open_in_browser),
                    onPressed: () {
                      AppCubit.instance.launchURL(kWebsiteUrl);
                    },
                  ),
          );
        } else {
          return const ListTile(
            title: Text('Up to date'),
          );
        }
      },
    );
  }
}

/// A tile that shows the current theme, and a switch to toggle between
/// light and dark mode.
class _ThemeTile extends StatelessWidget {
  const _ThemeTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          value: state.theme == darkTheme,
          title: const Text('Dark mode'),
          secondary: const Icon(Icons.brightness_4),
          onChanged: (bool value) {
            settingsCubit
                .updateThemeMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        );
      },
    );
  }
}

class _CloseToTrayTile extends StatelessWidget {
  const _CloseToTrayTile();

  @override
  Widget build(BuildContext context) {
    if (!Platform.isLinux && !Platform.isWindows) return const SizedBox();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          title: const Text('Close to tray'),
          secondary: const Icon(Icons.bedtime),
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

class _SignOutTile extends StatelessWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthenticationCubit, AuthenticationState>(
      builder: (context, authState) {
        if (!authState.signedIn) {
          return const SizedBox.shrink();
        }

        return ListTile(
          title: const Text('Sign out'),
          leading: const Icon(Icons.logout),
          onTap: () => _showSignOutDialog(context),
        );
      },
    );
  }

  /// Shows a dialog to confirm signing out.
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const CircularProgressIndicator(),
                );

                await authCubit.signOut();
                navigator.pushReplacementNamed(SignInPage.routeName);
              },
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );
  }
}
