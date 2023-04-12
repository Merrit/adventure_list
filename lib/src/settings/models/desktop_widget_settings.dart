import 'package:freezed_annotation/freezed_annotation.dart';

part 'desktop_widget_settings.freezed.dart';
part 'desktop_widget_settings.g.dart';

/// The settings related to pinning the app to the desktop as a widget.
@freezed
class DesktopWidgetSettings with _$DesktopWidgetSettings {
  const factory DesktopWidgetSettings({
    /// Whether the widget background should be transparent.
    required bool transparentBackground,
  }) = _DesktopWidgetSettings;

  factory DesktopWidgetSettings.initial() => const DesktopWidgetSettings(
        transparentBackground: true,
      );

  factory DesktopWidgetSettings.fromJson(Map<String, dynamic> json) =>
      _$DesktopWidgetSettingsFromJson(json);
}
