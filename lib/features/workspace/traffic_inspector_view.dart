import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Full-featured real-time JSON-RPC 2.0 traffic inspector like Postman & MCP Inspector.
class TrafficInspectorView extends StatefulWidget {
  const TrafficInspectorView({super.key, required this.session});
  final McpSession session;

  @override
  State<TrafficInspectorView> createState() => _TrafficInspectorViewState();
}

class _TrafficInspectorViewState extends State<TrafficInspectorView> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final session = widget.session;
    final client = session.client;
    final history = client?.trafficHistory ?? const [];

    final filtered = _filter.isEmpty
        ? history
        : history.where((e) {
            final q = _filter.toLowerCase();
            return (e.method?.toLowerCase().contains(q) ?? false) ||
                e.type.name.toLowerCase().contains(q) ||
                e.formattedPayload.toLowerCase().contains(q);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filter and actions bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Field(
                  value: _filter,
                  onChange: (v) => setState(() => _filter = v),
                  placeholder:
                      'Filter JSON-RPC traffic (method, type, payload)…',
                ),
              ),
              Btn(
                label: 'Clear',
                icon: Ic.delete,
                onClick: () {
                  client?.clearTraffic();
                  session.selectedTrafficEntry = null;
                  setState(() {});
                },
              ),
            ],
          ),
        ),

        // Traffic Table
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: history.isEmpty ? Ic.traffic : Ic.search,
                  title: history.isEmpty
                      ? 'No traffic yet'
                      : 'No matching messages',
                  message: history.isEmpty
                      ? 'Every JSON-RPC request, response and notification is recorded here.'
                      : 'Try a different filter.',
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item =
                        filtered[filtered.length -
                            1 -
                            i]; // Reverse chronological
                    final isSel = item.id == session.selectedTrafficEntry?.id;
                    return Clickable(
                      onClick: () => session.selectedTrafficEntry = item,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSel
                              ? p.selected
                              : (i.isEven
                                    ? p.hover.withValues(alpha: 0.3)
                                    : const Color(0x00000000)),
                          border: Border(
                            left: BorderSide(
                              color: isSel ? p.accent : const Color(0x00000000),
                              width: 3,
                            ),
                            bottom: BorderSide(
                              color: p.border.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                        child: Row(
                          spacing: 10,
                          children: [
                            // Direction Indicator
                            Ico(
                              item.direction == McpMessageDirection.outgoing
                                  ? Ic.outgoing
                                  : Ic.incoming,
                              tint:
                                  item.direction == McpMessageDirection.outgoing
                                  ? p.accent
                                  : p.ok,
                              size: 14,
                            ),

                            // Type badge
                            Container(
                              width: 76,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _typeBg(p, item.type),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: T(
                                  item.type.name.toUpperCase(),
                                  size: 9,
                                  mono: true,
                                  weight: FontWeight.w700,
                                  color: _typeFg(p, item.type),
                                ),
                              ),
                            ),

                            // Method or JSON-RPC ID
                            Expanded(
                              child: Row(
                                spacing: 8,
                                children: [
                                  T(
                                    item.method ??
                                        (item.jsonRpcId != null
                                            ? 'id: ${item.jsonRpcId}'
                                            : 'response'),
                                    size: 12,
                                    mono: true,
                                    weight: FontWeight.w600,
                                  ),
                                  if (item.durationMs != null)
                                    T(
                                      '${item.durationMs}ms',
                                      size: 10,
                                      mono: true,
                                      color: p.muted,
                                    ),
                                ],
                              ),
                            ),

                            // Timestamp
                            T(
                              '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}.${item.timestamp.millisecond.toString().padLeft(3, '0')}',
                              size: 11,
                              mono: true,
                              color: p.muted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _typeBg(Pal p, McpMessageType type) => switch (type) {
    McpMessageType.request => p.accent.withValues(alpha: 0.15),
    McpMessageType.response => p.ok.withValues(alpha: 0.15),
    McpMessageType.notification => p.muted.withValues(alpha: 0.15),
    McpMessageType.error => p.err.withValues(alpha: 0.15),
  };

  Color _typeFg(Pal p, McpMessageType type) => switch (type) {
    McpMessageType.request => p.accent,
    McpMessageType.response => p.ok,
    McpMessageType.notification => p.muted,
    McpMessageType.error => p.err,
  };
}
