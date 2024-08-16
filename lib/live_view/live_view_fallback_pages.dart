import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/compilation_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/error_404.dart';
import 'package:liveview_flutter/live_view/ui/errors/flutter_error_view.dart';
import 'package:liveview_flutter/live_view/ui/errors/no_server_error_view.dart';

/// LiveViewFallbackPages handles the fallback widgets used during various
/// error and loading states in a LiveView app.
class LiveViewFallbackPages {
  final bool _debugMode;
  final Widget Function(LiveView, [String?])? _connectingBuilder;
  final Widget Function(LiveView, String)? _loadingBuilder;
  final Widget Function(LiveView, Uri)? _notFoundErrorBuilder;
  final Widget Function(LiveView, Response)? _compilationErrorBuilder;
  final Widget Function(LiveView, FlutterErrorDetails)? _noServerErrorBuilder;
  final Widget Function(LiveView, FlutterErrorDetails)? _flutterErrorBuilder;

  /// Constructs the fallback pages with optional custom builders.
  ///
  /// If [debugMode] is true, custom builders will be ignored in debug mode.
  const LiveViewFallbackPages({
    bool debugMode = kDebugMode,
    Widget Function(LiveView, [String?])? connectingBuilder,
    Widget Function(LiveView, String)? loadingBuilder,
    Widget Function(LiveView, Uri)? notFoundErrorBuilder,
    Widget Function(LiveView, Response)? compilationErrorBuilder,
    Widget Function(LiveView, FlutterErrorDetails)? noServerErrorBuilder,
    Widget Function(LiveView, FlutterErrorDetails)? flutterErrorBuilder,
  })  : _debugMode = debugMode,
        _connectingBuilder = connectingBuilder,
        _loadingBuilder = loadingBuilder,
        _notFoundErrorBuilder = notFoundErrorBuilder,
        _noServerErrorBuilder = noServerErrorBuilder,
        _compilationErrorBuilder = compilationErrorBuilder,
        _flutterErrorBuilder = flutterErrorBuilder;

  /// Builds the loading widget, using a custom builder if provided.
  Widget buildLoading(LiveView liveView, String url) {
    return _buildFallbackWidget(
      liveView,
      customBuilder: _loadingBuilder,
      param: url,
      defaultBuilder: () => _defaultLoadingWidget(liveView),
    );
  }

  /// Builds the connecting widget, using a custom builder if provided.
  Widget buildConnecting(LiveView liveView, [String? url]) {
    return _buildFallbackWidget(
      liveView,
      customBuilder: _connectingBuilder,
      param: url,
      defaultBuilder: () => _defaultLoadingWidget(liveView),
    );
  }

  /// Builds the compilation error widget, using a custom builder if provided.
  Widget buildCompilationError(LiveView liveView, Response response) {
    return _buildFallbackWidget(
      liveView,
      customBuilder: _compilationErrorBuilder,
      param: response,
      defaultBuilder: () => CompilationErrorView(html: response.body),
    );
  }

  /// Builds the not found error widget, using a custom builder if provided.
  Widget buildNotFoundError(LiveView liveView, Uri endpoint) {
    return _buildFallbackWidget(
      liveView,
      customBuilder: _notFoundErrorBuilder,
      param: endpoint,
      defaultBuilder: () => Error404(url: endpoint.toString()),
    );
  }

  /// Builds the no server error widget, using a custom builder if provided.
  Widget buildNoServerError(LiveView liveView, FlutterErrorDetails details) {
    return _buildFallbackWidget(
      liveView,
      customBuilder: _noServerErrorBuilder,
      param: details,
      defaultBuilder: () => NoServerError(error: details),
    );
  }

  /// Builds the Flutter error widget, using a custom builder if provided.
  Widget buildFlutterError(LiveView liveView, FlutterErrorDetails details) {
    return _buildFallbackWidget(
      liveView,
      customBuilder: _flutterErrorBuilder,
      param: details,
      defaultBuilder: () => FlutterErrorView(error: details),
    );
  }

  /// A helper method to wrap the logic for choosing between a custom
  /// builder and a default widget. If [debugMode] is enabled, the custom
  /// builder is ignored.
  Widget _buildFallbackWidget<T>(
    LiveView liveView, {
    required Widget Function(LiveView, T)? customBuilder,
    required T param,
    required Widget Function() defaultBuilder,
  }) {
    if (!_debugMode && customBuilder != null) {
      return customBuilder(liveView, param);
    }
    return defaultBuilder();
  }

  /// A default loading widget to be used in the absence of a custom builder.
  Widget _defaultLoadingWidget(LiveView liveView) {
    return Builder(
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Center(
          child: CircularProgressIndicator(
            value: liveView.disableAnimations == false ? null : 1,
          ),
        ),
      ),
    );
  }
}
