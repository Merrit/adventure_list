import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'application/home/cubit/home_cubit.dart';
import 'application/theme/cubit/theme_cubit.dart';
import 'infrastructure/auth/auth_repository.dart';
import 'infrastructure/preferences/preferences_repository.dart';
import 'presentation/app_widget.dart';

Future<void> main() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final prefsRepository = PreferencesRepository(sharedPreferences);

  final googleAuthRepository = AuthRepository.google(prefsRepository);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => HomeCubit(googleAuthRepository),
        ),
        BlocProvider(
          create: (context) => ThemeCubit(),
        ),
      ],
      child: const App(),
    ),
  );
}
