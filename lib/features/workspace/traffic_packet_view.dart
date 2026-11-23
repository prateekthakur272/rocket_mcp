import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/header_bar.dart';
import 'package:rocket_mcp/components/icon_btn_group.dart';
import 'package:rocket_mcp/components/json_tree.dart';
import 'package:rocket_mcp/components/response_controls.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The detail pane of the Traffic Inspector: the JSON-RPC packet of the selected message, as raw JSON or a tree, or a
/// prompt to select one when [entry] is null.
class TrafficPacketView extends StatefulWidget {
  const TrafficPacketView({
    super.key,
    required this.entry,
    required this.onToggleLayout,
    required this.isVertical,
  });

  final McpMessageLogEntry? entry;
  final VoidCallback onToggleLayout;
  final bool isVertical;

  @override
  State<TrafficPacketView> createState() => _TrafficPacketViewState();
}

class _TrafficPacketViewState extends State<TrafficPacketView> {
  String _viewMode = 'Raw JSON';
  int _treeExpandSignal = 0;
  final bool _wrapCode = true;

  /// An icon button sized for an [IconBtnGroup].
  Widget _groupBtn(IconData icon, String tooltip, VoidCallback onClick) =>
      IconBtn(
        icon: icon,
        tooltip: tooltip,
        boxSize: IconBtnGroup.boxSize,
        size: IconBtnGroup.iconSize,
        onClick: onClick,
      );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final entry = widget.entry;
    if (entry == null) {
      return const EmptyState(
        icon: Ic.traffic,
        title: 'Select a message',
        message: 'Pick a message in the list to inspect its JSON-RPC packet.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Traffic inspect header
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: HeaderBar(
            leading: [
              Ico(Ic.timer, tint: p.muted, size: 14),
              const T(
                'JSON-RPC Packet',
                weight: FontWeight.w600,
                size: 12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: p.muted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: T(
                  entry.direction == McpMessageDirection.outgoing
                      ? 'OUTGOING'
                      : 'INCOMING',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  size: 9,
                  mono: true,
                  color: entry.direction == McpMessageDirection.outgoing
                      ? p.accent
                      : p.ok,
                ),
              ),
            ],
            trailing: [
              ViewModeMenu(
                current: _viewMode == 'Tree' ? 'Tree' : 'Raw JSON',
                options: const [
                  MenuOpt('Raw JSON', 'Raw JSON', Ic.fmtJson),
                  MenuOpt('Tree', 'Tree', Ic.workflow),
                ],
                onSelect: (m) => setState(() => _viewMode = m),
              ),
              IconBtnGroup(
                children: [
                  if (_viewMode == 'Tree') ...[
                    _groupBtn(
                      Ic.expandAll,
                      'Expand all',
                      () => setState(() => _treeExpandSignal++),
                    ),
                    _groupBtn(
                      Ic.collapseAll,
                      'Collapse all',
                      () => setState(() => _treeExpandSignal--),
                    ),
                  ],
                  _groupBtn(Ic.copy, 'Copy', () {
                    Clipboard.setData(
                      ClipboardData(text: entry.formattedPayload),
                    );
                  }),
                  _groupBtn(
                    widget.isVertical ? Ic.splitH : Ic.splitV,
                    'Switch layout',
                    widget.onToggleLayout,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Payload inspection
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _viewMode == 'Tree'
                ? JsonTree(
                    root: entry.payload,
                    expandSignal: _treeExpandSignal,
                    onCopy: (val, msg) {
                      Clipboard.setData(ClipboardData(text: val));
                    },
                  )
                : CodeView(
                    text: entry.formattedPayload,
                    lang: 'json',
                    wrap: _wrapCode,
                  ),
          ),
        ),
      ],
    );
  }
}
