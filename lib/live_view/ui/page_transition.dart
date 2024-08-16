import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A custom page transition that extends [MaterialPage].
/// This class can be used for custom transitions between pages.
class CustomPageTransition extends MaterialPage {
  const CustomPageTransition({
    required super.child,
    super.maintainState = true,
    super.fullscreenDialog = false,
    super.allowSnapshotting = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });
}

/// A custom page route with a transition animation using [CupertinoPageTransition].
class PageTransition<T> extends MaterialPageRoute<T> {
  /// Constructor for [PageTransition], accepting a [builder] and optional [settings].
  PageTransition({
    required super.builder,
    super.settings,
  });

  /// Duration of the page transition animation.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  /// Builds the transition animation for the page.
  ///
  /// [context] - The build context.
  /// [animation] - The primary animation for the route.
  /// [secondaryAnimation] - The secondary animation for the route.
  /// [child] - The widget that is being transitioned to.
  ///
  /// Returns a [CupertinoPageTransition] with a linear transition.
  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: true,
      child: child,
    );
  }
}
