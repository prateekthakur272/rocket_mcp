import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/app/title_menu_state.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/mcp/transports.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/core/storage/server_store.dart';

/// The single owner of application state: settings, dialogs, MCP servers and sessions.
class AppState extends ChangeNotifier {
  AppState({List<McpServerConfig>? initialServers, this.transportFactory}) {
    titleMenu.addListener(notifyListeners);
    settings = AppStore.loadSettings();
    final layout = AppStore.loadLayout();
    _sidebarWidth = layout.sidebarWidth.clamp(minSidebarWidth, maxSidebarWidth);
    _splitFraction = layout.splitFraction.clamp(
      minSplitFraction,
      maxSplitFraction,
    );
    _listPaneWidth = layout.listPaneWidth.clamp(
      minListPaneWidth,
      maxListPaneWidth,
    );
    _sidebarVisible = layout.sidebarVisible;

    // Load servers
    _servers = List.of(initialServers ?? ServerStore.loadServers());
    for (final s in _servers) {
      _initSession(s);
    }
    if (_servers.isNotEmpty) {
      final savedId = layout.activeServerId;
      if (savedId != null && _servers.any((s) => s.id == savedId)) {
        _activeServerId = savedId;
      } else {
        _activeServerId = _servers.first.id;
      }
    }

    // Only auto-connect the selected server on launch if autoConnect is enabled
    if (settings.autoConnect && _activeServerId != null) {
      final session = _sessions[_activeServerId];
      if (session != null && session.status == McpServerStatus.disconnected) {
        session.connect();
      }
    }

    // Launch initial onboarding tour on first run
    if (AppStore.needsOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_modal == null) {
          modal = const ModalOnboarding();
        }
      });
    }
  }

  /// Supplies the transport a server connects through, instead of the one its configuration describes. Tests and the
  /// documentation screenshots use it to talk to an in-memory demo server; the app leaves it null.
  final McpTransport? Function(McpServerConfig server)? transportFactory;

  static const double minSidebarWidth = 0.12;
  static const double maxSidebarWidth = 0.45;
  static const Duration toastDuration = Duration(milliseconds: 3500);

  final TitleMenuState titleMenu = TitleMenuState();

  late AppSettings settings;

  Modal? _modal;
  Modal? get modal => _modal;
  set modal(Modal? value) {
    _modal = value;
    notifyListeners();
  }

  /// Toggles the palette: opens it, or closes it when it is already showing.
  void togglePalette() =>
      modal = modal is ModalPalette ? null : const ModalPalette();

  String? _toast;
  String? get toast => _toast;
  Timer? _toastTimer;

  /// Shows a short message at the bottom of the window.
  void showToast(String message) {
    _toast = message;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(toastDuration, () {
      _toast = null;
      notifyListeners();
    });
  }

  String? _availableUpdate;
  String? get availableUpdate => _availableUpdate;
  set availableUpdate(String? version) {
    _availableUpdate = version;
    notifyListeners();
  }

  static const double minListPaneWidth = 160;
  static const double maxListPaneWidth = 560;

  static const double minSplitFraction = 0.12;
  static const double maxSplitFraction = 0.88;

  late double _splitFraction;

  /// The share of the workspace taken by the request pane; the response pane has the rest.
  double get splitFraction => _splitFraction;
  set splitFraction(double value) {
    _splitFraction = value.clamp(minSplitFraction, maxSplitFraction);
    notifyListeners();
  }

  late double _listPaneWidth;

  /// Width in dp of the Tools / Resources / Prompts list, shared by all three so it keeps its size across tabs.
  double get listPaneWidth => _listPaneWidth;
  set listPaneWidth(double value) {
    _listPaneWidth = value.clamp(minListPaneWidth, maxListPaneWidth);
    notifyListeners();
  }

  late double _sidebarWidth;
  double get sidebarWidth => _sidebarWidth;
  set sidebarWidth(double value) {
    _sidebarWidth = value.clamp(minSidebarWidth, maxSidebarWidth);
    notifyListeners();
  }

  late bool _sidebarVisible;
  bool get sidebarVisible => _sidebarVisible;
  set sidebarVisible(bool value) {
    _sidebarVisible = value;
    notifyListeners();
  }

  String? _prefsSection;
  String? get prefsSection => _prefsSection;
  set prefsSection(String? value) {
    _prefsSection = value;
    notifyListeners();
  }

  // ==========================================
  // MCP Servers & Sessions
  // ==========================================

  List<McpServerConfig> _servers = [];
  List<McpServerConfig> get servers => List.unmodifiable(_servers);

  final Map<String, McpSession> _sessions = {};
  String? _activeServerId;
  String? get activeServerId => _activeServerId;

  McpServerConfig? get activeServer {
    final id = _activeServerId;
    if (id == null) return null;
    return _servers.where((s) => s.id == id).firstOrNull;
  }

  McpSession? get activeSession {
    final id = _activeServerId;
    if (id == null) return null;
    return _sessions[id];
  }

  McpSession? getSession(String id) => _sessions[id];

  /// Pings the active server and displays toast feedback.
  Future<Duration?> pingActiveServer({bool feedback = true}) async {
    return activeSession?.ping(feedback: feedback);
  }

  void _initSession(McpServerConfig server) {
    final session = McpSession(
      config: server,
      transportOverride: transportFactory?.call(server),
      onToast: showToast,
    );
    session.addListener(notifyListeners);
    _sessions[server.id] = session;
    if (server.autoConnect) {
      session.connect();
    }
  }

  void selectServer(String id) {
    if (_activeServerId != id && _sessions.containsKey(id)) {
      _activeServerId = id;
      persist();
      if (settings.autoConnect) {
        final session = _sessions[id];
        if (session != null && session.status == McpServerStatus.disconnected) {
          session.connect();
        }
      }
      notifyListeners();
    }
  }

  void addServer(McpServerConfig server) {
    _servers.add(server);
    _initSession(server);
    _activeServerId = server.id;
    persist();
    ServerStore.saveServers(_servers);
    if (settings.autoConnect) {
      _sessions[server.id]?.connect();
    }
    notifyListeners();
  }

  void updateServer(McpServerConfig server) {
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index >= 0) {
      _servers[index] = server;
      _sessions[server.id]?.updateConfig(server);
      ServerStore.saveServers(_servers);
      notifyListeners();
    }
  }

  void deleteServer(String id) {
    final session = _sessions.remove(id);
    session?.removeListener(notifyListeners);
    session?.dispose();

    _servers.removeWhere((s) => s.id == id);
    ServerStore.saveServers(_servers);

    if (_activeServerId == id) {
      _activeServerId = _servers.isNotEmpty ? _servers.first.id : null;
    }
    persist();
    notifyListeners();
  }

  void duplicateServer(String id) {
    final target = _servers.where((s) => s.id == id).firstOrNull;
    if (target == null) return;

    final copy = target.copyWith(
      id: 'server_${DateTime.now().microsecondsSinceEpoch}',
      name: '${target.name} (Copy)',
    );
    addServer(copy);
  }

  void importServers(List<McpServerConfig> imported) {
    if (imported.isEmpty) return;
    for (final s in imported) {
      _servers.add(s);
      _initSession(s);
    }
    _activeServerId = imported.first.id;
    ServerStore.saveServers(_servers);
    notifyListeners();
  }

  void updateSettings(AppSettings next) {
    if (next == settings) return;
    final prevAutoConnect = settings.autoConnect;
    settings = next;
    AppStore.saveSettings(next);
    if (!prevAutoConnect && next.autoConnect) {
      if (activeSession?.status == McpServerStatus.disconnected) {
        activeSession?.connect();
      }
    }
    notifyListeners();
  }

  void toggleLayout() => updateSettings(
    settings.copyWith(verticalLayout: !settings.verticalLayout),
  );

  void zoom(int delta) {
    final size = delta == 0
        ? AppSettings.defaultFontSize
        : (settings.fontSize + delta).clamp(
            AppSettings.minFontSize,
            AppSettings.maxFontSize,
          );
    updateSettings(settings.copyWith(fontSize: size));
  }

  List<Object?> layoutSnapshot() => [
    sidebarWidth,
    sidebarVisible,
    listPaneWidth,
    splitFraction,
    _activeServerId,
  ];

  void persist() => AppStore.saveLayout(
    SavedLayout(
      sidebarWidth: sidebarWidth,
      sidebarVisible: sidebarVisible,
      listPaneWidth: listPaneWidth,
      splitFraction: splitFraction,
      activeServerId: _activeServerId,
    ),
  );

  @override
  void dispose() {
    _toastTimer?.cancel();
    titleMenu.removeListener(notifyListeners);
    titleMenu.dispose();
    for (final s in _sessions.values) {
      s.removeListener(notifyListeners);
      s.dispose();
    }
    _sessions.clear();
    super.dispose();
  }
}

/// Hands [AppState] to widgets: `AppScope.of(context)` rebuilds on every change, `AppScope.read(context)` does not.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
