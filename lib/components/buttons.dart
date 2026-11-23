import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Text button with optional icon. Styles: filled (default), [primary] accent fill, [outlined] transparent with a
/// border; [danger] recolours any of them. [leading] replaces [icon] with an arbitrary widget.
class Btn extends StatefulWidget {
  const Btn({
    super.key,
    required this.label,
    required this.onClick,
    this.primary = false,
    this.outlined = false,
    this.enabled = true,
    this.danger = false,
    this.icon,
    this.leading,
    this.height = CONTROL_H,
    this.fontSize,
  });

  final String label;
  final VoidCallback onClick;
  final bool primary;
  final bool outlined;
  final bool enabled;
  final bool danger;
  final IconData? icon;
  final Widget? leading;
  final double height;
  final double? fontSize;

  @override
  State<Btn> createState() => _BtnState();
}

class _BtnState extends State<Btn> {
  static const Color _onAccent = Color(0xFFFFFFFF);
  static const Color _clear = Color(0x00000000);

  bool _hov = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final enabled = widget.enabled;
    final hov = _hov && enabled;
    final tone = widget.danger ? p.err : p.accent;

    Color bg;
    Color fg;
    Color? borderColor;
    if (widget.primary) {
      bg = hov ? tone.withValues(alpha: 0.85) : tone;
      fg = _onAccent;
    } else if (widget.outlined) {
      bg = hov
          ? (widget.danger ? p.err.withValues(alpha: 0.12) : p.hover)
          : _clear;
      fg = widget.danger ? p.err : p.text;
      borderColor = hov
          ? (widget.danger ? p.err : p.accent.withValues(alpha: 0.55))
          : p.border;
    } else {
      bg = hov ? p.hover : p.field;
      fg = widget.danger ? p.err : p.text;
      borderColor = p.border;
    }
    if (!enabled) {
      bg = bg.withValues(alpha: bg.a * 0.5);
      fg = fg.withValues(alpha: 0.5);
    }
    final fontSize =
        widget.fontSize ??
        (widget.height <= 24 ? 11.0 : (widget.height <= 28 ? 11.5 : 12.5));
    final radius = BorderRadius.circular(5);
    final horizontalPadding = widget.height <= 26
        ? 8.0
        : (widget.height <= 28 ? 10.0 : 12.0);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: enabled ? widget.onClick : null,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.97 : 1,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: widget.height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            // The border is painted over the content so it doesn't change the layout.
            foregroundDecoration: borderColor == null
                ? null
                : BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 1),
                  ),
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (widget.leading != null)
                    widget.leading!
                  else if (widget.icon != null)
                    Ico(
                      widget.icon!,
                      tint: fg,
                      size: widget.height <= 24 ? 12 : 13.5,
                    ),
                  if (widget.label.isNotEmpty)
                    Flexible(
                      child: T(
                        widget.label,
                        color: fg,
                        size: fontSize,
                        weight: widget.primary
                            ? FontWeight.w600
                            : FontWeight.w500,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon-only button.
class IconBtn extends StatelessWidget {
  const IconBtn({
    super.key,
    required this.icon,
    required this.onClick,
    this.color,
    this.size = 14,
    this.boxSize = 26,
    this.active = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onClick;
  final Color? color;
  final num size;
  final num boxSize;

  /// Highlights the button with the accent colour (a toggled-on state).
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final button = Clickable(
      onClick: onClick,
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(5),
      child: HoverBuilder(
        builder: (ctx, hov) => Container(
          width: boxSize.toDouble(),
          height: boxSize.toDouble(),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active
                ? p.accent.withValues(alpha: 0.12)
                : (hov ? p.hover : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Ico(
            icon,
            tint: color ?? (active ? p.accent : (hov ? p.text : p.muted)),
            size: size.toDouble(),
          ),
        ),
      ),
    );
    final hint = tooltip;
    return hint == null ? button : Tooltip(message: hint, child: button);
  }
}

/// Checkbox without a label.
class Check extends StatelessWidget {
  const Check({
    super.key,
    required this.checked,
    required this.onChange,
    this.partial = false,
  });

  final bool checked;
  final ValueChanged<bool> onChange;
  final bool partial;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final on = checked || partial;
    return Clickable(
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(3),
      onClick: () => onChange(!checked),
      child: Container(
        width: 16,
        height: 16,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? p.accent : const Color(0x00000000),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: on ? p.accent : p.muted, width: 1),
        ),
        child: partial
            ? const Ico(Ic.dash, tint: Color(0xFF000000), size: 13)
            : checked
            ? const Ico(Ic.check, tint: Color(0xFF000000), size: 13)
            : null,
      ),
    );
  }
}

/// Checkbox with a text label.
class LabeledCheck extends StatelessWidget {
  const LabeledCheck({
    super.key,
    required this.label,
    required this.checked,
    required this.onChange,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) => Clickable(
    onClick: () => onChange(!checked),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Check(checked: checked, onChange: onChange),
          T(label),
        ],
      ),
    ),
  );
}
