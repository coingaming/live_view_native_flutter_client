import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

class StateChild {
  /// Handles the child structure for widgets that can accept either a single child
  /// or multiple children. If multiple children are present, they are wrapped
  /// in a `Column` widget. If a single child is present, it is returned directly.
  ///
  /// In Flutter, components can accept either a single child or multiple children but not both.
  /// How the client reconciles this is to add a `Column` widget if needed to behave more like HTML.
  /// Raw text elements in the xml payload are transformed into a basic Flutter `Text` widget.
  /// Those two buttons are equivalent:
  ///
  /// ```xml
  /// <ElevatedButton>Click me</ElevatedButton>
  /// <ElevatedButton><Text>Click me</Text></ElevatedButton>
  /// ```
  ///
  /// And those two buttons are exactly rendered the same way as well:
  ///
  /// ```xml
  /// <ElevatedButton>
  ///     <Column>
  ///         <Text>Click</Text>
  ///         <Text> me</Text>
  ///     </Column>
  /// </ElevatedButton>
  ///
  /// <ElevatedButton>
  ///     <Text>Click</Text>
  ///     <Text> me</Text>
  /// </ElevatedButton>
  /// ```
  static Widget singleChild(NodeState state) {
    List<XmlNode> children = state.node.nonEmptyChildren;

    return switch (children.length) {
      0 => const SizedBox.shrink(),
      1 => _handleSingleChild(state, children),
      _ => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: multipleChildren(state)),
    };
  }

  /// Handles a single child case, parsing the child into Flutter components.
  static Widget _handleSingleChild(NodeState state, List<XmlNode> children) {
    List<Widget> components =
        LiveViewUiParser.traverse(state.copyWith(node: children[0]));

    if (components.isEmpty) {
      return const SizedBox.shrink();
    }

    if (components.length == 1) {
      return components.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: components,
    );
  }

  /// Extracts multiple children from the XML nodes.
  /// This is needed for widgets that accept multiple children, such as List or SegmentedButton.
  static List<Widget> multipleChildren(NodeState state) {
    List<Widget> childrenWidgets = [];

    for (XmlNode node in state.node.nonEmptyChildren) {
      childrenWidgets
          .addAll(LiveViewUiParser.traverse(state.copyWith(node: node)));
    }

    return childrenWidgets;
  }

  /// Extracts child widgets of a specific type from the list of widgets,
  /// filtering based on type and the `as` attribute.
  static List<LiveStateWidget> extractChildren<Type extends LiveStateWidget>(
      List<Widget> children) {
    List<LiveStateWidget> result = [];
    String refType = Type.toString()
        .replaceAll('Live', '')
        .replaceAll('Attribute', '')
        .toLowerCase();

    for (Widget child in children) {
      if (child is Type) {
        result.add(child);
      } else if (child is LiveStateWidget &&
          child.state.node.getAttribute('as') == refType) {
        result.add(child);
      }
    }

    children.removeWhere((widget) => result.contains(widget));
    return result;
  }

  /// Extracts a child widget of a specific type from the list of widgets,
  /// using the `as` attribute if necessary.
  static LiveStateWidget? extractChild<Type extends LiveStateWidget>(
      List<Widget> children) {
    LiveStateWidget? result;
    String refType = Type.toString()
        .replaceAll('Live', '')
        .replaceAll('Attribute', '')
        .toLowerCase();

    for (Widget child in children) {
      if (child is Type) {
        result = child;
      } else if (child is LiveStateWidget &&
          child.state.node.getAttribute('as') == refType) {
        result = child;
      }
    }

    children.removeWhere((widget) => widget == result);
    return result;
  }

  /// Extracts a widget of a specific type from the list of widgets.
  static Type? extractWidgetChild<Type extends Widget>(List<Widget> children) {
    Type? result;

    for (Widget child in children) {
      if (child is Type) {
        result = child;
      }
    }

    children.removeWhere((widget) => widget == result);
    return result;
  }
}
