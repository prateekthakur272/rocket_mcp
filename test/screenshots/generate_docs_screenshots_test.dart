// Regenerates the screenshots in docs/screenshots from the real UI.
//
//   GEN_SCREENSHOTS=1 flutter test test/screenshots/generate_docs_screenshots_test.dart
//
// The app is rendered with real fonts against a fictional demo workspace served by an in-memory MCP server, so no
// personal paths or data end up in the docs. Skipped unless GEN_SCREENSHOTS is set, so a normal `flutter test` never
// touches the docs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart'
    show Material, MaterialApp, MaterialType;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/badge_icon_btn.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/shell/app.dart';
import 'package:rocket_mcp/features/shell/window_chrome.dart';
import 'package:rocket_mcp/theme/theme.dart';

const _windowSize = Size(1360, 860);
const _pixelRatio = 1.5;
const _outDir = 'docs/screenshots';

final bool _generate = Platform.environment['GEN_SCREENSHOTS'] == '1';

// ---------------------------------------------------------------------------------------------------------------
// Fonts
// ---------------------------------------------------------------------------------------------------------------

Future<void> _loadFonts() async {
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final fonts = '$root/bin/cache/artifacts/material_fonts';

  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(await File(path).readAsBytes());

  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('$fonts/MaterialIcons-Regular.otf'));
  await icons.load();

  // The app's text has no explicit family, so it resolves to the platform default; load a real sans font under every
  // name it may resolve to.
  for (final family in [
    'Roboto',
    '.AppleSystemUIFont',
    '.SF UI Text',
    '.SF Pro Text',
  ]) {
    final sans = FontLoader(family);
    const sf = '/System/Library/Fonts/SFNS.ttf';
    if (File(sf).existsSync()) {
      sans.addFont(bytes(sf));
    } else {
      for (final f in ['Roboto-Regular', 'Roboto-Medium', 'Roboto-Bold']) {
        sans.addFont(bytes('$fonts/$f.ttf'));
      }
    }
    await sans.load();
  }

  final mono = FontLoader('Menlo');
  const menlo = '/System/Library/Fonts/Menlo.ttc';
  mono.addFont(
    bytes(File(menlo).existsSync() ? menlo : '$fonts/Roboto-Regular.ttf'),
  );
  await mono.load();
}

// ---------------------------------------------------------------------------------------------------------------
// The demo server
// ---------------------------------------------------------------------------------------------------------------

Map<String, dynamic> _ok(Object? id, Map<String, dynamic> result) => {
  'jsonrpc': '2.0',
  'id': id,
  'result': result,
};

Map<String, dynamic> _forecast(Map args) {
  final city = args['city'] ?? 'Lisbon';
  final days = (args['days'] as num?)?.toInt() ?? 3;
  final metric = (args['units'] ?? 'metric') == 'metric';
  return {
    'city': city,
    'units': metric ? 'metric' : 'imperial',
    'forecast': [
      for (var i = 0; i < days; i++)
        {
          'day': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'][i % 5],
          'summary': ['Sunny', 'Partly cloudy', 'Light rain'][i % 3],
          'high': metric ? 24 - i : 75 - i * 2,
          'low': metric ? 15 - i : 59 - i * 2,
        },
    ],
  };
}

