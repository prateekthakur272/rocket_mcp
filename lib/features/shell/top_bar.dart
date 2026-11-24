import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/breadcrumb.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';

class _TopBtn extends StatelessWidget {
  const _TopBtn({
    required this.label,
    required this.icon,
    this.color,
    required this.onClick,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final isDanger = color == p.err;
    return Btn(
      label: label,
      icon: icon,
      outlined: true,
      height: 26,
      fontSize: 11.5,
      danger: isDanger,
      onClick: onClick,
    );
  }
}

/// Where the user is: the active server, the workspace tab, and the selected tool, resource or prompt.
class _ServerBreadcrumb extends StatelessWidget {
  const _ServerBreadcrumb({required this.state, required this.session});
  final AppState state;
  final McpSession session;

  static const Map<WorkspaceTab, IconData> _tabIcons = {
    WorkspaceTab.tools: Ic.tool,
    WorkspaceTab.resources: Ic.resource,
    WorkspaceTab.prompts: Ic.prompt,
    WorkspaceTab.inspector: Ic.traffic,
    WorkspaceTab.logs: Ic.fmtRaw,
    WorkspaceTab.raw: Ic.fmtJson,
  };

  String? get _selectedName => switch (session.activeTab) {
    WorkspaceTab.tools => session.selectedTool?.name,
    WorkspaceTab.resources => session.selectedResource?.name,
    WorkspaceTab.prompts => session.selectedPrompt?.name,
    _ => null,
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) {
      final selected = _selectedName;
      return Breadcrumb(
        crumbs: [
          Crumb(
            session.config.name,
            icon: Ic.server,
            onTap: () => state.selectServer(session.config.id),
          ),
          Crumb(session.activeTab.label, icon: _tabIcons[session.activeTab]),
          if (selected != null) Crumb(selected),
        ],
      );
    },
  );
}

/// The header bar matching open_rest: logo, name, active server chip, and the main actions.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final server = state.activeServer;
    final session = state.activeSession;
    final status = session?.status ?? McpServerStatus.disconnected;
    final isConnected = status == McpServerStatus.connected;
    final isConnecting = status == McpServerStatus.connecting;

    return Container(
      height: 44,
      color: p.panel,
      child: DrawBottomBorder(
        color: p.border,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 4,
            children: [
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: T(AppConfig.NAME, weight: FontWeight.w700, size: 15),
              ),
              if (server != null && session != null) ...[
                Container(width: 1, height: 18, color: p.border),
                const SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Flexible(
                          child: _ServerBreadcrumb(
                            state: state,
                            session: session,
                          ),
                        ),
                        // The connection button sits right after the path it acts on.
                        if (isConnecting)
                          _TopBtn(
                            label: 'Connecting…',
                            icon: Ic.connecting,
                            color: p.accent,
                            onClick: () {},
                          )
                        else if (isConnected)
                          _TopBtn(
                            label: 'Disconnect',
                            icon: Ic.disconnect,
                            color: p.err,
                            onClick: () => session.disconnect(),
                          )
                        else
                          _TopBtn(
                            label: 'Connect',
                            icon: Ic.connect,
                            color: p.ok,
                            onClick: () => session.connect(),
                          ),
                      ],
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              _TopBtn(
                label: 'Templates',
                icon: Ic.presets,
                onClick: () => state.modal = const ModalTemplateGallery(),
              ),
              _TopBtn(
                label: 'Import',
                icon: Ic.import,
                onClick: () => state.modal = const ModalImportExport(),
              ),
              _TopBtn(
                label: 'New Server',
                icon: Ic.add,
                onClick: () => state.modal = const ModalServerConfig(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
