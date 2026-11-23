import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Text button with optional icon and primary/danger styling.
class Btn extends StatefulWidget {
  const Btn({
    super.key,
    required this.label,
    required this.onClick,
    this.primary = false,
    this.enabled = true,
    this.danger = false,
    this.icon,
  });

  final String label;
  final VoidCallback onClick;
  final bool primary;
  final bool enabled;
  final bool danger;
  final IconData? icon;

  @override
  State<Btn> createState() => _BtnState();
}

class _BtnState extends State<Btn> {
  bool _hov = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final enabled = widget.enabled, primary = widget.primary;
    final base = primary ? p.accent : p.hover;
    final bg = !enabled
        ? base.withValues(alpha: 0.4)
        : _hov && primary
        ? Color.lerp(base, const Color(0xFFFFFFFF), 0.18)!
        : _hov
        ? p.selected
        : base;
    final fg = primary
        ? const Color(0xFF000000)
        : (widget.danger ? p.err : p.text);
    final c = enabled ? fg : fg.withValues(alpha: 0.5);
    final radius = BorderRadius.circular(5);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: enabled ? widget.onClick : null,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.96 : 1,
          duration: const Duration(milliseconds: 80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: CONTROL_H,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: bg, borderRadius: radius),
            // Border is painted over the content so it doesn't change the layout.
            foregroundDecoration: !primary
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(
                      color: _hov && enabled
                          ? p.muted.withValues(alpha: 0.6)
                          : p.border,
                      width: 1,
                    ),
                  )
                : null,
            child: Center(
              widthFactor: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  if (widget.icon != null) Ico(widget.icon!, tint: c, size: 15),
                  if (widget.label.isNotEmpty)
                    T(
                      widget.label,
                      color: c,
                      size: 13,
                      weight: primary ? FontWeight.w600 : null,
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
    this.size = 16,
  });

  final IconData icon;
  final VoidCallback onClick;
  final Color? color;
  final num size;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Clickable(
      onClick: onClick,
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(5),
      child: HoverBuilder(
        builder: (ctx, hov) => Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hov ? p.hover : const Color(0x00000000),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Ico(
            icon,
            tint: hov ? p.text : (color ?? p.muted),
            size: size.toDouble(),
          ),
        ),
      ),
    );
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
