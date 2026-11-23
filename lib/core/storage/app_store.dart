import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:rocket_mcp/core/logging/log.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/utils/paths.dart';

/// Window size and position, remembered between launches.
class WindowGeometry {
  const WindowGeometry(
    this.width,
    this.height, [
    this.x,
    this.y,
    this.maximized = false,
  ]);

  final double width;
  final double height;
  final double? x;
  final double? y;
  final bool maximized;

  WindowGeometry copyWith({bool? maximized}) =>
      WindowGeometry(width, height, x, y, maximized ?? this.maximized);
}

/// The panel sizes the user left the window with (sidebar, list pane, request / response split), restored on the
/// next launch.
class SavedLayout {
  const SavedLayout({
    this.sidebarWidth = 0.22,
    this.sidebarVisible = true,
    this.listPaneWidth = defaultListPaneWidth,
    this.splitFraction = defaultSplitFraction,
  });

  static const double defaultListPaneWidth = 220;
  static const double defaultSplitFraction = 0.5;

  final double sidebarWidth;
  final bool sidebarVisible;

  /// Width in dp of the Tools / Resources / Prompts list.
  final double listPaneWidth;

  /// The share of the workspace taken by the request pane (the rest is the response pane).
  final double splitFraction;
}

/// Everything the app keeps on disk, all in one data folder (`~/.rocketmcp`): settings, layout, small flags, window
/// geometry and the log. Paths come from [Paths]; the platform preference store is deliberately not used, so the
/// user can see and delete everything the app remembers.
final class AppStore {
  const AppStore._();

  static const String _tag = 'storage';

  /// Overrides the data folder; set before first use (tests).
  static String? homeOverride;

  static String? _resolvedDir;

  static String get dir {
    final cached = _resolvedDir;
    if (cached != null && homeOverride == null) return cached;
    final d = homeOverride ?? Paths.dataDir;
    Directory(d).createSync(recursive: true);
    Log.writeTo(Paths.logFile(d));
    _resolvedDir = d;
    return d;
  }

  static String get _settingsFile => p.join(dir, 'settings.json');
  static String get _layoutFile => p.join(dir, 'layout.json');
  static String get _prefsFile => p.join(dir, 'prefs.json');
  static String get _windowFile => p.join(dir, 'window.json');

  /// True when nothing has been saved yet: a fresh install.
  static bool isFirstRun() =>
      !File(_settingsFile).existsSync() && !File(_layoutFile).existsSync();

  /// True when the user hasn't completed or dismissed the onboarding tour yet.
  static bool get needsOnboarding => flag('onboarding_completed') != true;

  static AppSettings loadSettings() {
    final json = _readJson(_settingsFile);
    return json == null ? const AppSettings() : AppSettings.fromJson(json);
  }

  static void saveSettings(AppSettings settings) =>
      _writeJson(_settingsFile, settings.toJson());

  static SavedLayout loadLayout() {
    final json = _readJson(_layoutFile);
    if (json == null) return const SavedLayout();
    final width = json['sidebarWidth'];
    final visible = json['sidebarVisible'];
    final listWidth = json['listPaneWidth'];
    final split = json['splitFraction'];
    return SavedLayout(
      sidebarWidth: width is num ? width.toDouble() : 0.22,
      sidebarVisible: visible is bool ? visible : true,
      listPaneWidth: listWidth is num
          ? listWidth.toDouble()
          : SavedLayout.defaultListPaneWidth,
      splitFraction: split is num
          ? split.toDouble()
          : SavedLayout.defaultSplitFraction,
    );
  }

  static void saveLayout(SavedLayout layout) => _writeJson(_layoutFile, {
    'sidebarWidth': layout.sidebarWidth,
    'sidebarVisible': layout.sidebarVisible,
    'listPaneWidth': layout.listPaneWidth,
    'splitFraction': layout.splitFraction,
  });

  /// A small named value the app remembers that is neither a setting nor layout, for example the update version the
  /// user dismissed.
  static Object? flag(String key) => (_readJson(_prefsFile) ?? const {})[key];

  static String? flagString(String key) {
    final value = flag(key);
    return value is String ? value : null;
  }

  /// Saves a flag; a null [value] removes it. Other flags are kept.
  static void setFlag(String key, Object? value) {
    final flags = Map<String, Object?>.of(_readJson(_prefsFile) ?? const {});
    if (value == null) {
      if (flags.remove(key) == null) return;
    } else {
      flags[key] = value;
    }
    _writeJson(_prefsFile, flags);
  }

  static WindowGeometry? loadWindow() {
    final json = _readJson(_windowFile);
    if (json == null) return null;
    final width = json['width'], height = json['height'];
    if (width is! num || height is! num || width < 200 || height < 150) {
      return null;
    }
    final x = json['x'], y = json['y'], maximized = json['maximized'];
    return WindowGeometry(
      width.toDouble(),
      height.toDouble(),
      x is num ? x.toDouble() : null,
      y is num ? y.toDouble() : null,
      maximized is bool ? maximized : false,
    );
  }

  static void saveWindow(WindowGeometry g) => _writeJson(_windowFile, {
    'width': g.width,
    'height': g.height,
    'maximized': g.maximized,
    if (g.x != null) 'x': g.x,
    if (g.y != null) 'y': g.y,
  });

  static Map<String, Object?>? _readJson(String file) {
    try {
      final text = File(file).readAsStringSync();
      final decoded = jsonDecode(text);
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } on PathNotFoundException {
      return null;
    } catch (e, st) {
      Log.warning(
        _tag,
        'Cannot read ${p.basename(file)}, using defaults',
        e,
        st,
      );
      return null;
    }
  }

  /// Writing is best effort (a read-only home must not crash the app) but a failure is always logged.
  static void _writeJson(String file, Map<String, Object?> json) {
    try {
      File(file)
          .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(json));
    } catch (e, st) {
      Log.error(_tag, 'Cannot write ${p.basename(file)}', e, st);
    }
  }
}
