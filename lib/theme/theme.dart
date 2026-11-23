// ignore_for_file: constant_identifier_names
import 'package:material_ui/material_ui.dart';

/// Colour palette for the light and dark themes.
class Pal {
  const Pal({
    required this.dark,
    required this.bg,
    required this.panel,
    required this.field,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.ok,
    required this.err,
    required this.warn,
    required this.hover,
    required this.selected,
    required this.syntaxKey,
    required this.syntaxString,
    required this.syntaxNumber,
    required this.syntaxKeyword,
    required this.syntaxComment,
  });

  final bool dark;
  final Color bg;
  final Color panel;
  final Color field;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color ok;
  final Color err;
  final Color warn;
  final Color hover;
  final Color selected;
  final Color syntaxKey;
  final Color syntaxString;
  final Color syntaxNumber;
  final Color syntaxKeyword;
  final Color syntaxComment;

  /// The palette in effect for [context] (dark palette when no [PalScope] is above).
  static Pal of(BuildContext context) {
    final s = context.dependOnInheritedWidgetOfExactType<PalScope>();
    return s?.pal ?? DarkPal;
  }
}

extension PalContext on BuildContext {
  Pal get pal => Pal.of(this);
}

const DarkPal = Pal(
  dark: true,
  bg: Color(0xFF1B1D21),
  panel: Color(0xFF23262B),
  field: Color(0xFF181A1E),
  border: Color(0xFF34383F),
  text: Color(0xFFE4E6EA),
  muted: Color(0xFF8B929C),
  accent: Color(0xFF8B7CFF),
  ok: Color(0xFF4CC38A),
  err: Color(0xFFEF5B5B),
  warn: Color(0xFFF0A04B),
  hover: Color(0xFF2C3036),
  selected: Color(0xFF30343B),
  syntaxKey: Color(0xFF7CB7FF),
  syntaxString: Color(0xFF9FD98F),
  syntaxNumber: Color(0xFFF2A65A),
  syntaxKeyword: Color(0xFFC792EA),
  syntaxComment: Color(0xFF6B7380),
);

const LightPal = Pal(
  dark: false,
  bg: Color(0xFFF6F7F9),
  panel: Color(0xFFFFFFFF),
  field: Color(0xFFFFFFFF),
  border: Color(0xFFD9DDE3),
  text: Color(0xFF1F2328),
  muted: Color(0xFF6B7280),
  accent: Color(0xFF5B35D6),
  ok: Color(0xFF15935B),
  err: Color(0xFFD13438),
  warn: Color(0xFFC2650A),
  hover: Color(0xFFEEF0F3),
  selected: Color(0xFFE4E8EE),
  syntaxKey: Color(0xFF0B63CE),
  syntaxString: Color(0xFF1A7F37),
  syntaxNumber: Color(0xFFB45309),
  syntaxKeyword: Color(0xFF8250DF),
  syntaxComment: Color(0xFF8C959F),
);

/// Provides the active palette to descendants. An [InheritedTheme] so popups/dialogs capture it too.
class PalScope extends InheritedTheme {
  const PalScope({super.key, required this.pal, required super.child});
  final Pal pal;

  @override
  bool updateShouldNotify(PalScope oldWidget) => pal != oldWidget.pal;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      PalScope(pal: pal, child: child);
}

/// Colour used for an HTTP method name.
Color methodColor(String m, Pal p) {
  switch (m.toUpperCase()) {
    case 'GET':
      return p.dark ? const Color(0xFF4CC38A) : const Color(0xFF15935B);
    case 'POST':
      return p.dark ? const Color(0xFFF5C451) : const Color(0xFFB7791F);
    case 'PUT':
      return p.dark ? const Color(0xFF6BA6FF) : const Color(0xFF1E6BD6);
    case 'PATCH':
      return p.dark ? const Color(0xFFB794F6) : const Color(0xFF7C3AED);
    case 'DELETE':
      return p.dark ? const Color(0xFFEF5B5B) : const Color(0xFFD13438);
    case 'WS':
      return p.dark ? const Color(0xFF38BDF8) : const Color(0xFF0B7FB8);
    case 'GQL':
      return p.dark ? const Color(0xFFF472B6) : const Color(0xFFC21E8C);
    default:
      return p.muted;
  }
}

/// Colour used for an HTTP status code.
Color statusColor(int code, Pal p) {
  if (code >= 200 && code <= 299) return p.ok;
  if (code >= 300 && code <= 399) return p.accent;
  if (code >= 400 && code <= 499) return p.warn;
  return p.err;
}

/// Material theme with the app colour-scheme mapping
/// plus the [Pal] for descendants. Use [RocketTheme.data] for `MaterialApp.theme` / `darkTheme`.
class RocketTheme extends StatelessWidget {
  const RocketTheme({super.key, required this.dark, required this.child});

  final bool dark;
  final Widget child;

  static Pal palFor(bool dark) => dark ? DarkPal : LightPal;

  static ColorScheme colorScheme(bool dark) {
    final p = palFor(dark);
    // Material 3 baseline values for the roles the scheme leaves at their defaults.
    return dark
        ? ColorScheme(
            brightness: Brightness.dark,
            primary: p.accent,
            onPrimary: const Color(0xFF000000),
            secondary: const Color(0xFFCCC2DC),
            onSecondary: const Color(0xFF332D41),
            error: const Color(0xFFF2B8B5),
            onError: const Color(0xFF601410),
            surface: p.panel,
            onSurface: p.text,
            surfaceContainer: p.panel,
            surfaceContainerHigh: p.panel,
            surfaceContainerHighest: p.panel,
            onSurfaceVariant: p.muted,
            outline: p.border,
          )
        : ColorScheme(
            brightness: Brightness.light,
            primary: p.accent,
            onPrimary: const Color(0xFFFFFFFF),
            secondary: const Color(0xFF625B71),
            onSecondary: const Color(0xFFFFFFFF),
            error: const Color(0xFFB3261E),
            onError: const Color(0xFFFFFFFF),
            surface: p.panel,
            onSurface: p.text,
            surfaceContainer: p.panel,
            surfaceContainerHigh: p.panel,
            surfaceContainerHighest: p.panel,
            onSurfaceVariant: p.muted,
            outline: p.border,
          );
  }

  static ThemeData data(bool dark) {
    final p = palFor(dark);
    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme(dark),
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accent.withValues(alpha: 0.4),
        selectionHandleColor: p.accent,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(p.muted.withValues(alpha: 0.45)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: data(dark),
    child: PalScope(pal: palFor(dark), child: child),
  );
}
