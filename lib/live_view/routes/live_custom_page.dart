import 'package:flutter/material.dart';

/// A custom page class that extends `MaterialPage` and provides a fade transition
/// animation when navigating to the page. This class allows for customizing
/// the transition and other page properties.
class LiveCustomPage extends MaterialPage {
  const LiveCustomPage({
    required super.child,
    super.maintainState = true,
    super.fullscreenDialog = false,
    super.allowSnapshotting = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this, // Pass the current page settings to the route
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
}
