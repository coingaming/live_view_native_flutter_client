import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:xml/xml.dart';

/// NodeState represents the state of an XML node.
///
/// It contains the node itself, associated variables, and additional context needed for rendering.
class NodeState {
  /// The XML node that this state represents.
  final XmlNode node;

  /// A map of local variables associated with this node.
  final Map<String, dynamic> variables;

  /// The parser used for converting XML into Flutter widgets.
  final LiveViewUiParser parser;

  /// A list representing the nested state of the node, used for state management.
  final List<String> nestedState;

  /// The LiveView instance associated with this node.
  final LiveView liveView;

  /// The URL path associated with this node, used to determine the current page.
  final String urlPath;

  /// The type of view (e.g., live view, dead view).
  final ViewType viewType;

  /// A list of widgets that are dynamically generated for this node.
  List<Widget> dynamicWidget;

  /// Determines if this node is on the current page based on the URL path.
  bool get isOnTheCurrentPage => urlPath == liveView.currentUrl;

  /// Constructor for creating a NodeState.
  NodeState({
    required this.node,
    required this.variables,
    required this.parser,
    required this.nestedState,
    required this.liveView,
    required this.urlPath,
    required this.viewType,
    this.dynamicWidget = const [],
  });

  /// Creates a copy of the current NodeState with optional overrides for properties.
  NodeState copyWith({
    XmlNode? node,
    Map<String, dynamic>? variables,
    LiveViewUiParser? parser,
    List<String>? nestedState,
    LiveView? liveView,
    String? urlPath,
    List<Widget>? dynamicWidget,
    ViewType? viewType,
  }) =>
      NodeState(
        node: node ?? this.node,
        variables: variables ?? this.variables,
        parser: parser ?? this.parser,
        nestedState: nestedState ?? this.nestedState,
        liveView: liveView ?? this.liveView,
        urlPath: urlPath ?? this.urlPath,
        dynamicWidget: dynamicWidget ?? this.dynamicWidget,
        viewType: viewType ?? this.viewType,
      );
}
