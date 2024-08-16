import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:event_hub/event_hub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import 'package:http_query_string/http_query_string.dart' as qs;
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/live_view_fallback_pages.dart';
import 'package:liveview_flutter/live_view/plugin.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/live_go_back_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/routes/live_router_delegate.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_sheet.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/live_persistent_footer_button.dart';
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/root_view/internal_view.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_view.dart';
import 'package:liveview_flutter/live_view/webdocs.dart';
import 'package:liveview_flutter/platform_name.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import "package:universal_html/html.dart" as web_html;
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';

// Enum to define the types of views available.
enum ViewType { deadView, liveView }

// LiveSocket class manages WebSocket connections.
class LiveSocket {
  PhoenixSocket create({
    required String url,
    required Map<String, dynamic> params,
    required Map<String, String> headers,
  }) {
    return PhoenixSocket(
      url,
      webSocketChannelFactory: (uri) {
        final queryParams = qs.Decoder().convert(uri.query).entries.toList();
        queryParams.addAll(params.entries.toList());
        final query = qs.Encoder().convert(Map.fromEntries(queryParams));
        final newUri = uri.replace(query: query).toString();

        return IOWebSocketChannel.connect(newUri, headers: headers);
      },
      socketOptions: const PhoenixSocketOptions(
        reconnectDelays: [
          Duration.zero,
          Duration(seconds: 1),
          Duration(seconds: 2),
          Duration(seconds: 4),
          Duration(seconds: 8),
        ],
      ),
    );
  }
}

// Enum to define client types.
enum ClientType { liveView, httpOnly, webDocs }

// LiveView class handles the live view's lifecycle and WebSocket communication.
class LiveView {
  final List<Plugin> _installedPlugins = [];
  bool catchExceptions = true;
  bool disableAnimations = false;
  ClientType clientType = ClientType.liveView;

  http.Client httpClient = http.Client();
  LiveSocket liveSocket = LiveSocket();

  Widget? onErrorWidget;
  late LiveRootView rootView;
  String? _csrf;
  late String host;
  late String _clientId;
  late String? _session;
  late String? _phxStatic;
  late String _liveViewId;
  late String currentUrl;
  String? cookie;
  late String endpointScheme;
  int mount = 0;
  EventHub eventHub = EventHub();
  bool isLiveReloading = false;

  String? redirectToUrl;

  PhoenixSocket? _socket;
  late PhoenixSocket _liveReloadSocket;

  PhoenixChannel? _channel;

  List<Widget>? lastRender;

  // Dynamic global state
  late StateNotifier changeNotifier;
  late LiveConnectionNotifier connectionNotifier;
  late ThemeSettings themeSettings;
  LiveGoBackNotifier goBackNotifier = LiveGoBackNotifier();
  late LiveRouterDelegate router;
  bool throttleSpammyCalls = true;

  /// Holds all fallback widgets used during the live view lifecycle.
  LiveViewFallbackPages fallbackPages;

  LiveView({
    this.fallbackPages = const LiveViewFallbackPages(),
  }) {
    currentUrl = '/';
    router = LiveRouterDelegate(this);
    changeNotifier = StateNotifier();
    connectionNotifier = LiveConnectionNotifier();
    themeSettings = ThemeSettings();
    themeSettings.httpClient = httpClient;
    rootView = LiveRootView(view: this);

    // Register default components and exec actions.
    LiveViewUiParser.registerDefaultComponents();
    FlutterExecAction.registerDefaultExecs();

    // Push a loading page.
    router.pushPage(
      url: 'loading',
      widget: connectingWidget(),
      rootState: null,
    );
  }

  /// Connects to the documentation service (only for web).
  void connectToDocs() {
    if (!kIsWeb) return;
    bindWebDocs(this);
  }

