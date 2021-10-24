import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';

import '../application/theme/cubit/theme_cubit.dart';
import 'home/home.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Layout(
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Todo List',
            theme: state.themeData,
            home: const HomePage(),
            routes: {
              HomePage.id: (_) => const HomePage(),
            },
          );
        },
      ),
    );
  }
}
