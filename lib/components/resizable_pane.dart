import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/drag_devices.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A pane of [width] dp whose right edge can be dragged to resize it (the caller keeps the width and clamps it).
/// Place it in a `Row`. The drag handle sits over the pane's inner right edge, so it takes no layout space, and shows the accent
/// colour while hovered or dragged, drawn over the pane's own border.
class ResizablePane extends StatefulWidget {
  const ResizablePane({
    super.key,
    required this.width,
    required this.onWidth,
    required this.child,
  });

  static const double _handleWidth = 8;

  final double width;
  final ValueChanged<double> onWidth;
  final Widget child;

  @override
  State<ResizablePane> createState() => _ResizablePaneState();
}

class _ResizablePaneState extends State<ResizablePane> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return SizedBox(
      width: widget.width,
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: ResizablePane._handleWidth,
            child: HoverBuilder(
              cursor: SystemMouseCursors.resizeLeftRight,
              builder: (context, hovered) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                supportedDevices: kDragDevices,
                onHorizontalDragStart: (_) => setState(() => _active = true),
                onHorizontalDragUpdate: (d) =>
                    widget.onWidth(widget.width + d.delta.dx),
                onHorizontalDragEnd: (_) => setState(() => _active = false),
                onHorizontalDragCancel: () => setState(() => _active = false),
                // The highlight sits on the pane's own right border (the far edge of the handle), so there is one
                // line, not two.
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: hovered || _active ? 2 : 0,
                    color: p.accent.withValues(alpha: _active ? 0.9 : 0.6),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
