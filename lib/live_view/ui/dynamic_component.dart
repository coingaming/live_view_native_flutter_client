import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';

/// Expands variables in the `diff` map based on templates and component data.
///
/// This function recursively replaces placeholders in the `diff` map with actual values
/// from the `templates` and `component` maps, supporting nested structures.
Map<String, dynamic> expandVariables(
  Map<String, dynamic> diff, {
  Map<String, dynamic> templates = const {},
  Map<String, dynamic>? component,
}) {
  // Create copies of the input maps to avoid mutating them directly
  final Map<String, dynamic> result = Map<String, dynamic>.from(diff);
  final Map<String, dynamic> nextTemplate =
      Map<String, dynamic>.from(templates);

  // If the 'c' key exists in the result, update the component map
  if (result.containsKey('c')) {
    component = result.remove('c');
  }

  // Replace numeric keys in the result map with corresponding values from the component map
  if (component != null) {
    for (String key in result.keys) {
      if (key.isNumber() && result[key] is num) {
        result[key] = component[result[key].toString()];
      }
    }
  }

  // Merge 'p' data from the result into the next template
  if (result.containsKey('p') && result['p'] is Map) {
    nextTemplate.addAll(result['p']);
  }

  // Handle 'd' data as a list and recursively expand variables
  if (result.containsKey('d') &&
      result['d'] is List &&
      !result.containsKey('0')) {
    int count = 0;
    if (result['d'].isEmpty) {
      return result;
    }

    for (List<dynamic> forList in result['d']) {
      final Map<String, dynamic> localVar = {
        for (final localVar in forList.indexed) '${localVar.$1}': localVar.$2
      };
      result[count.toString()] = localVar;
      count++;
    }
    return expandVariables(result,
        templates: nextTemplate, component: component);
  }

  // Replace 's' key in the result map with corresponding value from the next template
  if (result.containsKey('s') && result['s'] is int) {
    result['s'] = nextTemplate[result['s'].toString()];
  }

  // Recursively expand variables in nested maps
  return result.map((k, v) {
    if (v is Map<String, dynamic>) {
      return MapEntry(
        k,
        expandVariables(Map<String, dynamic>.from(v),
            templates: nextTemplate, component: component),
      );
    }
    return MapEntry(k, v);
  });
}

/// Renders dynamic components based on the current node state.
///
/// This function parses and renders dynamic components using the state parser,
/// handling nested and repeated components as well.
List<Widget> renderDynamicComponent(NodeState state) {
  final List<Widget> components = [];

  // Handle dynamic data 'd' in the state variables
  if (state.variables.containsKey('d')) {
    if (state.variables['d'].isEmpty) {
      return [];
    }

    for (int i = 0; i < state.variables['d'].length; i++) {
      final List<String> newState = List<String>.from(state.nestedState)
        ..add(i.toString());

      components.addAll(
        state.parser
            .parseHtml(
              List<String>.from(state.variables['s']),
              state.variables[i.toString()],
              newState,
            )
            .$1,
      );
    }
    return components;
  }

  // Extract dynamic keys and handle dynamic rendering
  final List<ElementKey> dynamicKeys =
      extractDynamicKeys(state.node.toString());
  for (final ElementKey elementKey in dynamicKeys) {
    final dynamic currentVariables = state.variables[elementKey.key];

    if (currentVariables is! Map || !currentVariables.containsKey('d')) {
      continue;
    }

    for (int i = 0; i < currentVariables['d'].length; i++) {
      final List<String> newState = List<String>.from(state.nestedState)
        ..add(elementKey.key)
        ..add(i.toString());

      components.addAll(
        state.parser
            .parseHtml(
              List<String>.from(currentVariables['s']),
              currentVariables[i.toString()],
              newState,
            )
            .$1,
      );
    }
  }

  // Handle cases where multiple components are rendered in the same text piece
  if (dynamicKeys.length > 1 && components.isEmpty) {
    for (final ElementKey elementKey in dynamicKeys) {
      components.addAll(
        state.parser.parseHtml(
          ["[[flutterState key=${elementKey.key}]]"],
          state.variables,
          state.nestedState,
        ).$1,
      );
    }
  }

  // Return the rendered components, or a LiveDynamicComponent if none were found
  return (components.isNotEmpty)
      ? components
      : [LiveDynamicComponent(state: state)];
}
