import 'dart:io' as io;

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:rocket_mcp/core/logging/log.dart';
import 'package:url_launcher/url_launcher.dart';

/// Desktop integration: default browser / file manager and the clipboard.
final class Platform {
  Platform._();

  static final bool isMac = io.Platform.isMacOS;
  static final bool isWindows = io.Platform.isWindows;
  static final bool isLinux = io.Platform.isLinux;

  /// Opens a web address in the default browser.
  static Future<void> openUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e, st) {
      Log.warning('platform', 'Cannot open $url', e, st);
    }
  }

  /// Label for the reveal action in the platform's file manager.
  static String get revealLabel => isMac
      ? 'Show in Finder'
      : (isWindows ? 'Show in Explorer' : 'Show in file manager');

  /// Shows [path] in the file manager: its parent folder opens with the item selected.
  static Future<void> reveal(String path) async {
    try {
      if (isMac) {
        await io.Process.run('open', ['-R', path]);
      } else if (isWindows) {
        await io.Process.run('explorer', ['/select,', path]);
      } else {
        await io.Process.run('xdg-open', [p.dirname(path)]);
      }
    } catch (e, st) {
      Log.warning('platform', 'Cannot reveal $path', e, st);
    }
  }

  static Future<void> copy(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (e, st) {
      Log.warning('platform', 'Cannot write to the clipboard', e, st);
    }
  }
}
