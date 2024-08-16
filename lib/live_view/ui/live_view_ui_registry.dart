import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

/// Type alias for a function that takes a [NodeState] and returns a list of [Widget]s.
typedef WidgetBuilder = List<Widget> Function(NodeState);

/// Singleton class for registering and retrieving widget builders based on component names.
class LiveViewUiRegistry {
  /// Private constructor for singleton pattern.
  LiveViewUiRegistry._internal();

  /// Singleton instance of [LiveViewUiRegistry].
  static final LiveViewUiRegistry _instance = LiveViewUiRegistry._internal();

  /// Registry map that holds component names and their corresponding widget builders.
  final Map<String, WidgetBuilder> _widgets = {};

  /// Public accessor for the singleton instance.
  static LiveViewUiRegistry get instance => _instance;

  /// Registers widget builders for the given component names.
  ///
  /// [componentNames]: A list of component names to associate with the [buildWidget] function.
  /// [buildWidget]: A function that returns a list of widgets for a given [NodeState].
  void add(List<String> componentNames, WidgetBuilder buildWidget) {
    for (String componentName in componentNames) {
      _widgets[componentName] = buildWidget;
    }
  }

  /// Builds a widget for the given component name using the registered widget builder.
  ///
  /// [componentName]: The name of the component to build.
  /// [state]: The [NodeState] that provides the context for building the widget.
  ///
  /// Returns a list of widgets. If the component name is unknown, returns a [SizedBox.shrink()] widget.
  List<Widget> buildWidget(String componentName, NodeState state) {
    final WidgetBuilder? builder = _widgets[componentName];

    if (builder != null) {
      return builder.call(state);
    }

    // Report error and return an empty widget if the component name is not found.
    reportError("Unknown widget: $componentName");
    return [const SizedBox.shrink()];
  }
}
