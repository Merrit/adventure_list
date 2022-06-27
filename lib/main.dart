import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'src/app.dart';
import 'src/authentication/authentication.dart';
import 'src/logs/logs.dart';
import 'src/storage/storage_service.dart';

void main() async {
  initializeLogger();

  final storageService = await StorageService.initialize();

  final authenticationCubit = await AuthenticationCubit.initialize(
    googleAuth: GoogleAuth(),
    storageService: storageService,
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => authenticationCubit,
        ),
      ],
      child: const App(),
    ),
  );
}
