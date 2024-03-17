import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveEndDrawer extends LiveStateWidget<LiveEndDrawer> {
  const LiveEndDrawer({super.key, required super.state});

  @override
  State<LiveEndDrawer> createState() => _LiveEndDrawerState();
}

class _LiveEndDrawerState extends StateWidget<LiveEndDrawer> {
  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node, [
        'backgroundColor',
        'elevation',
        'shadowColor',
        'surfaceTintColor',
        'width',
        'semanticLabel',
        'clipBehavior'
      ]);

  @override
  Widget render(BuildContext context) {
    return Drawer(
        backgroundColor: colorAttribute(context, 'backgroundColor'),
        elevation: doubleAttribute('elevation'),
        shadowColor: colorAttribute(context, 'shadowColor'),
        surfaceTintColor: colorAttribute(context, 'surfaceTintColor'),
        width: doubleAttribute('width'),
        semanticLabel: getAttribute('semanticLabel'),
        clipBehavior: clipAttribute('clipBehavior'),
        child: singleChild());
  }
}
