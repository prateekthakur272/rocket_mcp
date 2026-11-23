// ignore_for_file: constant_identifier_names
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

const List<String> TEXT_FORMATS = ['JSON', 'HTML', 'XML', 'JavaScript'];
const List<String> BINARY_FORMATS = ['Raw', 'Hex', 'Base64'];

IconData formatIcon(String f) {
  switch (f) {
    case 'JSON':
      return Ic.fmtJson;
    case 'HTML':
      return Ic.fmtHtml;
    case 'XML':
      return Ic.fmtXml;
    case 'JavaScript':
      return Ic.fmtJs;
    case 'Hex':
      return Ic.fmtHex;
    case 'Base64':
      return Ic.fmtB64;
    default:
      return Ic.fmtRaw;
  }
}

class Toggle extends StatelessWidget {
  const Toggle({
    super.key,
    required this.checked,
    required this.onChange,
    this.enabled = true,
  });

  final bool checked;
  final ValueChanged<bool> onChange;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Clickable(
      cursor: SystemMouseCursors.click,
      enabled: enabled,
      borderRadius: BorderRadius.circular(9),
      onClick: () => onChange(!checked),
      child: Container(
        width: 32,
        height: 18,
        decoration: BoxDecoration(
          color: !enabled
              ? p.muted.withValues(alpha: 0.25)
              : (checked ? p.accent : p.muted.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 120),
              curve: Curves.fastOutSlowIn,
              left: checked ? 16 : 2,
              top: 2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onClick,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: HoverBuilder(
        cursor: SystemMouseCursors.click,
        onTap: onClick,
        indicate: true,
        borderRadius: BorderRadius.circular(6),
        builder: (ctx, hov) => Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: selected
                ? p.accent.withValues(alpha: 0.14)
                : (hov ? p.hover : const Color(0x00000000)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            spacing: 8,
            children: [
              Ico(icon, tint: selected ? p.accent : p.muted, size: 16),
              Expanded(
                child: T(
                  label,
                  color: selected ? p.accent : p.text,
                  size: 13,
                  weight: selected ? FontWeight.w500 : null,
                ),
              ),
              if (selected) Ico(Ic.check, tint: p.accent, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuOpt {
  const MenuOpt(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Clickable(
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(5),
      onClick: onTap,
      child: Container(
        height: CONTROL_H,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: p.field,
          borderRadius: BorderRadius.circular(5),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: p.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 7,
          children: [
            Ico(icon, tint: p.muted, size: 16),
            Flexible(
              child: T(
                label,
                color: p.text,
                weight: FontWeight.w500,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Ico(Ic.dropDown, tint: p.muted, size: 15),
          ],
        ),
      ),
    );
  }
}

class ViewModeMenu extends StatelessWidget {
  const ViewModeMenu({
    super.key,
    required this.current,
    required this.onSelect,
    this.options = const [
      MenuOpt('pretty', 'Pretty', Ic.fmtJson),
      MenuOpt('raw', 'Raw', Ic.fmtRaw),
      MenuOpt('preview', 'Preview', Ic.eye),
    ],
  });

  final String current;
  final ValueChanged<String> onSelect;
  final List<MenuOpt> options;

  @override
  Widget build(BuildContext context) {
    final currentOpt = options.firstWhere(
      (o) => o.id == current,
      orElse: () => options.first,
    );
    return Builder(
      builder: (anchorCtx) {
        return _MenuButton(
          icon: currentOpt.icon,
          label: currentOpt.label,
          onTap: () async {
            final v = await showAnchoredPopup<String>(
              anchorCtx,
              anchor: anchorRectOf(anchorCtx),
              width: 150,
              offset: const Offset(0, 4),
              radius: 10,
              builder: (ctx, close) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final o in options)
                    MenuRow(
                      label: o.label,
                      icon: o.icon,
                      selected: o.id == current,
                      onClick: () => close(o.id),
                    ),
                ],
              ),
            );
            if (v != null) onSelect(v);
          },
        );
      },
    );
  }
}

class FormatMenu extends StatelessWidget {
  const FormatMenu({
    super.key,
    required this.current,
    required this.onFormat,
    this.textFormats = TEXT_FORMATS,
    this.rawFormats = BINARY_FORMATS,
  });

  final String current;
  final ValueChanged<String> onFormat;
  final List<String> textFormats;
  final List<String> rawFormats;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Builder(
      builder: (anchorCtx) {
        return _MenuButton(
          icon: formatIcon(current),
          label: current,
          onTap: () async {
            final v = await showAnchoredPopup<String>(
              anchorCtx,
              anchor: anchorRectOf(anchorCtx),
              width: 176,
              offset: const Offset(0, 4),
              radius: 10,
              builder: (ctx, close) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final f in textFormats)
                    MenuRow(
                      label: f,
                      icon: formatIcon(f),
                      selected: f == current,
                      onClick: () => close(f),
                    ),
                  if (textFormats.isNotEmpty && rawFormats.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      height: 1,
                      color: p.border,
                    ),
                  for (final f in rawFormats)
                    MenuRow(
                      label: f,
                      icon: formatIcon(f),
                      selected: f == current,
                      onClick: () => close(f),
                    ),
                ],
              ),
            );
            if (v != null) onFormat(v);
          },
        );
      },
    );
  }
}

/// Hex dump of the first [max] bytes of [b].
String hexDump(Uint8List b, [int max = 96 * 1024]) {
  final n = math.min(b.length, max);
  final sb = StringBuffer();
  var i = 0;
  while (i < n) {
    sb.write('${i.toRadixString(16).padLeft(8, '0')}  ');
    for (var j = 0; j < 16; j++) {
      if (i + j < n) {
        sb.write('${b[i + j].toRadixString(16).padLeft(2, '0')} ');
      } else {
        sb.write('   ');
      }
      if (j == 7) sb.write(' ');
    }
    sb.write(' |');
    for (var j = 0; j < 16; j++) {
      if (i + j < n) {
        final c = b[i + j] & 0xff;
        sb.write(c >= 32 && c <= 126 ? String.fromCharCode(c) : '.');
      }
    }
    sb.write('|\n');
    i += 16;
  }
  if (b.length > n) sb.write('… ${b.length - n} more bytes not shown');
  return sb.toString();
}

String base64Wrapped(Uint8List b, [int width = 100]) {
  final s = base64Encode(b);
  final out = <String>[];
  for (var i = 0; i < s.length; i += width) {
    out.add(s.substring(i, math.min(s.length, i + width)));
  }
  return out.join('\n');
}
