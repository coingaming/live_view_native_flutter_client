import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Returns the name of the platform on which the app is currently running.
String getPlatformName() {
  // Check if the app is running on the web.
  if (kIsWeb) return "Web";

  return switch (Platform.operatingSystem) {
    'android' => "Android",
    'ios' => "iOS",
    'fuchsia' => "Fuchsia",
    'linux' => "Linux",
    'macos' => "MacOS",
    'windows' => "Windows",
    _ => "Unknown", // Fallback for unsupported platforms.
  };
}
