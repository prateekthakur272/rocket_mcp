import 'dart:math' as math;

import 'package:material_ui/material_ui.dart' hide Chip;
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/drag_devices.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Key-Value pair model for tables.
class TableKV {
  final String name;
  final String value;
  final bool enabled;

  const TableKV({this.name = '', this.value = '', this.enabled = true});

  TableKV copyWith({String? name, String? value, bool? enabled}) => TableKV(
    name: name ?? this.name,
    value: value ?? this.value,
    enabled: enabled ?? this.enabled,
  );
}

const double _rowH = 34;
const double _checkW = 26;

int _flex(double f) => math.max(1, (f * 100000).round());

/// A cell with a focus underline; content is a borderless Field.
class _TableCell extends StatefulWidget {
  const _TableCell({required this.child});
  final Widget child;

  @override
  State<_TableCell> createState() => _TableCellState();
}

class _TableCellState extends State<_TableCell> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => setState(() => focused = f),
      child: CustomPaint(
        painter: _CellPainter(p, focused),
        child: Align(alignment: Alignment.centerLeft, child: widget.child),
      ),
    );
  }
}

class _CellPainter extends CustomPainter {
  _CellPainter(this.p, this.focused);
  final Pal p;
  final bool focused;

  @override
  void paint(Canvas c, Size s) {
    if (focused) {
      final paint = Paint()
        ..color = p.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      c.drawLine(Offset(0, s.height - 1), Offset(s.width, s.height - 1), paint);
    }
  }

  @override
  bool shouldRepaint(_CellPainter old) => old.focused != focused || old.p != p;
}

/// An editable key-value table matching open_rest UI guidelines.
/// Shows an automatic blank row at the end so typing immediately creates a new entry.
class EditableKVTable extends StatefulWidget {
  const EditableKVTable({
    super.key,
    required this.items,
    required this.onChange,
    this.keyHint = 'Key',
    this.valHint = 'Value',
    this.keyTitle = 'KEY',
    this.valTitle = 'VALUE',
    this.showEnabled = true,
  });

  final List<TableKV> items;
  final ValueChanged<List<TableKV>> onChange;
  final String keyHint;
  final String valHint;
  final String keyTitle;
  final String valTitle;
  final bool showEnabled;

  @override
  State<EditableKVTable> createState() => _EditableKVTableState();
}

class _EditableKVTableState extends State<EditableKVTable> {
  double _splitFrac = 0.4;

  void _update(int index, TableKV item) {
    final next = List<TableKV>.from(widget.items);
    if (index < next.length) {
      if (item.name.isEmpty && item.value.isEmpty) {
        next.removeAt(index);
      } else {
        next[index] = item;
      }
    } else {
      if (item.name.isNotEmpty || item.value.isNotEmpty) {
        next.add(item);
      }
    }
    widget.onChange(next);
  }

  void _remove(int index) {
    if (index >= widget.items.length) return;
    final next = List<TableKV>.from(widget.items)..removeAt(index);
    widget.onChange(next);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final rows = [...widget.items, const TableKV()];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(5),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Header
          Container(
            height: 30,
            decoration: BoxDecoration(
              color: p.panel,
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: Row(
              children: [
                if (widget.showEnabled) const SizedBox(width: _checkW),
                Expanded(
                  flex: _flex(_splitFrac),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: T(
                      widget.keyTitle,
                      color: p.muted,
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                _ColumnResizer(
                  onDelta: (dx, totalW) {
                    setState(() {
                      _splitFrac = (_splitFrac + dx / totalW).clamp(0.15, 0.85);
                    });
                  },
                ),
                Expanded(
                  flex: _flex(1.0 - _splitFrac),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: T(
                      widget.valTitle,
                      color: p.muted,
                      size: 11,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 34), // Delete action column
              ],
            ),
          ),
          // Table Rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final item = rows[i];
              final isBlank = i == rows.length - 1;

              return HoverBuilder(
                builder: (ctx, hov) => Container(
                  height: _rowH,
                  decoration: BoxDecoration(
                    color: hov
                        ? p.hover.withValues(alpha: 0.35)
                        : const Color(0x00000000),
                    border: Border(
                      bottom: BorderSide(
                        color: p.border.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.showEnabled)
                        SizedBox(
                          width: _checkW,
                          child: isBlank
                              ? null
                              : Center(
                                  child: Clickable(
                                    cursor: SystemMouseCursors.click,
                                    onClick: () => _update(
                                      i,
                                      item.copyWith(enabled: !item.enabled),
                                    ),
                                    child: Ico(
                                      item.enabled ? Ic.checkCircle : Ic.cancel,
                                      tint: item.enabled ? p.accent : p.muted,
                                      size: 15,
                                    ),
                                  ),
                                ),
                        ),
                      Expanded(
                        flex: _flex(_splitFrac),
                        child: _TableCell(
                          child: Field(
                            key: ValueKey('k_${i}_${item.name}'),
                            value: item.name,
                            onChange: (v) => _update(i, item.copyWith(name: v)),
                            placeholder: widget.keyHint,
                            bordered: false,
                            mono: true,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        color: p.border.withValues(alpha: 0.4),
                      ),
                      Expanded(
                        flex: _flex(1.0 - _splitFrac),
                        child: _TableCell(
                          child: Field(
                            key: ValueKey('v_${i}_${item.value}'),
                            value: item.value,
                            onChange: (v) =>
                                _update(i, item.copyWith(value: v)),
                            placeholder: widget.valHint,
                            bordered: false,
                            mono: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 34,
                        child: Center(
                          child: !isBlank && hov
                              ? IconBtn(
                                  icon: Ic.delete,
                                  onClick: () => _remove(i),
                                  size: 15,
                                  color: p.err,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColumnResizer extends StatelessWidget {
  const _ColumnResizer({required this.onDelta});
  final void Function(double dx, double totalW) onDelta;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          supportedDevices: kDragDevices,
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            final box = context.findAncestorRenderObjectOfType<RenderBox>();
            final w = box?.size.width ?? 500;
            onDelta(details.delta.dx, w);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Container(
              width: 9,
              height: double.infinity,
              alignment: Alignment.center,
              child: Container(width: 1, color: p.border),
            ),
          ),
        );
      },
    );
  }
}