/// A transport that answers like a small, well-behaved weather server.
McpInMemoryTransport _demoTransport(McpServerConfig server) {
  final weather = server.id == 'weather';
  return McpInMemoryTransport(
    onRequest: (msg) {
      final id = msg['id'];
      final params = (msg['params'] as Map?) ?? const {};
      switch (msg['method']) {
        case 'initialize':
          return _ok(id, {
            'protocolVersion': '2024-11-05',
            'serverInfo': {'name': server.name, 'version': '1.4.0'},
            'capabilities': {
              'tools': {},
              'resources': {'subscribe': true},
              'prompts': {},
              'logging': {},
            },
          });
        case 'ping':
          return _ok(id, {});
        case 'tools/list':
          return _ok(id, {
            'tools': weather
                ? [
                    {
                      'name': 'get_forecast',
                      'description': 'Returns the weather forecast for a city for the next few days, in metric or imperial units.',
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'city': {
                            'type': 'string',
                            'description':
                                'Name of the city, for example Lisbon.',
                          },
                          'days': {
                            'type': 'integer',
                            'description':
                                'How many days to forecast (1 to 5).',
                            'default': 3,
                          },
                          'units': {
                            'type': 'string',
                            'description':
                                'The unit system of the temperatures.',
                            'enum': ['metric', 'imperial'],
                          },
                          'includeAlerts': {
                            'type': 'boolean',
                            'description': 'Also return active weather alerts.',
                          },
                        },
                        'required': ['city'],
                      },
                    },
                    {
                      'name': 'get_alerts',
                      'description':
                          'Lists the active weather alerts for a region.',
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'region': {
                            'type': 'string',
                            'description': 'Region code.',
                          },
                        },
                        'required': ['region'],
                      },
                    },
                    {
                      'name': 'convert_temperature',
                      'description': 'Converts a temperature between Celsius and Fahrenheit.',
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'value': {'type': 'number'},
                          'to': {
                            'type': 'string',
                            'enum': ['celsius', 'fahrenheit'],
                          },
                        },
                        'required': ['value', 'to'],
                      },
                    },
                    {
                      'name': 'list_cities',
                      'description':
                          'Lists the cities the server has data for.',
                      'inputSchema': {'type': 'object', 'properties': {}},
                    },
                  ]
                : [
                    {
                      'name': 'echo',
                      'description': 'Echoes back the input string.',
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'message': {'type': 'string'},
                        },
                        'required': ['message'],
                      },
                    },
                  ],
          });
        case 'tools/call':
          final args = (params['arguments'] as Map?) ?? const {};
          return _ok(
            id,
            {
              'content': [
                {
                  'type': 'text',
                  'text': weather
                      ? 'Forecast for ${args['city']}: sunny, high 24°C.'
                      : '${args['message']}',
                },
              ],
              'structuredContent': weather ? _forecast(args) : null,
              'isError': false,
            }..removeWhere((_, v) => v == null),
          );
        case 'resources/list':
          return _ok(id, {
            'resources': [
              {
                'uri': 'weather://stations',
                'name': 'Weather stations',
                'description': 'All stations the server reads from.',
                'mimeType': 'application/json',
              },
              {
                'uri': 'file:///docs/README.md',
                'name': 'README',
                'description': 'About this server.',
                'mimeType': 'text/markdown',
              },
              {
                'uri': 'file:///docs/limits.txt',
                'name': 'Rate limits',
                'mimeType': 'text/plain',
              },
            ],
          });
        case 'resources/templates/list':
          return _ok(id, {
            'resourceTemplates': [
              {
                'uriTemplate': 'weather://{city}/today',
                'name': 'Today in a city',
                'description': 'The current conditions for one city.',
                'mimeType': 'application/json',
              },
            ],
          });
        case 'resources/read':
          return _ok(id, {
            'contents': [
              {
                'uri': params['uri'],
                'mimeType': 'application/json',
                'text': '{\n  "stations": [\n    {"id": "LIS-01", "city": "Lisbon", "online": true},\n    {"id": "OPO-02", "city": "Porto", "online": true},\n    {"id": "FAO-03", "city": "Faro", "online": false}\n  ]\n}',
              },
            ],
          });
        case 'prompts/list':
          return _ok(id, {
            'prompts': [
              {
                'name': 'summarize-forecast',
                'description': 'Summarise the coming days in two sentences.',
                'arguments': [
                  {
                    'name': 'city',
                    'description': 'The city to summarise.',
                    'required': true,
                  },
                  {'name': 'tone', 'description': 'formal or casual.'},
                ],
              },
              {
                'name': 'daily-briefing',
                'description': 'A short morning briefing for all stations.',
              },
            ],
          });
        case 'prompts/get':
          return _ok(id, {
            'description': 'A short morning briefing for all stations.',
            'messages': [
              {
                'role': 'user',
                'content': {
                  'type': 'text',
                  'text': 'Give me a short morning weather briefing for every online station.',
                },
              },
              {
                'role': 'assistant',
                'content': {
                  'type': 'text',
                  'text': 'Good morning. Lisbon and Porto are clear with highs near 24°C; Faro is offline.',
                },
              },
            ],
          });
      }
      return _ok(id, {});
    },
  );
}

