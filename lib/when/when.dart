import 'package:flutter/material.dart';

class When {
  String conditions;

  When({this.conditions = ""});

  bool get isNotEmpty => conditions.isNotEmpty;

  /// Evaluates a condition based on the provided operator.
  bool _calculateCondition(double first, String operator, double second) {
    return switch (operator) {
      '>' => first > second,
      '<' => first < second,
      '>=' => first >= second,
      '<=' => first <= second,
      '==' => first == second,
      '!=' => first != second,
      _ => false,
    };
  }

  /// Recursively executes a list of conditions and operators.
  bool _execute(List<dynamic> conditions) {
    var stack = [];

    while (conditions.length > 1) {
      var chunk = conditions.removeAt(0);

      if (chunk is double) {
        // If the chunk is a number, calculate the condition.
        double first = chunk;
        var operator = conditions.removeAt(0);
        var second = conditions.removeAt(0);
        stack.insert(0, _calculateCondition(first, operator, second));
      } else if (chunk is String) {
        // If the chunk is an operator, evaluate the logical expression.
        return switch (chunk) {
          'and' => stack.first && _execute(conditions),
          'or' => stack.first || _execute(conditions),
          _ => false,
        };
      }
    }

    return stack.first;
  }

  /// Executes the condition based on the context.
  bool execute(BuildContext context) {
    if (conditions.isEmpty) return true;

    String trimmed = conditions.trim();

    // Use switch expression to handle different screen size conditions.
    return switch (trimmed) {
      'screen-xs' => MediaQuery.of(context).size.width < 576,
      'screen-sm' => MediaQuery.of(context).size.width >= 576,
      'screen-md' => MediaQuery.of(context).size.width >= 768,
      'screen-lg' => MediaQuery.of(context).size.width >= 992,
      'screen-xl' => MediaQuery.of(context).size.width >= 1200,
      'screen-2xl' => MediaQuery.of(context).size.width >= 1400,
      _ => () {
          // Replace window dimensions in the conditions and parse them.
          MediaQueryData window = MediaQuery.of(context);
          String updatedConditions = conditions
              .replaceAll('window_width', window.size.width.toString())
              .replaceAll('window_height', window.size.height.toString());

          // Split the condition string and remove empty elements.
          List<String> c = updatedConditions.split(' ')
            ..removeWhere((element) => element.isEmpty);

          // Convert the conditions to a list of numbers and operators, then execute.
          return _execute(c.map((op) => double.tryParse(op) ?? op).toList());
        }(),
    };
  }

  /// Parses the "when" condition from attributes.
  static When parse(String attributeName, Map<String, dynamic>? attributes) {
    String? when = attributes?["$attributeName-when"]?.trim();
    return when != null ? When(conditions: when) : When();
  }
}
