import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';

WidgetStateProperty<TextStyle?>? materialTextStyle() =>
    (find.byType(FilledButton).evaluate().first.widget as FilledButton)
        .style
        ?.textStyle;

Future<void> setStyle(WidgetTester tester, String style) async {
  await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
    return FilledButton(
      onPressed: () {},
      style: ButtonStyle(textStyle: getMaterialTextStyle(style, context)),
      child: const Text('hello'),
    );
  })));
  await tester.pumpAndSettle();
}

main() {
  testWidgets('material text style', (tester) async {
    await setStyle(tester, 'hello');
    expect(materialTextStyle()!.resolve({}), const TextStyle());

    await setStyle(tester, 'fontWeight: bold');
    expect(materialTextStyle()!.resolve({}),
        const TextStyle(fontWeight: FontWeight.bold));

    await setStyle(tester, """'
          pressed: {
            fontWeight: bold
            color: #F44336
          }
          disabled: {
            fontWeight: w100
          }
        """);
    var style = materialTextStyle()!;
    expect(style.resolve({WidgetState.pressed}),
        const TextStyle(fontWeight: FontWeight.bold, color: Color(0xfff44336)));
    expect(style.resolve({WidgetState.disabled}),
        const TextStyle(fontWeight: FontWeight.w100));
  });
}
