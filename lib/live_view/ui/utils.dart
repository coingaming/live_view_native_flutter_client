import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

extension NonEmptyChildren on XmlNode {
  List<XmlNode> get nonEmptyChildren {
    return children.where((c) {
      return !c.isEmpty;
    }).toList();
  }

  bool get isEmpty => nodeType == XmlNodeType.TEXT && text.trim() == '';
}

extension JoinMethod on List<String> {
  String joinWith(String Function(int index) separator) {
    var index = -1;
    Iterator<String> iterator = this.iterator;
    if (!iterator.moveNext()) return "";
    var first = iterator.current.toString();
    if (!iterator.moveNext()) return first;
    var buffer = StringBuffer(first);
    if (separator(index++).isEmpty) {
      do {
        buffer.write(iterator.current.toString());
      } while (iterator.moveNext());
    } else {
      do {
        buffer
          ..write(separator(index++))
          ..write(iterator.current.toString());
      } while (iterator.moveNext());
    }
    return buffer.toString();
  }
}

extension Matches on String {
  bool matches(String regex) => RegExp(regex).firstMatch(this) != null;
}

dynamic tryJsonDecode(String source,
    {Object? Function(Object?, Object?)? reviver}) {
  try {
    return jsonDecode(source, reviver: reviver);
  } on FormatException {
    return null;
  }
}

extension ThemeModeStringify on ThemeMode {
  static ThemeMode parse(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String modeAsString() {
    switch (this) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}
