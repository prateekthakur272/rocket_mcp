import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/transport_icon.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The panel header of the active server: an avatar with its status, the name and version, the transport and address,
/// a status chip, and the actions that apply to the connection.
class ServerHeader extends StatelessWidget {
  const ServerHeader({
    super.key,
    required this.state,
    required this.server,
    required this.session,
  });

  static const double height = 60;
  static const double _avatarSize = 36;

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
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: p.panel,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        spacing: 12,
        children: [
          _Avatar(tone: tone, size: _avatarSize),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Flexible(
                      child: T(
                        server.name,
                        size: 14,
                        lineHeight: 1.3,
                        weight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (version != null)
                      T(
                        'v$version',
                        size: 11,
                        lineHeight: 1.3,
                        mono: true,
                        color: p.muted,
                      ),
                  ],
                ),
                Row(
                  spacing: 6,
                  children: [
                    Ico(
                      transportIcon(server.transport),
                      size: 12,
                      tint: p.muted,
                    ),
                    T(
                      server.transport.shortLabel,
                      size: 10.5,
                      lineHeight: 1.3,
                      mono: true,
                      weight: FontWeight.w600,
                      color: p.muted,
                    ),
                    Flexible(
                      child: T(
                        _address.isEmpty ? 'not configured' : _address,
                        size: 10.5,
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
          _StatusChip(
            label: session.status.label,
            color: tone,
            latency: connected ? session.pingLatency : null,
          ),
          IconBtn(
            icon: Ic.configuration,
            size: 16,
            boxSize: 28,
            tooltip: 'Configurations',
            onClick: () => state.modal = ModalServerConfig(server: server),
          ),
          if (connected)
            Btn(
              label: 'Ping',
              icon: Ic.ping,
              outlined: true,
              onClick: session.ping,
            ),
          if (connected)
            Btn(
              label: 'Disconnect',
              icon: Ic.disconnect,
              danger: true,
              outlined: true,
              onClick: session.disconnect,
            )
          else if (session.status != McpServerStatus.connecting)
            Btn(
              label: 'Connect',
              icon: Ic.connect,
              primary: true,
              onClick: session.connect,
            ),
        ],
      ),
    );
  }
}

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
            borderRadius: BorderRadius.circular(9),
          ),
          child: Ico(Ic.server, size: 19, tint: tone),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: tone,
              shape: BoxShape.circle,
              border: Border.all(color: p.panel, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// A rounded chip with a status dot, the status name and, when known, the last ping latency.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color, this.latency});
  final String label;
  final Color color;
  final Duration? latency;

  @override
  Widget build(BuildContext context) {
    final ping = latency;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          T(
            ping == null ? label : '$label · ${ping.inMilliseconds}ms',
            size: 11,
            lineHeight: 1.2,
            weight: FontWeight.w600,
            color: color,
          ),
        ],
      ),
    );
  }
}
