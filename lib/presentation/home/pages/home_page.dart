import 'package:device_type/device_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/home/cubit/home_cubit.dart';
import '../../todo/pages/todo_view.dart';
import '../widgets/widgets.dart';

class HomePage extends StatelessWidget {
  static const id = 'home_page';

  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Center(
        child: BlocConsumer<HomeCubit, HomeState>(
          buildWhen: (previous, current) =>
              previous.authenticated != current.authenticated,
          listener: (context, state) {
            if (state.awaitingAuth) _promptForAuthentication(context);
            if (state.loading) _showLoadingModal(context);
          },
          builder: (context, state) {
            if (state.authenticated) {
              return const TodoView();
            } else {
              return const GoogleSignInButton();
            }
          },
        ),
      ),
      // Drawer is a column on non-phone devices.
      drawer: Device.isLargeFormFactor(context)
          ? null
          : const Drawer(child: CustomDrawer()),
    );
  }
}

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    Key? key,
  }) : super(key: key);

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool failed = false;

  Widget instructionsText = const Text(
    'A browser tab will open for you to '
    'sign in.\n\nReturn here when finished.',
  );

  Widget failureText = const Text(
    'There was an issue authenticating, please try again.',
    style: TextStyle(color: Colors.amber),
  );

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => const SignInDialog(),
        );
      },
      child: const Text('Sign in with Google'),
    );
  }
}

class SignInDialog extends StatefulWidget {
  const SignInDialog({Key? key}) : super(key: key);

  @override
  _SignInDialogState createState() => _SignInDialogState();
}

class _SignInDialogState extends State<SignInDialog> {
  bool failed = false;

  Widget instructionsText = const Text(
    'A browser tab will open for you to '
    'sign in.\n\nReturn here when finished.',
  );

  Widget failureText = const Text(
    'There was an issue authenticating, please try again.',
    style: TextStyle(color: Colors.amber),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: (failed) ? failureText : instructionsText,
      actions: [
        TextButton(
          onPressed: () => Navigator.pushReplacementNamed(context, HomePage.id),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final success = await homeCubit.signInGoogle();
            if (success) {
              // Navigator.pushReplacementNamed(context, HomePage.id);
            } else {
              setState(() => failed = true);
            }
          },
          child: Text((failed) ? 'Try again' : 'Continue'),
        ),
      ],
    );
  }
}

Future<void> _promptForAuthentication(BuildContext context) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        content: BlocListener<HomeCubit, HomeState>(
          listener: (context, state) {
            if (!state.awaitingAuth) Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              Text('Please authenticate'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

void _showLoadingModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          if (!state.loading) {
            Navigator.pushReplacementNamed(context, HomePage.id);
          }
          // if (!state.loading) Navigator.pop(context);
        },
        child: Stack(
          children: const [
            Center(
              child: CircularProgressIndicator(),
            ),
            ModalBarrier(dismissible: false),
          ],
        ),
      );
    },
  );
}
