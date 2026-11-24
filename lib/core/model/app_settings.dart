import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/utils/app_metadata.dart';

/// Which colour scheme the interface uses.
enum ThemeMode {
  system('system', 'System'),
  light('light', 'Light'),
  dark('dark', 'Dark');

  const ThemeMode(this.id, this.label);
  final String id;
  final String label;

  bool isDark(bool systemIsDark) => switch (this) {
    ThemeMode.system => systemIsDark,
    ThemeMode.light => false,
    ThemeMode.dark => true,
  };

  static ThemeMode? of(String? id) {
    for (final mode in ThemeMode.values) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

/// The user's preferences, saved in `settings.json`.
class AppSettings {
  const AppSettings({
    this.theme = ThemeMode.system,
    this.timeoutMs = 30000,
    this.sslVerify = true,
    this.proxyEnabled = false,
    this.proxyHost = '',
    this.proxyPort = 8080,
    this.userAgent = '',
    this.verticalLayout = true,
    this.fontSize = defaultFontSize,
    this.autoSave = false,
    this.autoConnect = false,
  });

  static const int defaultFontSize = 13;
  static const int minFontSize = 10;
  static const int maxFontSize = 20;

  final ThemeMode theme;
  final int timeoutMs;
  final bool sslVerify;
  final bool proxyEnabled;
  final String proxyHost;
  final int proxyPort;

  /// A custom User-Agent; empty means "use the default". Read it through [effectiveUserAgent].
  final String userAgent;

  /// True stacks the request above the response; false puts them side by side.
  final bool verticalLayout;
  final int fontSize;
  final bool autoSave;
  final bool autoConnect;

  /// `Rocket MCP/1.0.0`: the app name and the version read at startup.
  static String get defaultUserAgent =>
      '${AppConfig.NAME}/${AppMetadata.version}';

  String get effectiveUserAgent =>
      userAgent.trim().isEmpty ? defaultUserAgent : userAgent.trim();

  AppSettings copyWith({
    ThemeMode? theme,
    int? timeoutMs,
    bool? sslVerify,
    bool? proxyEnabled,
    String? proxyHost,
    int? proxyPort,
    String? userAgent,
    bool? verticalLayout,
    int? fontSize,
    bool? autoSave,
    bool? autoConnect,
  }) => AppSettings(
    theme: theme ?? this.theme,
    timeoutMs: timeoutMs ?? this.timeoutMs,
    sslVerify: sslVerify ?? this.sslVerify,
    proxyEnabled: proxyEnabled ?? this.proxyEnabled,
    proxyHost: proxyHost ?? this.proxyHost,
    proxyPort: proxyPort ?? this.proxyPort,
    userAgent: userAgent ?? this.userAgent,
    verticalLayout: verticalLayout ?? this.verticalLayout,
    fontSize: fontSize ?? this.fontSize,
    autoSave: autoSave ?? this.autoSave,
    autoConnect: autoConnect ?? this.autoConnect,
  );

  Map<String, Object?> toJson() => {
    'theme': theme.id,
    'timeoutMs': timeoutMs,
    'sslVerify': sslVerify,
    'proxyEnabled': proxyEnabled,
    'proxyHost': proxyHost,
    'proxyPort': proxyPort,
    'userAgent': userAgent,
    'verticalLayout': verticalLayout,
    'fontSize': fontSize,
    'autoSave': autoSave,
    'autoConnect': autoConnect,
  };

  /// Reads settings written by [toJson]; a missing or wrongly typed field keeps its default.
  factory AppSettings.fromJson(Map<String, Object?> json) {
    const d = AppSettings();
    int? number(String k) => json[k] is num ? (json[k] as num).toInt() : null;
    bool? flag(String k) => json[k] is bool ? json[k] as bool : null;
    String? text(String k) => json[k] is String ? json[k] as String : null;
    return AppSettings(
      theme: ThemeMode.of(text('theme')) ?? d.theme,
      timeoutMs: number('timeoutMs') ?? d.timeoutMs,
      sslVerify: flag('sslVerify') ?? d.sslVerify,
      proxyEnabled: flag('proxyEnabled') ?? d.proxyEnabled,
      proxyHost: text('proxyHost') ?? d.proxyHost,
      proxyPort: number('proxyPort') ?? d.proxyPort,
      userAgent: text('userAgent') ?? d.userAgent,
      verticalLayout: flag('verticalLayout') ?? d.verticalLayout,
      fontSize: (number('fontSize') ?? d.fontSize).clamp(
        minFontSize,
        maxFontSize,
      ),
      autoSave: flag('autoSave') ?? d.autoSave,
      autoConnect: flag('autoConnect') ?? d.autoConnect,
    );
  }
}
