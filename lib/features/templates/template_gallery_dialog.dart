import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/features/templates/server_template_model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Interactive Server Template Gallery dialog modeled after DevSpace's catalog.
/// Allows browsing, filtering, and one-click instantiating curated MCP server configurations.
class TemplateGalleryDialog extends StatefulWidget {
  const TemplateGalleryDialog({super.key, required this.state});
  final AppState state;

  @override
  State<TemplateGalleryDialog> createState() => _TemplateGalleryDialogState();
}

class _TemplateGalleryDialogState extends State<TemplateGalleryDialog> {
  ServerTemplateCategory _category = ServerTemplateCategory.all;
  String _query = '';

  List<ServerTemplate> get _filteredTemplates {
    final list = ServerTemplates.all.where((t) {
      if (_category != ServerTemplateCategory.all && t.category != _category) {
        return false;
      }
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return t.name.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q) ||
          t.commandPreview.toLowerCase().contains(q) ||
          (t.package?.toLowerCase().contains(q) ?? false) ||
          t.tags.any((tag) => tag.toLowerCase().contains(q));
    }).toList();

    return list;
  }

  int _countFor(ServerTemplateCategory cat) {
    if (cat == ServerTemplateCategory.all) return ServerTemplates.all.length;
    return ServerTemplates.all.where((t) => t.category == cat).length;
  }

  void _addServer(ServerTemplate template) {
    final config = template.config;
    // Generate a unique id if a server with this id already exists
    var id = config.id;
    var counter = 1;
    while (widget.state.servers.any((s) => s.id == id)) {
      counter++;
      id = '${config.id}_$counter';
    }

    final newServer = McpServerConfig(
      id: id,
      name: counter > 1 ? '${config.name} ($counter)' : config.name,
      transport: config.transport,
      command: config.command,
      args: config.args,
      env: config.env,
      workingDirectory: config.workingDirectory,
      url: config.url,
      headers: config.headers,
    );

    widget.state.addServer(newServer);
    widget.state.showToast('Added "${newServer.name}" to workspace');
    widget.state.modal = null;
  }

  void _customizeServer(ServerTemplate template) {
    widget.state.modal = ModalServerConfig(server: template.config);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final templates = _filteredTemplates;

    return ModalScaffold(
      title: 'Server Template Gallery',
      width: 900,
      maxHeight: 640,
      onClose: () => widget.state.modal = null,
      actions: [
        Btn(
          label: 'Custom Server…',
          icon: Ic.add,
          onClick: () => widget.state.modal = const ModalServerConfig(),
        ),
        Btn(
          label: 'Import Config…',
          icon: Ic.import,
          onClick: () => widget.state.modal = const ModalImportExport(),
        ),
        const Spacer(),
        Btn(
          label: 'Close',
          primary: true,
          onClick: () => widget.state.modal = null,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtitle / Intro
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: T(
              'Browse pre-configured official and community MCP servers. Add one directly or customize parameters for instant testing.',
              color: p.muted,
              size: 12,
            ),
          ),

          // Search & Filter Bar
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Field(
                  value: _query,
                  onChange: (v) => setState(() => _query = v),
                  placeholder:
                      'Search templates by name, command, tag, or description…',
                  prefixIcon: Ic.search,
                  clearable: true,
                  highlightVars: false,
                ),
              ),
              if (_query.isNotEmpty)
                Btn(label: 'Clear', onClick: () => setState(() => _query = '')),
            ],
          ),
          const SizedBox(height: 12),

          // Category Segmented Bar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: p.field,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: p.border, width: 1),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cat in ServerTemplateCategory.values)
                    _buildCategorySegment(p, cat),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Gallery Grid View or Empty State
          Expanded(
            child: templates.isEmpty
                ? _buildEmptyState(p)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 740 ? 2 : 1;

                      return GridView.builder(
                        itemCount: templates.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 172,
                        ),
                        itemBuilder: (context, i) {
                          return _buildTemplateCard(p, templates[i]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySegment(Pal p, ServerTemplateCategory cat) {
    final selected = _category == cat;
    final count = _countFor(cat);

    return ClickableNoRipple(
      onClick: () => setState(() => _category = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? p.panel : const Color(0x00000000),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? p.border : const Color(0x00000000),
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF000000)
                        .withValues(alpha: p.dark ? 0.35 : 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, size: 13, color: selected ? p.accent : p.muted),
            const SizedBox(width: 6),
            Text(
              cat.label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? p.text : p.muted,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? p.accent.withValues(alpha: 0.14)
                    : p.border.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontFamily: monoFamily,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: selected ? p.accent : p.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Pal p, ServerTemplate template) {
    final alreadyAdded = widget.state.servers.any(
      (s) => s.id == template.config.id,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Icon, Name, Transport badge
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  template.icon ?? Icons.extension_rounded,
                  size: 16,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (template.featured) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: p.ok.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'FEATURED',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: p.ok,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      template.author,
                      style: TextStyle(fontSize: 10, color: p.muted),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Transport Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: p.panel,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: p.border, width: 1),
                ),
                child: Text(
                  template.config.transport.shortLabel.toUpperCase(),
                  style: TextStyle(
                    fontFamily: monoFamily,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: template.config.transport == McpTransportType.stdio
                        ? p.accent
                        : p.ok,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Expanded(
            child: Text(
              template.description,
              style: TextStyle(fontSize: 11, color: p.muted, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),

          // Command Snippet row
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: p.panel,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: p.border.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    template.commandPreview,
                    style: TextStyle(
                      fontFamily: monoFamily,
                      fontSize: 10,
                      color: p.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                ClickableNoRipple(
                  onClick: () {
                    Clipboard.setData(
                      ClipboardData(text: template.commandPreview),
                    );
                    widget.state.showToast('Copied command to clipboard');
                  },
                  child: Icon(Ic.copy, size: 11, color: p.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Actions Row
          Row(
            children: [
              // Tags
              Expanded(
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final tag in template.tags.take(2))
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: p.panel,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(fontSize: 9, color: p.muted),
                        ),
                      ),
                  ],
                ),
              ),
              Btn(
                label: 'Customize…',
                onClick: () => _customizeServer(template),
              ),
              const SizedBox(width: 6),
              Btn(
                label: alreadyAdded ? 'Add Again' : 'Add Server',
                icon: Ic.add,
                primary: true,
                onClick: () => _addServer(template),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Pal p) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: p.muted),
          Text(
            'No templates match “$_query”',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Text(
            'Try adjusting your search terms or switch categories above.',
            style: TextStyle(color: p.muted, fontSize: 11.5),
          ),
          const SizedBox(height: 6),
          Btn(
            label: 'Clear Search',
            onClick: () => setState(() {
              _query = '';
              _category = ServerTemplateCategory.all;
            }),
          ),
        ],
      ),
    );
  }
}