const _weather = McpServerConfig(
  id: 'weather',
  name: 'Weather Server',
  command: 'npx',
  args: ['-y', '@acme/mcp-weather'],
);
const _notes = McpServerConfig(
  id: 'notes',
  name: 'Notes Server',
  transport: McpTransportType.streamHttp,
  url: 'https://notes.example.com/mcp',
);
const _search = McpServerConfig(
  id: 'search',
  name: 'Search Server',
  transport: McpTransportType.sse,
  url: 'http://localhost:3001/sse',
);
const _files = McpServerConfig(
  id: 'files',
  name: 'Filesystem Server',
  command: 'npx',
  args: ['-y', '@modelcontextprotocol/server-filesystem', '.'],
);

// ---------------------------------------------------------------------------------------------------------------
// Rendering
// ---------------------------------------------------------------------------------------------------------------

final Map<String, McpInMemoryTransport> _transports = {};

AppState _newState({
  List<McpServerConfig> servers = const [_weather, _notes, _search, _files],
  bool dark = false,
  bool stacked = true,
}) {
  _transports.clear();
  AppStore.setFlag('onboarding_completed', true);
  AppStore.saveSettings(
    AppSettings(
      theme: dark ? ThemeMode.dark : ThemeMode.light,
      verticalLayout: stacked,
    ),
  );
  return AppState(
    initialServers: servers,
    transportFactory: (server) =>
        _transports[server.id] = _demoTransport(server),
  );
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 60)),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _connect(WidgetTester tester, AppState state, String id) async {
  await tester.runAsync(() async {
    await state.getSession(id)!.connect();
    await Future<void>.delayed(const Duration(milliseconds: 80));
  });
}

/// The app in a window with macOS-style traffic lights.
Future<void> _pumpApp(
  WidgetTester tester,
  AppState state, {
  required bool dark,
  Size size = _windowSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final key = GlobalKey();
  _captureKey = key;
  await tester.pumpWidget(
    RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: RocketTheme.data(dark),
        builder: (context, child) => AppScope(
          state: state,
          child: RocketTheme(dark: dark, child: child!),
        ),
        home: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              RocketApp(
                state: state,
                chrome: const WindowChrome(leftInset: 72),
              ),
              const Positioned(left: 12, top: 9, child: _TrafficLights()),
            ],
          ),
        ),
      ),
    ),
  );
  await _settle(tester);
}

GlobalKey? _captureKey;

class _TrafficLights extends StatelessWidget {
  const _TrafficLights();

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      for (final c in const [
        Color(0xFFFF5F57),
        Color(0xFFFEBC2E),
        Color(0xFF28C840),
      ])
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
    ],
  );
}

