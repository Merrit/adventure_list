import 'dart:io';

/// True if the running environment is a unit test.
final bool testing = Platform.environment.containsKey('FLUTTER_TEST');
