import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'theme_state.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit()
      : super(
          ThemeState(
            brightness: Brightness.dark,
            // brightness: Preferences.instance.isDarkTheme
            //     ? Brightness.dark
            //     : Brightness.light,
          ),
        );

  // TODO: Uncomment and implement theme switch.
  /// Toggle between light theme and dark theme.
  // void toggleTheme({required bool isDark}) {
  //   final brightness = (isDark) ? Brightness.dark : Brightness.light;
  //   Preferences.instance.isDarkTheme = isDark;
  //   emit(state.copyWith(brightness: brightness));
  // }
}
