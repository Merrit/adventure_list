import 'dart:io';

import 'package:home_widget/home_widget.dart';

/// Manages the Android home screen widget.
class HomeWidgetManager {
  /// Save data to the home screen widget and trigger an update.
  Future<void> updateHomeWidget<T>(String id, T data) async {
    if (!Platform.isAndroid) return;

    await HomeWidget.saveWidgetData<T>(id, data);
    await HomeWidget.updateWidget(
      name: 'HomeWidgetExampleProvider',
      iOSName: 'HomeWidgetExample',
    );
  }
}