  /// Establishes a connection to the live view server.
  Future<void> connect(String address) async {
    await _loadCookies();

    _clientId = const Uuid().v4();
    Uri endpoint = Uri.parse(address);
    host = "${endpoint.host}:${endpoint.port}";
    themeSettings.httpClient = httpClient;
    themeSettings.host = "${endpoint.scheme}://$host";
    bool initialized = false;

    currentUrl = endpoint.path.isEmpty ? "/" : endpoint.path;
    endpointScheme = endpoint.scheme;

    try {
      // Try to get a dead view first.
      http.Response response = await deadViewGetQuery(currentUrl);
      initialized = true;

      // Handle HTTP errors.
      if (response.statusCode > 300) {
        if (response.statusCode == 404) {
          router.pushPage(
            url: 'error',
            widget: [fallbackPages.buildNotFoundError(this, endpoint)],
            rootState: null,
          );
        } else {
          router.pushPage(
            url: 'error',
            widget: [fallbackPages.buildCompilationError(this, response)],
            rootState: null,
          );
        }
      }
    } on SocketException catch (e, stack) {
      // Handle SocketException.
      router.pushPage(
        url: 'error',
        widget: [
          fallbackPages.buildNoServerError(
            this,
            FlutterErrorDetails(exception: e, stack: stack),
          )
        ],
        rootState: null,
      );
    } catch (e, stack) {
      // Handle generic exceptions.
      router.pushPage(
        url: 'error',
        widget: [
          fallbackPages.buildFlutterError(
            this,
            FlutterErrorDetails(exception: e, stack: stack),
          )
        ],
        rootState: null,
      );
    }

    if (!initialized) return autoReconnect(address);

    await reconnect();
  }

  /// Attempts to reconnect after a delay.
  void autoReconnect(String address) {
    Timer(const Duration(seconds: 5), () => connect(address));
  }

  /// Generates HTTP headers for requests.
  Map<String, String> httpHeaders() {
    Map<String, String> headers = {
      'Accept-Language': WidgetsBinding.instance.platformDispatcher.locales
          .map((l) => l.toLanguageTag())
          .where((e) => e != 'C')
          .toSet()
          .toList()
          .join(', '),
      'User-Agent': 'Flutter Live View - ${getPlatformName()}',
      'Accept': 'text/flutter',
    };

    if (cookie != null) headers['Cookie'] = cookie!;

    return headers;
  }

  /// Reconnects to the live view and sets up the necessary components.
  Future<void> reconnect() async {
    await themeSettings.loadPreferences();
    await themeSettings.fetchCurrentTheme();
    await _websocketConnect();
    await _setupLiveReload();
    await _setupPhoenixChannel();
  }

