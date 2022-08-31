import 'package:flutter/material.dart';

import '../logs/logs.dart';

/// A ShortcutManager that logs all keys that it handles.
class LoggingShortcutManager extends ShortcutManager {
  LoggingShortcutManager(
    Map<ShortcutActivator, Intent> shortcuts,
  ) : super(shortcuts: shortcuts);

  @override
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    final KeyEventResult result = super.handleKeypress(context, event);

    if (result == KeyEventResult.handled) {
      logger.i('''Handled shortcut
Shortcut: $event
Context: $context
      ''');
    }

    return result;
  }
}

/// An ActionDispatcher that logs all the actions that it invokes.
class LoggingActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    logger.i('''
Action invoked:
Action: $action($intent)
From: $context
    ''');

    super.invokeAction(action, intent, context);

    return null;
  }
}
