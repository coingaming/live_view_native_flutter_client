import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';

/// Abstract class representing a Plugin that can be registered in a LiveView application.
///
/// This class defines the interface for plugins, requiring them to have a `name`
/// and methods for registering widgets and executable actions.
abstract class Plugin {
  /// The name of the plugin, used for identification.
  String get name;

  /// Registers the plugin's widgets with the provided [LiveViewUiRegistry].
  ///
  /// Implement this method to register custom widgets that your plugin provides.
  void registerWidgets(LiveViewUiRegistry registry);

  /// Registers the plugin's execs (executable actions) with the provided [LiveViewExecRegistry].
  ///
  /// Implement this method to register any executable actions that your plugin provides.
  void registerExecs(LiveViewExecRegistry registry);
}
