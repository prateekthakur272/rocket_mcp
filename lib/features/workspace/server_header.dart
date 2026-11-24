import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/mini_spinner.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/transport_icon.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/features/workspace/workspace_tabs.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The server header bar: displays server title, command, connection status and controls,
/// with the workspace tab bar placed below the title in a column.
class ServerHeader extends StatelessWidget {
  const ServerHeader({
    super.key,
    required this.state,
    required this.server,
    required this.session,
  });

  static const double _avatarSize = 30;

  final AppState state;
  final McpServerConfig server;
  final McpSession session;

  bool get _isStdio => server.transport == McpTransportType.stdio;

  String get _address => _isStdio
      ? [server.command, ...server.args].where((s) => s.isNotEmpty).join(' ')
      : server.url;

  Color _statusColor(Pal p) => switch (session.status) {
    McpServerStatus.connected => p.ok,
    McpServerStatus.connecting => p.accent,
    McpServerStatus.error => p.err,
    McpServerStatus.disconnected => p.muted,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final tone = _statusColor(p);
    final version = session.client?.serverInfo?.version;
    final connected = session.status == McpServerStatus.connected;
    return Container(
      decoration: BoxDecoration(
        color: p.panel,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Server avatar, Title & Command, Status Chip, and Connection Controls
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _Avatar(tone: tone, size: _avatarSize),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Flexible(
                            child: T(
                              server.name,
                              size: 13.5,
                              lineHeight: 1.3,
                              weight: FontWeight.w600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (version != null)
                            T(
                              'v$version',
                              size: 10.5,
                              lineHeight: 1.3,
                              mono: true,
                              color: p.muted,
                            ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Ico(
                            transportIcon(server.transport),
                            size: 11,
                            tint: p.muted,
                          ),
                          T(
                            server.transport.shortLabel,
                            size: 10,
                            lineHeight: 1.3,
                            mono: true,
                            weight: FontWeight.w600,
                            color: p.muted,
                          ),
                          Flexible(
                            child: T(
                              _address.isEmpty ? 'not configured' : _address,
                              size: 10,
                              lineHeight: 1.3,
                              mono: true,
                              color: p.muted.withValues(alpha: 0.8),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StatusChip(
                  label: session.status.label,
                  color: tone,
                  latency: connected ? session.pingLatency : null,
                  isPinging: session.isPinging,
                ),
                const SizedBox(width: 6),
                IconBtn(
                  icon: Ic.configuration,
                  size: 15,
                  boxSize: 26,
                  tooltip: 'Configurations',
                  onClick: () =>
                      state.modal = ModalServerConfig(server: server),
                ),
                const SizedBox(width: 4),
                if (connected) ...[
                  Btn(
                    label: session.isPinging ? 'Pinging…' : 'Ping',
                    icon: session.isPinging ? Ic.connecting : Ic.ping,
                    outlined: true,
                    height: 26,
                    fontSize: 11.5,
                    enabled: !session.isPinging,
                    onClick: () => session.ping(feedback: true),
                  ),
                  const SizedBox(width: 6),
                  Btn(
                    label: 'Disconnect',
                    icon: Ic.disconnect,
                    danger: true,
                    outlined: true,
                    height: 26,
                    fontSize: 11.5,
                    onClick: session.disconnect,
                  ),
                ] else if (session.status != McpServerStatus.connecting) ...[
                  Btn(
                    label: 'Connect',
                    icon: Ic.connect,
                    primary: true,
                    height: 26,
                    fontSize: 11.5,
                    onClick: session.connect,
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: MiniSpinner(size: 14),
                  ),
                ],
              ],
            ),
          ),

          // Tab bar below title in a column (when connected)
          if (connected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: WorkspaceTabs(session: session),
            ),
        ],
      ),
    );
  }
}

/// The MCP server icon in a rounded square, with the connection status as a pip on its corner.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.tone, required this.size});

  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Ico(Ic.server, size: 15, tint: tone),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: tone,
              shape: BoxShape.circle,
              border: Border.all(color: p.panel, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// A rounded chip with a status dot, the status name and, when known, the last ping latency.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.latency,
    this.isPinging = false,
  });
  final String label;
  final Color color;
  final Duration? latency;
  final bool isPinging;

  @override
  Widget build(BuildContext context) {
    final ping = latency;
    final text = isPinging
        ? '$label · pinging…'
        : (ping == null ? label : '$label · ${ping.inMilliseconds}ms');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 5,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          T(
            text,
            size: 10.5,
            lineHeight: 1.2,
            weight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}
