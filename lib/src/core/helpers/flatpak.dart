import 'dart:io';

/// True if the application is running inside a Flatpak container.
final bool runningInFlatpak = Platform.environment.containsKey('FLATPAK_ID');
