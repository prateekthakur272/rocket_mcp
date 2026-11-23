import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/state_graphic.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/features/workspace/disconnected_panel.dart';
import 'package:rocket_mcp/features/workspace/prompt_runner_view.dart';
import 'package:rocket_mcp/features/workspace/raw_jsonrpc_view.dart';
import 'package:rocket_mcp/features/workspace/resource_runner_view.dart';
import 'package:rocket_mcp/features/workspace/server_header.dart';
import 'package:rocket_mcp/features/workspace/server_logs_view.dart';
import 'package:rocket_mcp/features/workspace/tool_runner_view.dart';
import 'package:rocket_mcp/features/workspace/traffic_inspector_view.dart';
import 'package:rocket_mcp/features/workspace/traffic_packet_view.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

export 'package:rocket_mcp/features/sidebar/sidebar_view.dart' show SidebarView;

/// The main workspace view for testing and managing MCP servers, featuring
/// an interactive inspector and runner for tools, resources, prompts, traffic, and logs.
class WorkspaceView extends StatelessWidget {
  const WorkspaceView({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final activeServer = state.activeServer;
    final session = state.activeSession;

    if (activeServer == null || session == null) {
      return ColoredBox(
        color: p.bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              const StateGraphic.server(),
              const SizedBox(height: 2),
              const T('No server selected', size: 16, weight: FontWeight.w600),
              T(
                'Select an MCP server in the sidebar, or add one to begin testing.',
                color: p.muted,
                size: 12,
              ),
              const SizedBox(height: 4),
              Btn(
                label: 'Add Server',
                icon: Ic.add,
                primary: true,
                onClick: () => state.modal = const ModalServerConfig(),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: p.bg,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Unified Server Connection Header & Tab Bar
            ServerHeader(state: state, server: activeServer, session: session),

            // Content body: active tab when connected, or DisconnectedPanel when disconnected
            Expanded(
              child: session.status == McpServerStatus.connected
                  ? _tabBody(session)
                  : DisconnectedPanel(
                      state: state,
                      server: activeServer,
                      session: session,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// A tab's content. Traffic Inspector splits packets and detail; Tools internally splits request
  /// builder and response viewer; other tabs use the full workspace.
  Widget _tabBody(McpSession session) {
    if (session.activeTab == WorkspaceTab.inspector) {
      return SplitPane(
        vertical: state.settings.verticalLayout,
        fraction: state.splitFraction,
        onFraction: (v) => state.splitFraction = v,
        first: TrafficInspectorView(session: session),
        second: TrafficPacketView(
          entry: session.selectedTrafficEntry,
          onToggleLayout: state.toggleLayout,
          isVertical: state.settings.verticalLayout,
        ),
      );
    }
    return _buildActiveExplorer(session);
  }

  Widget _buildActiveExplorer(McpSession session) =>
      switch (session.activeTab) {
        WorkspaceTab.tools => ToolRunnerView(session: session, state: state),
        WorkspaceTab.resources => ResourceRunnerView(session: session),
        WorkspaceTab.prompts => PromptRunnerView(session: session),
        WorkspaceTab.inspector => TrafficInspectorView(session: session),
        WorkspaceTab.logs => ServerLogsView(session: session),
        WorkspaceTab.raw => RawJsonRpcView(session: session),
      };
}
