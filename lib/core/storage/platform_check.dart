import 'platform_check_io.dart'
    if (dart.library.js_interop) 'platform_check_web.dart'
    if (dart.library.html) 'platform_check_web.dart';

bool get isFlutterTest => isFlutterTestEnv;
