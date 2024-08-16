import 'package:flutter/material.dart';

/// Returns the corresponding `MainAxisAlignment` based on the input string property.
MainAxisAlignment? getMainAxisAlignment(String? prop) {
  return switch (prop) {
    'center' => MainAxisAlignment.center,
    'start' => MainAxisAlignment.start,
    'end' => MainAxisAlignment.end,
    'spaceAround' => MainAxisAlignment.spaceAround,
    'spaceBetween' => MainAxisAlignment.spaceBetween,
    'spaceEvenly' => MainAxisAlignment.spaceEvenly,
    _ => null,
  };
}

/// Returns the corresponding `MainAxisSize` based on the input string property.
MainAxisSize? getMainAxisSize(String? prop) {
  return switch (prop) {
    'max' => MainAxisSize.max,
    'min' => MainAxisSize.min,
    _ => null,
  };
}

/// Returns the corresponding `CrossAxisAlignment` based on the input string property.
CrossAxisAlignment? getCrossAxisAlignment(String? prop) {
  return switch (prop) {
    'center' => CrossAxisAlignment.center,
    'start' => CrossAxisAlignment.start,
    'end' => CrossAxisAlignment.end,
    'baseline' => CrossAxisAlignment.baseline,
    'stretch' => CrossAxisAlignment.stretch,
    _ => null,
  };
}

/// Returns the corresponding `VerticalDirection` based on the input string property.
VerticalDirection? getVerticalDirection(String? prop) {
  return switch (prop) {
    'down' => VerticalDirection.down,
    'up' => VerticalDirection.up,
    _ => null,
  };
}
