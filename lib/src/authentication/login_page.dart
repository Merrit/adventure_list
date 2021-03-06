import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';

import '../tasks/tasks.dart';
import 'cubit/authentication_cubit.dart';

class LoginPage extends StatelessWidget {
  static const routeName = '/login_page';

  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthenticationCubit, AuthenticationState>(
        builder: (context, state) {
          return Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Signed in, inform user and proceed to load app.
              if (state.signedIn)
                Builder(builder: (context) {
                  Timer(const Duration(seconds: 2), () {
                    // TODO: window_manager -> focus window?
                    Navigator.pushReplacementNamed(
                      context,
                      TasksPage.routeName,
                    );
                  });

                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 30),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 100,
                        color: Colors.green,
                      ),
                    ),
                  );
                }),

              // Not signed in, prompt for authentication.
              Center(
                child: SignInButton(
                  Buttons.GoogleDark,
                  onPressed: () async {
                    await authCubit.login();

                    // if (state.signedIn) {
                    //   print('signed in!');
                    // } else {
                    //   print('sign in failed!');
                    // }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
