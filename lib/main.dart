import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:home_widget/home_widget.dart';

import 'src/app.dart';
import 'src/authentication/authentication.dart';
import 'src/logs/logs.dart';
import 'src/storage/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerBackgroundCallback(backgroundCallback);
  initializeLogger();

  final storageService = await StorageService.initialize();

  final googleAuth = GoogleAuth();
  final authenticationCubit = await AuthenticationCubit.initialize(
    googleAuth: googleAuth,
    storageService: storageService,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: googleAuth),
        RepositoryProvider.value(value: storageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => authenticationCubit,
          ),
        ],
        child: const App(),
      ),
    ),
  );
}

// Called when Doing Background Work initiated from Widget
Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updatecounter') {
    int? _counter;
    await HomeWidget.getWidgetData<int>('_counter', defaultValue: 0)
        .then((int? value) {
      if (value == null) return;
      _counter = value;
      if (_counter != null) _counter = _counter! + 1;
    });
    await HomeWidget.saveWidgetData<int>('_counter', _counter);
    await HomeWidget.updateWidget(
        name: 'AppWidgetProvider', iOSName: 'AppWidgetProvider');
  }
}
