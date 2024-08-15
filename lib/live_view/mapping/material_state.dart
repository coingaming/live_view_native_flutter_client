import 'package:flutter/material.dart';

WidgetState? getWidgetState(String? value) {
  switch (value) {
    case 'disabled':
      return WidgetState.disabled;
    case 'hovered':
      return WidgetState.hovered;
    case 'focused':
      return WidgetState.focused;
    case 'pressed':
      return WidgetState.pressed;
    case 'dragged':
      return WidgetState.dragged;
    case 'selected':
      return WidgetState.selected;
    case 'scrolledUnder':
      return WidgetState.scrolledUnder;
    case 'error':
      return WidgetState.error;
    default:
      return null;
  }
}
