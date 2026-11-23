import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Ambient body line height / tracking (see [T]).
const double bodyLineHeight = 24;
const double bodyLetterSpacing = 0.5;

const String monoFamily = 'Menlo';
const List<String> monoFallback = [
  'Consolas',
  'DejaVu Sans Mono',
  'Courier New',
  'monospace',
];

/// Text style for monospace text of [fontSize].
TextStyle monoStyle({
  double fontSize = 13,
  Color? color,
  FontWeight? fontWeight,
  double? height,
}) => TextStyle(
  fontFamily: monoFamily,
  fontFamilyFallback: monoFallback,
  fontSize: fontSize,
  color: color,
  fontWeight: fontWeight,
  height: height,
);

/// App text widget with a fixed line box.
class T extends StatelessWidget {
  const T(
    this.text, {
    super.key,
    this.color,
    this.size = 13,
    this.weight,
    this.mono = false,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.softWrap,
    this.textAlign,
  });

  final String text;
  final Color? color;
  final num size;
  final FontWeight? weight;
  final bool mono;
  final int? maxLines;
  final TextOverflow overflow;
  final bool? softWrap;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) => Text(
    text,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    textAlign: textAlign,
    // The ambient body style (16sp, line height 24sp, letterSpacing 0.5sp, centred line height) is only
    // overridden in size, so every `T` has a fixed 24sp line box and 0.5sp tracking.
    strutStyle: StrutStyle(
      fontSize: size.toDouble(),
      height: bodyLineHeight / size.toDouble(),
      forceStrutHeight: true,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    textHeightBehavior: const TextHeightBehavior(
      leadingDistribution: TextLeadingDistribution.even,
    ),
    style: TextStyle(
      color: color ?? context.pal.text,
      fontSize: size.toDouble(),
      height: bodyLineHeight / size.toDouble(),
      letterSpacing: bodyLetterSpacing,
      fontWeight: weight,
      fontFamily: mono ? monoFamily : null,
      fontFamilyFallback: mono ? monoFallback : null,
      decoration: TextDecoration.none,
    ),
  );
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      T(text, color: context.pal.muted, size: 11, weight: FontWeight.w600);
}

/// Small rounded label.
class Chip extends StatelessWidget {
  const Chip(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(4),
    ),
    child: T(text, color: color, size: 12, weight: FontWeight.w600),
  );
}

class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.selected,
    required this.onClick,
  });

  final String label;
  final bool selected;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Clickable(
      onClick: onClick,
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(14),
      child: HoverBuilder(
        builder: (ctx, hov) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? p.accent.withValues(alpha: 0.18)
                : (hov ? p.hover : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(14),
          ),
          // Border is painted over the content so it doesn't change the layout.
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? p.accent.withValues(alpha: 0.6) : p.border,
              width: 1,
            ),
          ),
          child: T(
            label,
            color: selected ? p.accent : p.text,
            size: 12,
            weight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}

/// A style applied over a range of text ([start, end)); later ranges override earlier ones attribute by attribute
/// (colour, bold, background).
class StyleRange {
  const StyleRange(
    this.start,
    this.end, {
    this.color,
    this.bold = false,
    this.background,
  });
  final int start;
  final int end;
  final Color? color;
  final bool bold;
  final Color? background;
}

/// Builds a [TextSpan] of [text] with [base] style and the (possibly overlapping) [ranges] applied in order.
TextSpan buildStyledSpan(String text, TextStyle base, List<StyleRange> ranges) {
  if (ranges.isEmpty || text.isEmpty) return TextSpan(text: text, style: base);
  final n = text.length;
  final col = List<int>.filled(n, 0);
  final bold = List<bool>.filled(n, false);
  final bg = List<int>.filled(n, 0);
  for (final r in ranges) {
    final s = r.start.clamp(0, n), e = r.end.clamp(0, n);
    final c = r.color?.toARGB32();
    final b = r.background?.toARGB32();
    for (var i = s; i < e; i++) {
      if (c != null) col[i] = c;
      if (r.bold) bold[i] = true;
      if (b != null) bg[i] = b;
    }
  }
  final out = <TextSpan>[];
  var start = 0;
  for (var i = 1; i <= n; i++) {
    if (i == n ||
        col[i] != col[start] ||
        bold[i] != bold[start] ||
        bg[i] != bg[start]) {
      final hasStyle = col[start] != 0 || bold[start] || bg[start] != 0;
      out.add(
        TextSpan(
          text: text.substring(start, i),
          style: hasStyle
              ? TextStyle(
                  color: col[start] != 0 ? Color(col[start]) : null,
                  fontWeight: bold[start] ? FontWeight.w600 : null,
                  backgroundColor: bg[start] != 0 ? Color(bg[start]) : null,
                )
              : null,
        ),
      );
      start = i;
    }
  }
  return TextSpan(style: base, children: out);
}
