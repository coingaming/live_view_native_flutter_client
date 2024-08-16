import 'package:flutter/rendering.dart';

/// Returns the corresponding `Axis` based on the input string property.
Axis? getAxis(String? prop) {
  return switch (prop) {
    'vertical' => Axis.vertical,
    'horizontal' => Axis.horizontal,
    _ => null,
  };
}
