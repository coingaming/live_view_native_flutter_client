import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

/// A mixin that handles the computation and management of attributes
/// for XML nodes in a LiveView component.
mixin ComputedAttributes {
  /// Holds the computed attributes and the list of listened keys.
  VariableAttributes computedAttributes = VariableAttributes({}, []);

  /// Stores additional keys that need to be listened to.
  List<ElementKey> extraKeysListened = [];

  /// The default set of attributes that are listened to.
  List<String> defaultListenedAttributes = [
    'phx-click',
    'id',
    'live-patch',
    'phx-href',
    'phx-before-each-render',
    'data-confirm',
    'data-confirm-title',
    'data-confirm-cancel',
    'data-confirm-confirm',
    'self-padding',
    'self-margin',
  ];

  /// Holds the current variables for state management.
  Map<String, dynamic> currentVariables = {};

  /// Checks if the provided key is listened to by either computed attributes
  /// or extra keys that have been added manually.
  bool isKeyListened(ElementKey key) =>
      computedAttributes.listenedKeys.contains(key) ||
      extraKeysListened.contains(key);

  /// Adds a key to the list of extra keys that are listened to, if not already present.
  void addListenedKey(ElementKey key) {
    if (!extraKeysListened.contains(key)) {
      extraKeysListened.add(key);
    }
  }

  /// Retrieves the value of an attribute by its name from the computed attributes.
  /// Returns `null` if the attribute is not found.
  String? getAttribute(String name) {
    return computedAttributes.attributes[name];
  }

  /// Reloads the predefined attributes for a given XML node, merging them with
  /// the current variables and updating the computed attributes.
  void reloadPredefinedAttributes(XmlNode node) {
    for (final attribute in node.attributes) {
      final String name = attribute.name.toString();
      // Add phx- attributes to the default list if they aren't already there.
      if (name.startsWith('phx-') &&
          !defaultListenedAttributes.contains(name)) {
        defaultListenedAttributes.add(name);
      }
    }

    final VariableAttributes attrs = getVariableAttributes(
        node, defaultListenedAttributes, currentVariables);
    computedAttributes.merge(attrs);
  }

  /// Reloads attributes for a given XML node based on the provided list of attributes.
  /// Updates the computed attributes with the latest values.
  void reloadAttributes(XmlNode node, List<String> attributes) {
    computedAttributes =
        getVariableAttributes(node, attributes, currentVariables);
  }

  /// Binds child variable attributes by processing the node and its attributes.
  /// Ensures that attributes are added to the list if necessary and returns
  /// a map of attribute names to their values.
  Map<String, String?> bindChildVariableAttributes(XmlNode node,
      List<String> attributes, Map<String, dynamic> stateVariables) {
    for (final attribute in node.attributes) {
      final String name = attribute.name.toString();
      if ((name.startsWith('phx-') ||
              defaultListenedAttributes.contains(name)) &&
          !attributes.contains(name)) {
        attributes.add(name);
      }
    }

    final VariableAttributes ret =
        getVariableAttributes(node, attributes, stateVariables);

    // Add any new listened keys to the extraKeysListened list.
    for (final ElementKey key in ret.listenedKeys) {
      if (!extraKeysListened.contains(key)) {
        extraKeysListened.add(key);
      }
    }

    return ret.attributes;
  }

  /// Recursively retrieves the children nodes of a given XML node that match
  /// the specified component name. This method navigates through the tree to
  /// find nodes of interest.
  List<XmlNode> childrenNodesOf(XmlNode node, String componentName) {
    final List<XmlNode> result = [];

    for (final XmlNode child in node.nonEmptyChildren) {
      if (child.nodeType == XmlNodeType.ELEMENT) {
        final XmlElement element = child as XmlElement;
        if (element.name.qualified == 'flutter') {
          // Recursively search within <flutter> elements.
          result.addAll(childrenNodesOf(child, componentName));
        } else if (element.name.qualified == componentName) {
          // Add matching component name elements to the result list.
          result.add(child);
        }
      }
    }
    return result;
  }
}
