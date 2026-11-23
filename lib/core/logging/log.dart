// ignore_for_file: constant_identifier_names

import 'dart:io';

/// Severity of a log line.
enum LogLevel { DEBUG, INFO, WARNING, ERROR }

/// The one place the app records what happened. Every line carries the level, the feature that logged it and the
/// operation, e.g. `WARNING [storage] Cannot read settings.json: ...`, and failures keep their stack trace.
///
/// Never pass passwords, tokens, secrets or request / response bodies: log identifiers and file names only.
class Log {
  Log._();

  static const int _maxLogBytes = 1000000;

  static LogLevel minimumLevel = LogLevel.INFO;
  static String? _file;

  /// Also writes to [path] (kept below 1 MB: the previous file is moved to `<name>.old` when it fills up).
  static void writeTo(String path) => _file = path;

  static void debug(String tag, String message) =>
      log(LogLevel.DEBUG, tag, message, null);
  static void info(String tag, String message) =>
      log(LogLevel.INFO, tag, message, null);
  static void warning(
    String tag,
    String message, [
    Object? cause,
    StackTrace? stack,
  ]) => log(LogLevel.WARNING, tag, message, cause, stack);
  static void error(
    String tag,
    String message, [
    Object? cause,
    StackTrace? stack,
  ]) => log(LogLevel.ERROR, tag, message, cause, stack);

  /// Runs [block]; on failure logs [message] at WARNING and returns [fallback] (for work that is allowed to fail, such as optional files).
  static T orElse<T>(
    String tag,
    String message,
    T fallback,
    T Function() block,
  ) {
    try {
      return block();
    } catch (e, st) {
      warning(tag, '$message: ${_describe(e)}', e, st);
      return fallback;
    }
  }

  static String _describe(Object e) {
    var s = e.toString();
    for (final pre in const [
      'Exception: ',
      'Bad state: ',
      'Invalid argument(s): ',
      'Invalid argument: ',
    ]) {
      if (s.startsWith(pre)) {
        s = s.substring(pre.length);
        break;
      }
    }
    return s;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _timestamp() {
    final t = DateTime.now();
    return '${t.year}-${_two(t.month)}-${_two(t.day)} ${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}.${t.millisecond.toString().padLeft(3, '0')}';
  }

  static void log(
    LogLevel level,
    String tag,
    String message,
    Object? cause, [
    StackTrace? stack,
  ]) {
    if (level.index < minimumLevel.index) return;
    final b = StringBuffer()
      ..write(_timestamp())
      ..write(' ')
      ..write(level.name)
      ..write(' [')
      ..write(tag)
      ..write('] ')
      ..write(message);
    if (cause != null) {
      b.write('\n');
      b.write(
        '${cause.runtimeType}: ${_describe(cause)}${stack == null ? '' : '\n${stack.toString().trimRight()}'}',
      );
    }
    final line = b.toString();
    stderr.writeln(line);
    _appendToFile(line);
  }

  static void _appendToFile(String line) {
    final target = _file;
    if (target == null) return;
    try {
      final f = File(target);
      if (f.existsSync() && f.lengthSync() > _maxLogBytes) {
        f.renameSync('$target.old');
      }
      f.writeAsStringSync('$line\n', mode: FileMode.append);
    } catch (_) {
      // the log itself must never fail the app, and there is nowhere else to report it
    }
  }
}
