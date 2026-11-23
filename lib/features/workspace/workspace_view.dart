import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/features/workspace/disconnected_panel.dart';
import 'package:rocket_mcp/features/workspace/prompt_runner_view.dart';
import 'package:rocket_mcp/features/workspace/raw_jsonrpc_view.dart';
import 'package:rocket_mcp/features/workspace/resource_runner_view.dart';
import 'package:rocket_mcp/features/workspace/response_viewer.dart';
import 'package:rocket_mcp/features/workspace/server_header.dart';
import 'package:rocket_mcp/features/workspace/server_logs_view.dart';
import 'package:rocket_mcp/features/workspace/tool_runner_view.dart';
import 'package:rocket_mcp/features/workspace/traffic_inspector_view.dart';
import 'package:rocket_mcp/features/workspace/traffic_packet_view.dart';
import 'package:rocket_mcp/features/workspace/workspace_tabs.dart';
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
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Ico(Ic.server, size: 30, tint: p.accent),
              ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Connection Header Bar
          ServerHeader(state: state, server: activeServer, session: session),

          // Tabs and panes only exist while connected; otherwise the panel explains how to connect.
          Expanded(
            child: ListenableBuilder(
              listenable: session,
              builder: (context, _) =>
                  session.status == McpServerStatus.connected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        WorkspaceTabs(session: session),
                        Expanded(child: _tabBody(session)),
                      ],
                    )
                  : DisconnectedPanel(
                      state: state,
                      server: activeServer,
                      session: session,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// A tab's content. Tools has the tool result beside (or below) its runner; the Traffic Inspector has the selected
  /// packet; every other tab shows its own results and uses the full width.
  Widget _tabBody(McpSession session) {
    final explorer = _buildActiveExplorer(session);
    final detail = switch (session.activeTab) {
      WorkspaceTab.tools => ResponseViewer(
        session: session,
        onToggleLayout: state.toggleLayout,
        isVertical: state.settings.verticalLayout,
      ),
      WorkspaceTab.inspector => TrafficPacketView(
        entry: session.selectedTrafficEntry,
        onToggleLayout: state.toggleLayout,
        isVertical: state.settings.verticalLayout,
      ),
      _ => null,
    };
    if (detail == null) return explorer;
    return SplitPane(
      vertical: state.settings.verticalLayout,
      fraction: state.splitFraction,
      onFraction: (v) => state.splitFraction = v,
      first: explorer,
      second: detail,
    );
  }

  Widget _buildActiveExplorer(McpSession session) =>
      switch (session.activeTab) {
        WorkspaceTab.tools => ToolRunnerView(session: session),
        WorkspaceTab.resources => ResourceRunnerView(session: session),
        WorkspaceTab.prompts => PromptRunnerView(session: session),
        WorkspaceTab.inspector => TrafficInspectorView(session: session),
        WorkspaceTab.logs => ServerLogsView(session: session),
        WorkspaceTab.raw => RawJsonRpcView(session: session),
      };
}
