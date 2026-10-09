import 'dart:io';

bool get isFlutterTestEnv {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}
