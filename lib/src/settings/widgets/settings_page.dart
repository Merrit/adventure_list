import 'dart:io';

import 'package:badges/badges.dart' as badges;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/locale_keys.g.dart';
import '../../app/cubit/app_cubit.dart';
import '../../authentication/cubit/authentication_cubit.dart';
import '../../authentication/sign_in_page.dart';
import '../../core/core.dart';
import '../../core/helpers/helpers.dart';
import '../../home_widget/home_widget.dart';
import '../../logs/logging_manager.dart';
import '../../theme/theme.dart';
import '../settings.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = '/settings';

  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.settings_settings.tr()),
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

        final appearanceSection = _SectionCard(
          title: LocaleKeys.settings_appearance_title.tr(),
          children: const [
            _ThemeTile(),
          ],
        );

        final integrationSection = _SectionCard(
          title: LocaleKeys.settings_integration_title.tr(),
          children: const [
            _AutostartTile(),
            _CloseToTrayTile(),
          ],
        );

        final widgetSection = _SectionCard(
          title: LocaleKeys.settings_widget_title.tr(),
          children: const [
            _CustomizeAndroidWidgetTile(),
            _CustomizeDesktopWidgetTile(),
          ],
        );

        final syncSection = _SectionCard(
          title: LocaleKeys.settings_sync_title.tr(),
          children: const [
            _SignOutTile(),
          ],
        );

        final troubleshootingSection = _SectionCard(
          title: LocaleKeys.settings_troubleshooting_title.tr(),
          children: const [
            _VerboseLoggingTile(),
          ],
        );

        final versionSection = _SectionCard(
          title: LocaleKeys.settings_version_title.tr(),
          children: const [
            _CurrentVersionTile(),
            _UpdateTile(),
          ],
        );

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          children: [
            appearanceSection,
            integrationSection,
            widgetSection,
            syncSection,
            troubleshootingSection,
            versionSection,
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
          title: Text(LocaleKeys.settings_appearance_darkMode.tr()),
          secondary: const Icon(Icons.brightness_4),
          onChanged: (bool value) {
            context
                .read<SettingsCubit>()
                .updateThemeMode(value ? ThemeMode.dark : ThemeMode.light);
          },
        );
      },
    );
  }
}

/// Shows whether the app is set to autostart, and a switch to toggle it.
///
/// Only available on Desktop platforms.
class _AutostartTile extends StatelessWidget {
  const _AutostartTile();

  @override
  Widget build(BuildContext context) {
    if (!defaultTargetPlatform.isDesktop) return const SizedBox();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          title: Row(
            children: [
              Text(LocaleKeys.settings_integration_autostart.tr()),
              const SizedBox(width: 8),
              Tooltip(
                message: LocaleKeys.settings_integration_autostartDescription.tr(),
                child: const Icon(Icons.info_outline),
              ),
            ],
          ),
          secondary: const Icon(Icons.autorenew),
          value: state.autostart,
          onChanged: (value) => context.read<SettingsCubit>().toggleAutostart(),
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
          title: Text(LocaleKeys.settings_integration_closeToTray.tr()),
          secondary: const Icon(Icons.bedtime),
          value: state.closeToTray,
          onChanged: (value) => context.read<SettingsCubit>().updateCloseToTray(value),
        );
      },
    );
  }
}

class _CustomizeAndroidWidgetTile extends StatelessWidget {
  const _CustomizeAndroidWidgetTile();

  @override
  Widget build(BuildContext context) {
    if (!defaultTargetPlatform.isAndroid) return const SizedBox();

    return ListTile(
      title: Text(LocaleKeys.settings_settings.tr()),
      trailing: const Icon(Icons.keyboard_arrow_right),
      onTap: () => Navigator.pushNamed(context, HomeWidgetConfigPage.routeName),
    );
  }
}

class _CustomizeDesktopWidgetTile extends StatelessWidget {
  const _CustomizeDesktopWidgetTile();

  @override
  Widget build(BuildContext context) {
    if (!defaultTargetPlatform.isDesktop) return const SizedBox();

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        return SwitchListTile(
          title: Text(LocaleKeys.settings_widget_transparentBackground.tr()),
          secondary: const Icon(Icons.desktop_windows),
          value: state.desktopWidgetSettings.transparentBackground,
          onChanged: (value) => context.read<SettingsCubit>().updateDesktopWidgetSettings(
                state.desktopWidgetSettings.copyWith(
                  transparentBackground: value,
                ),
              ),
        );
      },
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
          title: Text(LocaleKeys.settings_sync_signOut.tr()),
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
          title: Text(LocaleKeys.settings_sync_signOut.tr()),
          content: Text(LocaleKeys.settings_sync_confirmSignOut.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocaleKeys.cancel.tr()),
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
              child: Text(LocaleKeys.settings_sync_signOut.tr()),
            ),
          ],
        );
      },
    );
  }
}

class _VerboseLoggingTile extends StatefulWidget {
  const _VerboseLoggingTile();

  @override
  State<_VerboseLoggingTile> createState() => _VerboseLoggingTileState();
}

class _VerboseLoggingTileState extends State<_VerboseLoggingTile> {
  bool isVerbose = LoggingManager.instance.verbose;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: const Icon(Icons.bug_report_outlined),
      title: const Text('Verbose logging'),
      value: isVerbose,
      onChanged: (value) async {
        setState(() => isVerbose = value);
        await LoggingManager.initialize(verbose: value);
      },
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
        String text = LocaleKeys.settings_version_currentVersion.tr(
          args: [state.runningVersion],
        );

        if (runningInFlatpak) {
          text += ' (Flatpak)';
        }

        return ListTile(
          title: Text(text),
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
              child: Text(
                LocaleKeys.settings_version_updateAvailable.tr(
                  args: [state.updateVersion ?? ''],
                ),
              ),
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
          return ListTile(
            title: Text(LocaleKeys.settings_version_upToDate.tr()),
          );
        }
      },
    );
  }
}