  /// Loads cookies from shared preferences.
  Future<void> _loadCookies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cookie = prefs.getString('cookie');
  }

  /// Parses and saves the cookie to shared preferences.
  Future<void> _parseAndSaveCookie(String cookieValue) async {
    cookie = Cookie.fromSetCookieValue(cookieValue).toString();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('cookie', cookie.toString());
  }

  /// Reads the initial session values from the HTML document.
  void _readInitialSession(Document content) {
    try {
      _csrf = content
              .querySelector('meta[name="csrf-token"]')
              ?.attributes['content'] ??
          content.getElementsByTagName('csrf-token').first.attributes['value']!;

      _session = content
          .querySelector('[data-phx-session]')
          ?.attributes['data-phx-session']!;
      _phxStatic = content
          .querySelector('[data-phx-static]')
          ?.attributes['data-phx-static']!;

      _liveViewId =
          (content.querySelector('[data-phx-main]')?.attributes['id'])!;
    } catch (e, stack) {
      router.pushPage(
        url: 'error',
        widget: [
          fallbackPages.buildFlutterError(
            this,
            FlutterErrorDetails(
              exception: Exception(
                "Unable to load the meta tags. Please add the csrf-token, data-phx-session, and data-phx-static tags in ${content.outerHtml}",
              ),
              stack: stack,
            ),
          ),
        ],
        rootState: null,
      );
    }
  }

  /// Determines the WebSocket scheme (wss or ws).
  String get websocketScheme => endpointScheme == 'https' ? 'wss' : 'ws';

  /// Returns required socket parameters for WebSocket connections.
  Map<String, dynamic> _requiredSocketParams() => {
        '_platform': 'flutter',
        '_format': 'flutter',
        '_lvn': {'os': getPlatformName()},
        'vsn': '2.0.0',
      };

  /// Returns the full socket parameters, including CSRF token and client ID.
  Map<String, dynamic> _socketParams() => {
        ..._requiredSocketParams(),
        '_csrf_token': _csrf,
        '_mounts': mount.toString(),
        'client_id': _clientId,
      };

  /// Returns the full socket parameters, including the URL.
  Map<String, dynamic> _fullsocketParams({bool redirect = false}) {
    Map<String, Object?> params = {
      'session': _session,
      'static': _phxStatic,
      'params': _socketParams()
    };
    String nextUrl = "$endpointScheme://$host$currentUrl";

    if (redirect) {
      params['redirect'] = nextUrl;
    } else {
      params['url'] = nextUrl;
    }

    return params;
  }

  /// Establishes the WebSocket connection.
  Future<void> _websocketConnect() async {
    _socket = liveSocket.create(
      url: "$websocketScheme://$host/live/websocket",
      params: _socketParams(),
      headers: httpHeaders(),
    );

    await _socket?.connect();
  }

  /// Sets up the Phoenix channel for communication with the server.
  Future<void> _setupPhoenixChannel({bool redirect = false}) async {
    _channel = _socket!.addChannel(
      topic: "lv:$_liveViewId",
      parameters: _fullsocketParams(redirect: redirect),
    );

    _channel?.messages.listen(handleMessage);

    if (_channel?.state != PhoenixChannelState.joined) {
      await _channel?.join().future;
    }
  }

  /// Redirects to a specified URL.
  Future<void> redirectTo(String path) async {
    redirectToUrl = path;
    await _channel?.push('phx_leave', {}).future;
  }

  /// Sets up the live reload functionality.
  Future<void> _setupLiveReload() async {
    if (endpointScheme == 'https') return;

    _liveReloadSocket = liveSocket.create(
      url: "$websocketScheme://$host/phoenix/live_reload/socket/websocket",
      params: _requiredSocketParams(),
      headers: {
        'Accept': 'text/flutter',
      },
    );

    PhoenixChannel liveReload = _liveReloadSocket
        .addChannel(topic: "phoenix:live_reload", parameters: {});

    liveReload.messages.listen(handleLiveReloadMessage);

    try {
      await _liveReloadSocket.connect();
      if (liveReload.state != PhoenixChannelState.joined) {
        await liveReload.join().future;
      }
    } catch (e) {
      debugPrint('no live reload available');
    }
  }

  /// Handles incoming messages from the WebSocket.
  void handleMessage(Message event) {
    log('Received message: ${event}');

    if (event.event.value == 'phx_close') {
      if (redirectToUrl != null) {
        currentUrl = redirectToUrl!;
        _setupPhoenixChannel(redirect: true);
      }
      return;
    }

    if (event.event.value == 'diff') {
      handleDiffMessage(event.payload!);
    }

    if (event.payload == null || !event.payload!.containsKey('response')) {
      return;
    }

    if (event.payload!['response']?.containsKey('rendered') ?? false) {
      handleRenderedMessage(event.payload!['response']!['rendered'],
          viewType: ViewType.liveView);
    } else if (event.payload!['response']?.containsKey('diff') ?? false) {
      handleDiffMessage(event.payload!['response']!['diff']);
    }
  }

  /// Handles rendered messages from the server.
  void handleRenderedMessage(Map<String, dynamic> rendered,
      {ViewType viewType = ViewType.liveView}) {
    List<String> elements = List<String>.from(rendered['s']);

    (List<Widget>, NodeState?) render = LiveViewUiParser(
      html: elements,
      htmlVariables: expandVariables(rendered),
      liveView: this,
      urlPath: currentUrl,
      viewType: viewType,
    ).parse();

    lastRender = render.$1;
    connectionNotifier.wipeState();
    router.updatePage(url: currentUrl, widget: render.$1, rootState: render.$2);
  }

  /// Handles diff messages from the server.
  void handleDiffMessage(Map<String, dynamic> diff) {
    changeNotifier.setDiff(diff);
  }

  /// Handles live reload messages from the server.
  Future<void> handleLiveReloadMessage(Message event) async {
    if (event.event.value == 'assets_change' && !isLiveReloading) {
      eventHub.fire('live-reload:start');
      isLiveReloading = true;

      _socket?.close();
      _channel?.close();
      connectionNotifier.wipeState();
      redirectToUrl = null;
      await connect("$endpointScheme://$host$currentUrl");
      isLiveReloading = false;
      eventHub.fire('live-reload:end');
    }
  }

  /// Sends an event to the server.
  void sendEvent(ExecLiveEvent event) {
    Map<String, dynamic> eventData = {
      'type': event.type,
      'event': event.name,
      'value': event.value
    };

    if (clientType == ClientType.webDocs) {
      web_html.window.parent
          ?.postMessage({'type': 'event', 'data': eventData}, "*");
    } else if (_channel?.state != PhoenixChannelState.closed) {
      _channel?.push('event', eventData);
    }
  }

  /// Returns a widget displayed while connecting.
  List<Widget> connectingWidget() {
    return [InternalView(child: fallbackPages.buildConnecting(this))];
  }

  /// Returns a widget displayed while loading a page.
  List<Widget> loadingWidget(String url) {
    List<Widget> previousWidgets = router.lastRealPage?.widgets ?? [];

    List<Widget> ret = [
      InternalView(child: fallbackPages.buildLoading(this, url))
    ];

    // Retain previous navigation items to avoid flickering during load.
    List<Widget> previousNavigation = previousWidgets
        .where((element) =>
            element is LiveDrawer ||
            element is LiveAppBar ||
            element is LiveBottomNavigationBar ||
            element is LiveBottomAppBar ||
            element is LiveNavigationRail ||
            element is LiveFloatingActionButton ||
            element is LivePersistentFooterButton ||
            element is LiveBottomSheet)
        .toList();

    ret.addAll(previousNavigation);

    return ret;
  }

  /// Switches the theme and saves the settings.
  Future<void> switchTheme(String? themeName, String? themeMode) async {
    if (themeName == null || themeMode == null) return;

    return themeSettings.setTheme(themeName, themeMode);
  }

  /// Saves the current theme settings.
  Future<void> saveCurrentTheme() => themeSettings.save();

  /// Executes a live patch request to the server.
  Future<void> livePatch(String url) async {
    if (clientType == ClientType.webDocs) {
      web_html.window.parent
          ?.postMessage({'type': 'live-patch', 'url': url}, "*");
    }

    router.pushPage(
      url: 'loading;$url',
      widget: loadingWidget(url),
      rootState: router.pages.lastOrNull?.rootState,
    );
    redirectTo(url);
  }

  /// Sends a form submission as a dead view request.
  Future<void> postForm(Map<String, dynamic> formValues) async {
    await deadViewPostQuery(currentUrl, formValues);
  }

  /// Executes a dead view POST request.
  Future<http.Response> deadViewPostQuery(
      String url, Map<String, dynamic> formValues) async {
    formValues['_csrf_token'] = _csrf;
    http.Response response = await httpClient.post(shortUrlToUri(currentUrl),
        headers: httpHeaders(), body: formValues);

    if (response.headers['set-cookie'] != null) {
      _parseAndSaveCookie(response.headers['set-cookie']!);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      Document content = html.parse(response.body);
      _readInitialSession(content);
    }

    if ((response.statusCode == 302 || response.statusCode == 301) &&
        response.headers['location'] != null) {
      await execHrefClick(response.headers['location']!);
      return response;
    }

    handleRenderedMessage({
      's': [response.body]
    }, viewType: ViewType.deadView);

    return response;
  }

  /// Executes a dead view GET request.
  Future<http.Response> deadViewGetQuery(String url) async {
    http.Response response =
        await httpClient.get(shortUrlToUri(url), headers: httpHeaders());

    if (response.headers['set-cookie'] != null) {
      await _parseAndSaveCookie(response.headers['set-cookie']!);
    }

    if (response.statusCode == 200) {
      Document content = html.parse(response.body);
      _readInitialSession(content);
    }

    return response;
  }

  /// Handles href clicks by performing a dead view GET request.
  Future<void> execHrefClick(String url) async {
    router.pushPage(
      url: 'loading;$url',
      widget: loadingWidget(url),
      rootState: router.pages.lastOrNull?.rootState,
    );

    http.Response response = await deadViewGetQuery(url);

    currentUrl = url;
    redirectToUrl = url;

    handleRenderedMessage({
      's': [response.body]
    }, viewType: ViewType.deadView);

    await _channel?.push('phx_leave', {}).future;
  }

  /// Converts a short URL to a fully qualified URI.
  Uri shortUrlToUri(String url) {
    Uri uri = Uri.parse("$endpointScheme://$host$url");
    Map<String, dynamic> queryParams =
        Map<String, dynamic>.from(uri.queryParametersAll);
    queryParams['_lvn[format]'] = 'flutter';

    return uri.replace(queryParameters: queryParams);
  }

  /// Handles the back navigation.
  Future<void> goBack() async {
    if (clientType == ClientType.webDocs) {
      web_html.window.parent?.postMessage({'type': 'go-back'}, "*");
    }

    await router.navigatorKey?.currentState?.maybePop();
    router.notify();
  }

  /// Installs plugins and registers their widgets and exec actions.
  Future<void> installPlugins(List<Plugin> plugins) async {
    for (Plugin plugin in plugins) {
      plugin.registerWidgets(LiveViewUiRegistry.instance);
      plugin.registerExecs(LiveViewExecRegistry.instance);
    }
    _installedPlugins.addAll(plugins);
  }
}
