import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// The workspace tabs of a server (Tools, Resources, Prompts, Traffic Inspector, Server Logs, Raw JSON-RPC), each with
/// its MCP icon and, where there is something to count, a count pill.
class WorkspaceTabs extends StatelessWidget {
  const WorkspaceTabs({super.key, required this.session});
  final McpSession session;

  static const Map<WorkspaceTab, IconData> _icons = {
    WorkspaceTab.tools: Ic.tool,
    WorkspaceTab.resources: Ic.resource,
    WorkspaceTab.prompts: Ic.prompt,
    WorkspaceTab.inspector: Ic.traffic,
    WorkspaceTab.logs: Ic.fmtRaw,
    WorkspaceTab.raw: Ic.fmtJson,
  };

  int? _count(WorkspaceTab tab) => switch (tab) {
    WorkspaceTab.tools => session.tools.length,
    WorkspaceTab.resources =>
      session.resources.length + session.resourceTemplates.length,
    WorkspaceTab.prompts => session.prompts.length,
    WorkspaceTab.inspector => session.client?.trafficHistory.length ?? 0,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      decoration: BoxDecoration(
        color: p.panel,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          spacing: 2,
          children: [
            for (final tab in WorkspaceTab.values)
              _TabButton(
                icon: _icons[tab]!,
                label: tab.label,
                count: _count(tab),
                selected: tab == session.activeTab,
                onTap: () => session.activeTab = tab,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      cursor: SystemMouseCursors.click,
      onTap: onTap,
      builder: (context, hovered) {
        final color = selected ? p.text : (hovered ? p.text : p.muted);
        return Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: hovered && !selected ? p.hover : const Color(0x00000000),
            border: Border(
              bottom: BorderSide(
                color: selected ? p.accent : const Color(0x00000000),
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Ico(icon, size: 15, tint: selected ? p.accent : color),
              T(
                label,
                color: color,
                size: 12.5,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
              if (count != null && count! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? p.accent.withValues(alpha: 0.15)
                        : p.muted.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: T(
                    '$count',
                    size: 10,
                    lineHeight: 1.2,
                    mono: true,
                    weight: FontWeight.w600,
                    color: selected ? p.accent : p.muted,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
