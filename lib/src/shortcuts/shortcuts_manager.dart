import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// A ShortcutManager that logs all keys that it handles.
class LoggingShortcutManager extends ShortcutManager {
  final _log = Logger('LoggingShortcutManager');

  @override
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    final KeyEventResult result = super.handleKeypress(context, event);

    if (result == KeyEventResult.handled) {
      _log.info('''Handled shortcut
Shortcut: $event
Context: $context
      ''');
    }

    return result;
  }
}

/// An ActionDispatcher that logs all the actions that it invokes.
class LoggingActionDispatcher extends ActionDispatcher {
  final _log = Logger('LoggingActionDispatcher');

  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    _log.info('''
Action invoked:
Action: $action($intent)
From: $context
    ''');

    super.invokeAction(action, intent, context);

    return null;
  }
}
