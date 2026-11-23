import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/state_graphic.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// What the workspace shows instead of its tabs and panes while the server is not connected: the explorer and response
/// panes have nothing to show without a connection, so they stay hidden and this offers the way forward.
class DisconnectedPanel extends StatelessWidget {
  const DisconnectedPanel({
    super.key,
    required this.state,
    required this.server,
    required this.session,
  });

  final AppState state;
  final McpServerConfig server;
  final McpSession session;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return switch (session.status) {
      McpServerStatus.connecting => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            const StateGraphic(type: StateGraphicType.connecting),
            const T('Connecting…', size: 15, weight: FontWeight.w600),
            T(
              'Starting ${server.name} and loading its tools, resources and prompts.',
              size: 12,
              color: p.muted,
            ),
          ],
        ),
      ),
      McpServerStatus.error => EmptyState(
        graphic: const StateGraphic.error(),
        title: 'Could not connect',
        message: session.statusError ?? 'The connection failed.',
        actions: [
          Btn(
            label: 'Try again',
            icon: Ic.refresh,
            primary: true,
            onClick: session.connect,
          ),
          Btn(
            label: 'Configurations',
            icon: Ic.configuration,
            outlined: true,
            onClick: () => state.modal = ModalServerConfig(server: server),
          ),
        ],
      ),
      _ => EmptyState(
        graphic: const StateGraphic.disconnected(),
        title: 'Not connected',
        message:
            'Connect to ${server.name} to browse its tools, resources and prompts.',
        actions: [
          Btn(
            label: 'Connect',
            icon: Ic.connect,
            primary: true,
            onClick: session.connect,
          ),
          Btn(
            label: 'Configurations',
            icon: Ic.configuration,
            outlined: true,
            onClick: () => state.modal = ModalServerConfig(server: server),
          ),
        ],
      ),
    };
  }
}
