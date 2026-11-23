import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';

/// The main area: a request pane and a response pane, stacked or side by side according to the layout setting.
/// This is the layout the MCP features (tools, resources, prompts and the message log) are built into.
class WorkspaceView extends StatefulWidget {
  const WorkspaceView({super.key, required this.state});
  final AppState state;

  @override
  State<WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends State<WorkspaceView> {
  double _split = 0.5;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = widget.state;
    return Container(
      color: p.bg,
      child: SplitPane(
        vertical: state.settings.verticalLayout,
        fraction: _split,
        onFraction: (v) => setState(() => _split = v),
        first: _Pane(
          title: 'Request',
          icon: Ic.send,
          message:
              'Choose a server tool, resource or prompt to build a request.',
        ),
        second: _Pane(
          title: 'Response',
          icon: Ic.history,
          message: 'Responses and protocol messages appear here.',
          trailing: IconBtn(
            icon: state.settings.verticalLayout ? Ic.splitH : Ic.splitV,
            onClick: state.toggleLayout,
            color: p.muted,
          ),
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.icon,
    required this.message,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 34,
          padding: const EdgeInsets.only(left: 12, right: 6),
          color: p.panel,
          child: Row(
            spacing: 8,
            children: [
              Ico(icon, tint: p.muted, size: 14),
              Expanded(child: T(title, weight: FontWeight.w600, size: 12)),
              ?trailing,
            ],
          ),
        ),
        Container(height: 1, color: p.border),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: T(message, color: p.muted, size: 12),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shown in the sidebar until servers can be added.
class SidebarView extends StatelessWidget {
  const SidebarView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      color: p.panel,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          const SectionLabel('SERVERS'),
          T('No servers yet', color: p.muted, size: 12),
          T(
            '${AppConfig.NAME} will list your MCP connections here.',
            color: p.muted,
            size: 11,
          ),
        ],
      ),
    );
  }
}
