import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show
        Scrollbar,
        ScrollbarTheme,
        ScrollbarThemeData,
        WidgetState,
        WidgetStateProperty,
        WidgetStatePropertyAll;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/features/sidebar/server_row.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

class _FooterBtn extends StatelessWidget {
  const _FooterBtn({
    required this.label,
    required this.icon,
    required this.onClick,
  });

  final String label;
  final IconData icon;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      indicate: true,
      borderRadius: BorderRadius.circular(6),
      cursor: SystemMouseCursors.click,
      onTap: onClick,
      builder: (ctx, hov) => Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
        decoration: BoxDecoration(
          color: hov ? p.hover : const Color(0x00000000),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Ico(icon, tint: hov ? p.accent : p.muted, size: 13),
            const SizedBox(width: 3),
            Flexible(
              child: T(
                label,
                color: hov ? p.text : p.muted,
                size: 11.5,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sidebar listing configured MCP servers with status, filtering, stats badges, and refined controls.
class SidebarView extends StatefulWidget {
  const SidebarView({super.key, required this.state});
  final AppState state;

  @override
  State<SidebarView> createState() => _SidebarViewState();
}

class _SidebarViewState extends State<SidebarView> {
  String _filter = '';

  AppState get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final allServers = state.servers;

    // Filter servers
    final filtered = _filter.isEmpty
        ? allServers
        : allServers.where((s) {
            final q = _filter.toLowerCase();
            return s.name.toLowerCase().contains(q) ||
                s.command.toLowerCase().contains(q) ||
                s.url.toLowerCase().contains(q);
          }).toList();

    return Container(
      color: p.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search / Filter Row
          Padding(
            padding: const EdgeInsets.only(
              left: 10,
              right: 6,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              spacing: 2,
              children: [
                Expanded(
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: p.field,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Ico(Ic.search, tint: p.muted, size: 15),
                        Expanded(
                          child: Field(
                            value: _filter,
                            onChange: (v) => setState(() => _filter = v),
                            placeholder: 'Filter servers…',
                            bordered: false,
                            highlightVars: false,
                          ),
                        ),
                        if (_filter.isNotEmpty)
                          IconBtn(
                            icon: Ic.close,
                            onClick: () => setState(() => _filter = ''),
                            size: 12,
                            boxSize: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(height: 1, color: p.border),

          // Body (Empty state or List)
          if (allServers.isEmpty)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Ico(Ic.server, tint: p.accent, size: 24),
                    ),
                    const SizedBox(height: 10),
                    const T('No MCP servers yet', weight: FontWeight.w600),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: DefaultTextStyle.merge(
                        textWidthBasis: TextWidthBasis.longestLine,
                        child: T(
                          'Configure a stdio or SSE server, explore presets, or import from Claude Desktop config.',
                          color: p.muted,
                          size: 12,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: Btn(
                        label: 'New Server',
                        onClick: () => state.modal = const ModalServerConfig(),
                        primary: true,
                        icon: Ic.add,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: Btn(
                        label: 'Explore Presets',
                        onClick: () => state.modal = const ModalImportExport(),
                        icon: Ic.presets,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: Btn(
                        label: 'Import Config',
                        onClick: () => state.modal = const ModalImportExport(),
                        icon: Ic.import,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Stack(
                children: [
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: T(
                        'No servers match “$_filter”',
                        color: p.muted,
                        size: 12,
                      ),
                    ),
                  ScrollbarTheme(
                    data: ScrollbarThemeData(
                      thumbVisibility: const WidgetStatePropertyAll(true),
                      thickness: const WidgetStatePropertyAll(8),
                      radius: const Radius.circular(4),
                      minThumbLength: 16,
                      thumbColor: WidgetStateProperty.resolveWith(
                        (s) => const Color(0xFF000000).withValues(
                          alpha: s.contains(WidgetState.hovered) ? 0.5 : 0.12,
                        ),
                      ),
                    ),
                    child: Scrollbar(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final server = filtered[i];
                          final session = state.getSession(server.id);
                          return ServerRow(
                            server: server,
                            session: session,
                            selected: server.id == state.activeServerId,
                            onSelect: () => state.selectServer(server.id),
                            onConnect: () => session?.connect(),
                            onDisconnect: () => session?.disconnect(),
                            onEdit: () =>
                                state.modal = ModalServerConfig(server: server),
                            onDuplicate: () => state.duplicateServer(server.id),
                            onDelete: () => state.deleteServer(server.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Bottom Footer Action Bar
          Container(
            foregroundDecoration: BoxDecoration(
              border: Border(top: BorderSide(color: p.border, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(
              spacing: 2,
              children: [
                Expanded(
                  child: _FooterBtn(
                    label: 'New',
                    icon: Ic.add,
                    onClick: () => state.modal = const ModalServerConfig(),
                  ),
                ),
                Expanded(
                  child: _FooterBtn(
                    label: 'Presets',
                    icon: Ic.presets,
                    onClick: () => state.modal = const ModalImportExport(),
                  ),
                ),
                Expanded(
                  child: _FooterBtn(
                    label: 'Import',
                    icon: Ic.import,
                    onClick: () => state.modal = const ModalImportExport(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
