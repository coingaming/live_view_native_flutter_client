import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/floating_action_button_location.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/state/computed_attributes.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_sheet.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_end_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/live_persistent_footer_button.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/loading/reload_widget.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_bottom_navigation_bar.dart';
import 'package:throttled/throttled.dart';
import 'package:xml/xml.dart';

/// Notification to trigger showing a bottom sheet.
class ShowBottomSheetNotification extends Notification {}

/// Root scaffold for the LiveView app.
class RootScaffold extends StatefulWidget {
  final LiveView view;

  const RootScaffold({super.key, required this.view});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> with ComputedAttributes {
  List<Widget> children = [];
  bool isLiveReloading = false;
  bool hasBottomNavigationBar = false;
  bool hasAppBar = false;
  LiveNavigationRail? railBar;
  LiveDrawer? drawer;
  LiveEndDrawer? endDrawer;
  LiveFloatingActionButton? floatingActionButton;
  FloatingActionButtonLocation? floatingActionButtonLocation;
  List<LiveStateWidget> persistentButtons = [];
  final GlobalKey<ScaffoldState> key = GlobalKey<ScaffoldState>();
  NodeState? rootNode;

  @override
  void initState() {
    super.initState();

    // Subscribe to live reload events
    widget.view.eventHub.on('live-reload:start', (_) => setState(() {}));
    widget.view.eventHub.on('live-reload:end', (_) => setState(() {}));

    // Listen for route changes and diff updates
    widget.view.router.addListener(routeChange);
    widget.view.changeNotifier.addListener(onDiffUpdateEvent);

    // Initialize state
    onStateChange(currentVariables);
  }

  /// Handles updates when the state changes due to diffs.
  void onDiffUpdateEvent() {
    if (!mounted) return;

    NodeState? currentRoot = widget.view.router.pages.last.rootState;
    if (currentRoot == null) return;

    rootNode = currentRoot;
    Map<String, dynamic> lastLiveDiff =
        widget.view.changeNotifier.getNestedDiff(currentRoot.nestedState);

    // If any listened keys are present in the diff, update the state
    if (lastLiveDiff.keys.any((key) => isKeyListened(ElementKey(key)))) {
      currentVariables.addAll(lastLiveDiff);
      onStateChange(lastLiveDiff);
      reloadPredefinedAttributes(currentRoot.node);
      setState(() {});
    }
  }

  /// Handles state changes by reloading attributes.
  void onStateChange(Map<String, dynamic> diff) {
    if (rootNode == null) return;
    reloadAttributes(rootNode!.node, []);
  }

  @override
  void dispose() {
    widget.view.changeNotifier.removeListener(onDiffUpdateEvent);
    widget.view.router.removeListener(routeChange);
    super.dispose();
  }

  /// Handles route changes by resetting computed attributes and updating the root node.
  void routeChange() {
    setState(() {
      computedAttributes = VariableAttributes({}, []);
      rootNode = widget.view.router.pages.last.rootState;
    });
  }

  /// Wraps the child widget with a navigation rail if present.
  Widget mapRailBar(Widget child) {
    if (railBar == null) return child;
    return Row(children: [railBar!, Expanded(child: child)]);
  }

  /// Binds the floating action button location to the current node's state.
  void bindFloatingActionButtonLocation() {
    rootNode = widget.view.router.pages.last.rootState;
    if (rootNode != null) {
      XmlNode? viewBody =
          childrenNodesOf(rootNode!.node, 'viewBody').firstOrNull;
      if (viewBody != null) {
        Map<String, String?> attributes = bindChildVariableAttributes(
            viewBody, ['floatingActionButtonLocation'], rootNode!.variables);
        FloatingActionButtonLocation? location =
            getFloatingActionButtonLocation(
                attributes['floatingActionButtonLocation']);
        if (location != null) {
          floatingActionButtonLocation = location;
        }
      }
    }
  }

  /// Retrieves a root attribute by name.
  String? getRootAttribute(String name) {
    NodeState? rootState = widget.view.router.pages.last.rootState;
    if (rootState == null) return null;

    Map<String, String?> attributes = bindChildVariableAttributes(
        rootState.node, [name], rootState.variables);
    return attributes[name];
  }

  @override
  Widget build(BuildContext context) {
    bindFloatingActionButtonLocation();

    // Check if the current page contains global navigation widgets
    if (widget.view.router.pages.last.containsGlobalNavigationWidgets) {
      List<Widget> widgets =
          List<Widget>.from(widget.view.router.pages.last.widgets);

      railBar = StateChild.extractWidgetChild<LiveNavigationRail>(widgets);
      drawer = StateChild.extractWidgetChild<LiveDrawer>(widgets);
      endDrawer = StateChild.extractWidgetChild<LiveEndDrawer>(widgets);
      floatingActionButton =
          StateChild.extractWidgetChild<LiveFloatingActionButton>(widgets);
      persistentButtons =
          StateChild.extractChildren<LivePersistentFooterButton>(widgets);
      hasAppBar = childrenNodesOf(rootNode!.node, 'AppBar').firstOrNull != null;
      hasBottomNavigationBar =
          childrenNodesOf(rootNode!.node, 'BottomAppBar').firstOrNull != null ||
              childrenNodesOf(rootNode!.node, 'BottomNavigationBar')
                      .firstOrNull !=
                  null;
    } else {
      // Reset attributes if no global navigation widgets are present
      railBar = null;
      drawer = null;
      endDrawer = null;
      floatingActionButton = null;
      hasAppBar = false;
      hasBottomNavigationBar = false;
      persistentButtons = [];
    }

    Widget child = SafeArea(
      child: Router(
        routerDelegate: widget.view.router,
        backButtonDispatcher: RootBackButtonDispatcher(),
      ),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      key: key,
      drawer: drawer,
      endDrawer: endDrawer,
      primary: getBoolean(getRootAttribute('primary')) ?? true,
      appBar: hasAppBar ? RootAppBar(view: widget.view) : null,
      body: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          if (widget.view.throttleSpammyCalls) {
            throttle(
              'window_resize',
              () => widget.view.eventHub.fire('phx:window:resize'),
              cooldown: const Duration(milliseconds: 50),
            );
          } else {
            widget.view.eventHub.fire('phx:window:resize');
          }
          return true;
        },
        child: NotificationListener<ShowBottomSheetNotification>(
          onNotification: (_) {
            List<Widget> widgets =
                List<Widget>.from(widget.view.router.pages.last.widgets);
            LiveBottomSheet? bottomSheet =
                StateChild.extractWidgetChild<LiveBottomSheet>(widgets);
            if (bottomSheet == null) {
              debugPrint('No bottomsheet to show');
              return true;
            }

            key.currentState!.showBottomSheet((context) => bottomSheet);
            return true;
          },
          child: mapRailBar(
            SizeChangedLayoutNotifier(
              child: widget.view.isLiveReloading
                  ? Stack(children: [child, const ReloadWidget()])
                  : child,
            ),
          ),
        ),
      ),
      bottomNavigationBar: hasBottomNavigationBar
          ? RootBottomNavigationBar(view: widget.view)
          : null,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButton: floatingActionButton,
      persistentFooterButtons:
          persistentButtons.isEmpty ? null : persistentButtons,
    );
  }
}
