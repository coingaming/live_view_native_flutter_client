import 'package:flutter/foundation.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import "package:universal_html/html.dart" as web_html;

/// Binds the LiveView to handle web-specific operations for rendering
/// and listening to messages in a web environment.
void bindWebDocs(LiveView view) {
  // Check if the platform is the web
  if (kIsWeb) {
    // Set the client type to webDocs
    view.clientType = ClientType.webDocs;

    // Parse the URL to check if there is a render request parameter ('r')
    String? renderFromUrl =
        Uri.parse('http://localhost${web_html.window.location.search}')
            .queryParameters['r'];

    // If the render request parameter exists, handle the rendering of the page
    if (renderFromUrl != null) {
      view.handleRenderedMessage({
        's': [renderFromUrl],
      }, viewType: ViewType.deadView);
    }

    // Listen for incoming messages from the window
    web_html.window.onMessage.listen((event) {
      var data = event.data;
      // If the incoming message is a string, handle it as a rendered message
      if (data is String) {
        view.handleRenderedMessage({
          's': [data],
        }, viewType: ViewType.deadView);
      }
    });
  }
}