Future<void> _capture(WidgetTester tester, String name) async {
  await _settle(tester);
  await tester.runAsync(() async {
    final boundary =
        _captureKey!.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File('$_outDir/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
  // ignore: avoid_print
  print('wrote $_outDir/$name.png');
}

// ---------------------------------------------------------------------------------------------------------------

void main() {
  late Directory home;

  setUpAll(() async {
    if (_generate) await _loadFonts();
  });

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-shots');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  testWidgets('docs screenshots', (tester) async {
    addTearDown(tester.view.reset);
    // The app is a desktop app: render it as one (no primary scroll controllers on vertical scroll views).
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    // ---- Welcome: no servers yet
    var state = _newState(servers: const []);
    await _pumpApp(tester, state, dark: false);
    await _capture(tester, 'welcome');

    // ---- First-run tour
    state = _newState();
    AppStore.setFlag('onboarding_completed', null);
    state = AppState(
      initialServers: const [],
      transportFactory: _demoTransport,
    );
    await _pumpApp(tester, state, dark: false);
    state.modal = const ModalOnboarding();
    await _capture(tester, 'onboarding');
    AppStore.setFlag('onboarding_completed', true);

    // ---- Not connected
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _capture(tester, 'not-connected');

    // ---- Tools: form, with a result
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    var session = state.getSession('weather')!;
    session.selectedTool = session.tools.first;
    session.toolArguments
      ..['city'] = 'Lisbon'
      ..['days'] = 3
      ..['units'] = 'metric';
    await tester.runAsync(session.executeTool);
    await _capture(tester, 'tools');

    // ---- Tools: warnings popup
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.selectedTool = session.tools.first;
    await _settle(tester);
    await tester.tap(find.byType(BadgeIconBtn));
    await _capture(tester, 'tool-warnings');

    // ---- Tools: JSON body
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.selectedTool = session.tools.first;
    session.toolJsonMode = true;
    session.toolJsonString = '{\n  "city": "Porto",\n  "days": 5,\n  "units": "imperial",\n  "includeAlerts": true\n}';
    await _capture(tester, 'tool-json');

    // ---- Resources
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.activeTab = WorkspaceTab.resources;
    await _settle(tester);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await _capture(tester, 'resources');

    // ---- Prompts
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.activeTab = WorkspaceTab.prompts;
    session.selectedPrompt = session.prompts.firstWhere(
      (p) => p.name == 'daily-briefing',
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await _capture(tester, 'prompts');

    // ---- Traffic inspector
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.selectedTool = session.tools.first;
    session.toolArguments['city'] = 'Lisbon';
    await tester.runAsync(session.executeTool);
    session.activeTab = WorkspaceTab.inspector;
    final traffic = session.client!.trafficHistory;
    session.selectedTrafficEntry = traffic.lastWhere(
      (e) => e.formattedPayload.contains('tools/call'),
    );
    await _capture(tester, 'traffic');

    // ---- Server logs
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    for (final line in const [
      'weather-mcp 1.4.0 listening on stdio',
      'loaded 3 stations from cache',
      'station FAO-03 is offline, skipping',
      'GET /forecast city=Lisbon days=3 (12 ms)',
    ]) {
      _transports['weather']!.emitStderr(line);
    }
    state.getSession('weather')!.activeTab = WorkspaceTab.logs;
    await _capture(tester, 'logs');

    // ---- Raw JSON-RPC
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.activeTab = WorkspaceTab.raw;
    session.rawMethod = 'tools/list';
    session.rawParams = '{\n}';
    await tester.runAsync(session.sendRawJsonRpc);
    await _capture(tester, 'raw-jsonrpc');

    // ---- Add server dialog
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    state.modal = const ModalServerConfig();
    await _capture(tester, 'add-server');

    // ---- Command palette
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    await _connect(tester, state, 'weather');
    state.modal = const ModalPalette();
    await _capture(tester, 'command-palette');

    // ---- Preferences
    state = _newState();
    await _pumpApp(tester, state, dark: false);
    state.modal = const ModalSettings();
    await _capture(tester, 'preferences');

    // ---- Dark theme, side by side
    state = _newState(dark: true, stacked: false);
    await _pumpApp(tester, state, dark: true, size: const Size(1680, 860));
    await _connect(tester, state, 'weather');
    session = state.getSession('weather')!;
    session.selectedTool = session.tools.first;
    session.toolArguments
      ..['city'] = 'Lisbon'
      ..['units'] = 'metric';
    await tester.runAsync(session.executeTool);
    await _capture(tester, 'dark-side-by-side');
  }, skip: !_generate);
}
