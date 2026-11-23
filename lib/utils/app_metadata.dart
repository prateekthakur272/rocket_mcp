import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:rocket_mcp/core/logging/log.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// What the running app reports about itself, read from the platform at startup instead of being written down a
/// second time. Add new runtime-read fields here.
///
/// The version is set only by `version:` in pubspec.yaml; the build passes it to the app bundle (macOS), the
/// executable (Windows) and the bundled build info (Linux), and this reads it back. The fixed identity (name and
/// credits) lives in `AppConfig`.
///
/// Call [load] once at startup, before anything shows these values.
final class AppMetadata {
  const AppMetadata._();

  /// Shown when the version could not be read (and in tests that did not load one).
  static const String unknown = 'dev';

  /// The id the app is built with (macOS PRODUCT_BUNDLE_IDENTIFIER, Linux APPLICATION_ID). Used where the platform
  /// does not report one.
  static const String fallbackBundleId = 'dev.prateekthakur.rocketmcp';

  static String _version = unknown;
  static String _build = '';
  static String _bundleId = fallbackBundleId;

  /// Reads the metadata from the platform. Never throws: on failure the fallbacks stay.
  static Future<void> load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.trim().isNotEmpty) _version = info.version.trim();
      _build = info.buildNumber.trim();
      _bundleId = _resolveBundleId(info.packageName);
    } catch (e, st) {
      Log.warning('app', 'Cannot read the app metadata', e, st);
    }
  }

  /// The platform's package name is a reverse-domain id on macOS (`dev.prateekthakur.rocketmcp`) but the exe's
  /// internal name on Windows (`Rocket MCP`) and the pubspec name on Linux (`rocket_mcp`). Only a reverse-domain
  /// value is a bundle id; anything else falls back to [fallbackBundleId].
  static String _resolveBundleId(String platformValue) {
    final v = platformValue.trim();
    return RegExp(r'^[A-Za-z0-9_-]+(\.[A-Za-z0-9_-]+)+$').hasMatch(v)
        ? v
        : fallbackBundleId;
  }

  /// `2.1.0`
  static String get version => _version;

  /// The build number after the `+` (`1` for `2.1.0+1`); empty when there is none.
  static String get build => _build;

  /// `2.1.0+1`, or just the version when there is no build number.
  static String get full => _build.isEmpty ? _version : '$_version+$_build';

  /// `dev.prateekthakur.rocketmcp`: the platform's bundle id when it reports one, otherwise [fallbackBundleId].
  static String get bundleId => _bundleId;

  /// Forgets what was loaded.
  @visibleForTesting
  static void reset() {
    _version = unknown;
    _build = '';
    _bundleId = fallbackBundleId;
  }
}
