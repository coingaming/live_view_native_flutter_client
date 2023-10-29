import 'package:flutter/foundation.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import "package:universal_html/html.dart" as web_html;

void bindWebDocs(LiveView view) {
  if (kIsWeb) {
    view.webDocsMode = true;
    var renderFromUrl =
        Uri.parse('http://localhost${web_html.window.location.search}')
            .queryParameters['r'];
    if (renderFromUrl != null) {
      view.handleRenderedMessage({
        's': [renderFromUrl]
      });
    }
    web_html.window.onMessage.listen((event) {
      var data = event.data;
      if (data is String) {
        view.handleRenderedMessage({
          's': [data]
        });
      }
    });
  }
}
