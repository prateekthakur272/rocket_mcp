import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

IconData _menuIcon(String l) {
  if (l.startsWith('New Request') || l.startsWith('New Collection')) {
    return Ic.newFile;
  }
  if (l.startsWith('New Folder')) return Ic.newFolder;
  if (l.startsWith('Open')) return Ic.open;
  if (l.startsWith('Import')) return Ic.import;
  if (l.startsWith('Export')) return Ic.export;
  if (l.startsWith('New Workflow')) return Ic.workflow;
  if (l.startsWith('Run')) return Ic.play;
  if (l.startsWith('Environments')) return Ic.environments;
  if (l.startsWith('Settings')) return Ic.settings;
  if (l.startsWith('Variables')) return Ic.variables;
  if (l.startsWith('Rename')) return Ic.rename;
  if (l.startsWith('Clone')) return Ic.clone;
  if (l.startsWith('Show in ')) return Ic.reveal;
  if (l.startsWith('Reload')) return Ic.refresh;
  if (l.startsWith('Close Collection') || l.startsWith('Close')) {
    return Ic.close;
  }
  if (l.startsWith('Delete')) return Ic.delete;
  if (l.startsWith('Move Up')) return Ic.moveUp;
  if (l.startsWith('Move Down')) return Ic.moveDown;
  if (l.startsWith('Send')) return Ic.send;
  if (l.startsWith('Save')) return Ic.save;
  if (l.startsWith('Copy')) return Ic.copy;
  if (l.startsWith('Generate')) return Ic.code;
  if (l.startsWith('Decode') || l.startsWith('Encode')) return Ic.codec;
  return Ic.command;
}

/// A menu entry; a null [label] is a divider.
class MenuItem {
  const MenuItem(this.label, {this.danger = false, this.action = _noop});

  final String? label;
  final bool danger;
  final VoidCallback action;
}

void _noop() {}

/// Declarative popup menu: place it as a (non-positioned) child of the `Stack` that wraps the anchoring widget;
/// it opens below that parent whenever [open] is true.
class ContextMenu extends StatefulWidget {
  const ContextMenu({
    super.key,
    required this.open,
    required this.onDismiss,
    required this.items,
  });

  final bool open;
  final VoidCallback onDismiss;
  final List<MenuItem> items;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ContextMenu old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.open && !_showing) {
      _showing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _show());
    }
  }

  Future<void> _show() async {
    if (!mounted) return;
    final ro = context.findRenderObject() as RenderBox?;
    final parent = ro?.parent;
    final box = (parent is RenderBox && parent.hasSize) ? parent : ro;
    if (box == null || !box.hasSize) {
      _showing = false;
      widget.onDismiss();
      return;
    }
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    final items = widget.items;
    final p = context.pal;
    final picked = await showAnchoredPopup<int>(
      context,
      anchor: anchor,
      builder: (ctx, close) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            if (items[i].label == null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 3),
                height: 1,
                color: p.border,
              )
            else
              PopupRow(
                onClick: () => close(i),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    Ico(
                      _menuIcon(items[i].label!),
                      tint: items[i].danger ? p.err : p.muted,
                      size: 16,
                    ),
                    Flexible(
                      child: T(
                        items[i].label!,
                        color: items[i].danger ? p.err : p.text,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
    _showing = false;
    widget.onDismiss();
    if (picked != null) items[picked].action();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
