import 'package:flutter/material.dart';

/// Returns the corresponding `AlignmentDirectional` based on the input string property.
AlignmentDirectional? getAlignmentDirectional(String? prop) {
  return switch (prop) {
    'bottomCenter' => AlignmentDirectional.bottomCenter,
    'bottomEnd' => AlignmentDirectional.bottomEnd,
    'bottomStart' => AlignmentDirectional.bottomStart,
    'center' => AlignmentDirectional.center,
    'centerEnd' => AlignmentDirectional.centerEnd,
    'centerStart' => AlignmentDirectional.centerStart,
    'topCenter' => AlignmentDirectional.topCenter,
    'topEnd' => AlignmentDirectional.topEnd,
    'topStart' => AlignmentDirectional.topStart,
    _ => null,
  };
}
