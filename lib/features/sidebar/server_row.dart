import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/context_menu.dart';
import 'package:rocket_mcp/components/mini_spinner.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/transport_icon.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Layout constants of a server row.
const double serverRowHeight = 46;
const double _selectionBarWidth = 2.5;
const double _avatarSize = 28;
const double _actionIconSize = 15;

/// One server in the sidebar: a flat, full-width, two-line row like the rows of the OpenRest tree.
///
/// Line one is the name; line two is the transport and either the address (disconnected) or what the server offers
/// (connected: tool, resource and prompt counts and the ping latency). Hovering swaps the right edge for the
/// connect / disconnect and more buttons; right-click opens the same menu. The selected row has a tinted background
/// and an accent bar on its left edge.
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
    final background = widget.selected
        ? p.selected
        : (_hovered ? p.hover : const Color(0x00000000));
    return Stack(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTap: () => setState(() => _menuOpen = true),
            child: Clickable(
              onClick: widget.onSelect,
              cursor: SystemMouseCursors.click,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 110),
                height: serverRowHeight,
                color: background,
                child: Stack(
                  children: [
                    if (widget.selected)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: _selectionBarWidth,
                        child: ColoredBox(color: p.accent),
                      ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10, right: 4),
                        child: Row(
                          spacing: 8,
                          children: [
                            _Avatar(
                              status: _status,
                              statusColor: _statusColor(p),
                            ),
                            Expanded(
                              child: _Details(row: widget, isStdio: _isStdio),
                            ),
                            if (showActions) ..._actions(p),
                          ],
                        ),
                      ),
                    ),
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
                if (_status == McpServerStatus.connected)
                  MenuItem('Disconnect', action: widget.onDisconnect)
                else
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
            width: 9,
            height: 9,
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
  const _Details({required this.row, required this.isStdio});
  final ServerRow row;
  final bool isStdio;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final address = isStdio
        ? (row.server.command.isNotEmpty ? row.server.command : 'local process')
        : row.server.url;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 1,
      children: [
        T(
          row.server.name,
          size: 12.5,
          weight: row.selected ? FontWeight.w600 : FontWeight.w500,
          lineHeight: 1.3,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          spacing: 5,
          children: [
            _TransportPill(transport: row.server.transport),
            Expanded(
              child: T(
                address,
                color: p.muted,
                size: 10,
                lineHeight: 1.3,
                mono: true,
                maxLines: 1,
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
          ),
        ],
      ),
    );
  }
}
