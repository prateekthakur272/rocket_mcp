import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/context_menu.dart';
import 'package:rocket_mcp/components/mini_spinner.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/transport_icon.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Layout constants of a server row.
const double serverRowHeight = 48;
const double _avatarSize = 28;
const double _actionIconSize = 15;

/// One server in the sidebar: styled as a modern floating capsule card with
/// status indicators, capability counts, transport badge, and interactive hover controls.
class ServerRow extends StatefulWidget {
  const ServerRow({
    super.key,
    required this.server,
    required this.session,
    required this.selected,
    required this.onSelect,
    required this.onConnect,
    required this.onDisconnect,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final McpServerConfig server;
  final McpSession? session;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  State<ServerRow> createState() => _ServerRowState();
}

class _ServerRowState extends State<ServerRow> {
  bool _hovered = false;
  bool _menuOpen = false;

  McpServerStatus get _status =>
      widget.session?.status ?? McpServerStatus.disconnected;

  Color _statusColor(Pal p) => switch (_status) {
    McpServerStatus.connected => p.ok,
    McpServerStatus.connecting => p.accent,
    McpServerStatus.error => p.err,
    McpServerStatus.disconnected => p.muted.withValues(alpha: 0.45),
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final showActions =
        _hovered || _menuOpen || _status == McpServerStatus.connecting;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onSelect,
              onSecondaryTap: () => setState(() => _menuOpen = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                constraints: const BoxConstraints(minHeight: serverRowHeight),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? p.accent.withValues(alpha: p.dark ? 0.16 : 0.08)
                      : (_hovered ? p.hover : const Color(0x00000000)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.selected
                        ? p.accent.withValues(alpha: p.dark ? 0.38 : 0.25)
                        : (_hovered
                              ? p.border.withValues(alpha: 0.5)
                              : const Color(0x00000000)),
                    width: 1,
                  ),
                  boxShadow: widget.selected && p.dark
                      ? [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.06),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 8,
                  children: [
                    _Avatar(status: _status, statusColor: _statusColor(p)),
                    Expanded(
                      child: _Details(
                        row: widget,
                        isStdio: _isStdio,
                        status: _status,
                        session: widget.session,
                      ),
                    ),
                    if (showActions)
                      ..._actions(p)
                    else if (widget.selected)
                      Ico(Ic.chevronRight, size: 12, tint: p.accent),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: SizedBox(
            width: 0,
            height: 0,
            child: ContextMenu(
              open: _menuOpen,
              onDismiss: () => setState(() => _menuOpen = false),
              items: [
                if (_status == McpServerStatus.connected) ...[
                  MenuItem(
                    'Ping',
                    action: () => widget.session?.ping(feedback: true),
                  ),
                  MenuItem('Disconnect', action: widget.onDisconnect),
                ] else
                  MenuItem('Connect', action: widget.onConnect),
                MenuItem('Configurations', action: widget.onEdit),
                MenuItem('Duplicate', action: widget.onDuplicate),
                const MenuItem(null),
                MenuItem('Delete', danger: true, action: widget.onDelete),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool get _isStdio => widget.server.transport == McpTransportType.stdio;

  List<Widget> _actions(Pal p) => [
    if (_status == McpServerStatus.connecting)
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6),
        child: MiniSpinner(size: 13),
      )
    else if (_status == McpServerStatus.connected)
      IconBtn(
        icon: Ic.disconnect,
        size: _actionIconSize,
        tooltip: 'Disconnect',
        color: p.err,
        onClick: widget.onDisconnect,
      )
    else
      IconBtn(
        icon: Ic.connect,
        size: _actionIconSize,
        tooltip: 'Connect',
        color: p.ok,
        onClick: widget.onConnect,
      ),
    IconBtn(
      icon: Ic.moreVert,
      size: _actionIconSize,
      tooltip: 'More actions',
      onClick: () => setState(() => _menuOpen = true),
    ),
  ];
}

/// The MCP server icon in a rounded square, with the connection status as a pip on its corner.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.status, required this.statusColor});

  final McpServerStatus status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final live = status == McpServerStatus.connected;
    final tone = live
        ? p.ok
        : (status == McpServerStatus.connecting ? p.accent : p.muted);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _avatarSize,
          height: _avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tone.withValues(alpha: live ? 0.14 : 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Ico(Ic.server, size: 15, tint: tone),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 8.5,
            height: 8.5,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: p.panel, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// The two text lines of a row.
class _Details extends StatelessWidget {
  const _Details({
    required this.row,
    required this.isStdio,
    required this.status,
    required this.session,
  });

  final ServerRow row;
  final bool isStdio;
  final McpServerStatus status;
  final McpSession? session;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isConnected = status == McpServerStatus.connected;
    final s = session;

    final String subtitleText;
    if (isConnected && s != null) {
      final toolsCount = s.tools.length;
      final resCount = s.resources.length + s.resourceTemplates.length;
      final parts = <String>[];
      if (toolsCount > 0) parts.add('$toolsCount tools');
      if (resCount > 0) parts.add('$resCount res');
      if (s.pingLatency != null) {
        parts.add('${s.pingLatency!.inMilliseconds}ms');
      }
      if (parts.isNotEmpty) {
        subtitleText = parts.join(' · ');
      } else {
        subtitleText = 'connected';
      }
    } else {
      subtitleText = isStdio
          ? (row.server.command.isNotEmpty
                ? row.server.command
                : 'local process')
          : row.server.url;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        T(
          row.server.name,
          size: 12,
          weight: row.selected ? FontWeight.w600 : FontWeight.w500,
          color: row.selected
              ? (p.dark ? const Color(0xFFFFFFFF) : p.text)
              : p.text,
          lineHeight: 1.25,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 5,
          children: [
            _TransportPill(transport: row.server.transport),
            Expanded(
              child: T(
                subtitleText,
                color: isConnected ? p.ok.withValues(alpha: 0.85) : p.muted,
                size: 9.5,
                lineHeight: 1.25,
                mono: !isConnected,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The transport as a small pill: its icon and short name (`stdio`, `sse`, `http`).
class _TransportPill extends StatelessWidget {
  const _TransportPill({required this.transport});
  final McpTransportType transport;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: p.muted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 3,
        children: [
          Ico(transportIcon(transport), size: 10, tint: p.muted),
          T(
            transport.shortLabel,
            size: 9,
            lineHeight: 1.1,
            mono: true,
            weight: FontWeight.w600,
            color: p.muted,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
