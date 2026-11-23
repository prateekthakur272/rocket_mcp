import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:material_ui/material_ui.dart' show SelectableText;
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Live viewer for server stderr logs and MCP notifications/message logs.
class ServerLogsView extends StatefulWidget {
  const ServerLogsView({super.key, required this.session});
  final McpSession session;

  @override
  State<ServerLogsView> createState() => _ServerLogsViewState();
}

class _ServerLogsViewState extends State<ServerLogsView> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final client = widget.session.client;
    final stderrLogs = client?.stderrLogLines ?? const [];
    final serverLogs = client?.serverLogs ?? const [];

    final combined = <_LogEntry>[
      for (final line in stderrLogs)
        _LogEntry(type: 'stderr', text: line, timestamp: DateTime.now()),
      for (final msg in serverLogs)
        _LogEntry(
          type: msg.level.name.toUpperCase(),
          text: '[${msg.logger ?? "server"}] ${msg.dataString}',
          timestamp: msg.timestamp,
          level: msg.level,
        ),
    ];

    final filtered = _filter.isEmpty
        ? combined
        : combined
              .where(
                (l) => l.text.toLowerCase().contains(_filter.toLowerCase()),
              )
              .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  placeholder: 'Filter logs…',
                ),
              ),
              Btn(
                label: 'Clear Logs',
                icon: Ic.delete,
                onClick: () {
                  client?.clearLogs();
                  setState(() {});
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Ic.fmtRaw,
                  title: 'No server logs yet',
                  message: 'Messages the server writes to stderr appear here while it runs.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: item.level == McpLogLevel.error
                                  ? p.err.withValues(alpha: 0.15)
                                  : p.muted.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: T(
                              item.type,
                              size: 9,
                              mono: true,
                              color: item.level == McpLogLevel.error
                                  ? p.err
                                  : p.muted,
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              item.text,
                              style: TextStyle(
                                fontFamily: monoFamily,
                                fontSize: 11,
                                color: item.level == McpLogLevel.error
                                    ? p.err
                                    : p.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _LogEntry {
  const _LogEntry({
    required this.type,
    required this.text,
    required this.timestamp,
    this.level,
  });

  final String type;
  final String text;
  final DateTime timestamp;
  final McpLogLevel? level;
}
