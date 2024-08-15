import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

String getPlatformName() {
  return kIsWeb
      ? "Web"
      : switch (Platform) {
          _ when Platform.isAndroid => "Android",
          _ when Platform.isIOS => "IOS",
          _ when Platform.isFuchsia => "Fuchsia",
          _ when Platform.isLinux => "Linux",
          _ when Platform.isMacOS => "MacOS",
          _ when Platform.isWindows => "Windows",
          _ => "Unknown",
        };
}
