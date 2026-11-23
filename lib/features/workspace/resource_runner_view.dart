import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show SelectableText;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/resizable_pane.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/features/workspace/list_empty_state.dart';
import 'package:rocket_mcp/components/item_tile.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Interactive viewer and runner for MCP resources and resource templates.
class ResourceRunnerView extends StatefulWidget {
  const ResourceRunnerView({super.key, required this.session});
  final McpSession session;

  @override
  State<ResourceRunnerView> createState() => _ResourceRunnerViewState();
}

class _ResourceRunnerViewState extends State<ResourceRunnerView> {
  String _uriInput = '';

  @override
  void initState() {
    super.initState();
    _uriInput = widget.session.selectedResource?.uri ?? '';
  }

  @override
  void didUpdateWidget(ResourceRunnerView old) {
    super.didUpdateWidget(old);
    if (widget.session.selectedResource != null &&
        _uriInput != widget.session.selectedResource!.uri) {
      _uriInput = widget.session.selectedResource!.uri;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final session = widget.session;
    final resources = session.resources;
    final templates = session.resourceTemplates;
    final selectedRes = session.selectedResource;
    final canSubscribe =
        session.client?.serverCapabilities?.resourcesSubscribe ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Resources & templates list
        ResizablePane(
          width: AppScope.of(context).listPaneWidth,
          onWidth: (w) => AppScope.read(context).listPaneWidth = w,
          child: Container(
            decoration: BoxDecoration(
              color: p.panel,
              border: Border(right: BorderSide(color: p.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: T(
                          'RESOURCES (${resources.length})',
                          size: 10,
                          weight: FontWeight.w600,
                          color: p.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: resources.isEmpty && templates.isEmpty
                      ? ListEmptyState(
                          noun: 'resources',
                          loading: session.isDiscovering,
                          icon: Ic.resource,
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            if (resources.isNotEmpty) ...[
                              for (final res in resources)
                                _item(
                                  p: p,
                                  title: res.name,
                                  subtitle: res.uri,
                                  badge: res.mimeType ?? 'resource',
                                  icon: _resourceIcon(res.mimeType),
                                  isSubscribed: session.isSubscribed(res.uri),
                                  isSelected: res.uri == selectedRes?.uri,
                                  onClick: () {
                                    session.selectedResource = res;
                                    setState(() => _uriInput = res.uri);
                                  },
                                ),
                            ],
                            if (templates.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 10,
                                  top: 12,
                                  bottom: 4,
                                ),
                                child: T(
                                  'TEMPLATES (${templates.length})',
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: p.muted,
                                ),
                              ),
                              for (final tmpl in templates)
                                _item(
                                  p: p,
                                  title: tmpl.name,
                                  subtitle: tmpl.uriTemplate,
                                  badge: 'template',
                                  icon: Ic.resourceTemplate,
                                  isSubscribed: false,
                                  isSelected: _uriInput == tmpl.uriTemplate,
                                  onClick: () {
                                    setState(
                                      () => _uriInput = tmpl.uriTemplate,
                                    );
                                  },
                                ),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),

        // Resource runner controls
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: p.panel,
                  border: Border(bottom: BorderSide(color: p.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Field(
                            value: _uriInput,
                            onChange: (v) => setState(() => _uriInput = v),
                            placeholder: 'Resource URI (e.g. file:///path or custom://uri)',
                            mono: true,
                          ),
                        ),
                        Btn(
                          label: session.isLoadingResource
                              ? 'Reading…'
                              : 'Read Resource',
                          icon: Ic.readResource,
                          primary: true,
                          enabled:
                              !session.isLoadingResource &&
                              _uriInput.trim().isNotEmpty &&
                              session.status == McpServerStatus.connected,
                          onClick: () => session.readResource(_uriInput.trim()),
                        ),
                        if (canSubscribe && _uriInput.trim().isNotEmpty) ...[
                          Btn(
                            label: session.isSubscribed(_uriInput.trim())
                                ? 'Subscribed'
                                : 'Subscribe',
                            icon: session.isSubscribed(_uriInput.trim())
                                ? Ic.check
                                : Ic.subscribe,
                            onClick: () => session.toggleResourceSubscription(
                              _uriInput.trim(),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (selectedRes != null && selectedRes.description != null)
                      T(selectedRes.description!, size: 11, color: p.muted),
                  ],
                ),
              ),

              // Preview of read content
              Expanded(
                child: session.isLoadingResource
                    ? const Center(child: T('Fetching resource content…'))
                    : (session.resourceContents == null
                          ? Center(
                              child: T(
                                'Enter or select a URI and click "Read Resource"',
                                color: p.muted,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(14),
                              itemCount: session.resourceContents!.length,
                              itemBuilder: (context, i) {
                                final item = session.resourceContents![i];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: p.field,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: p.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 6,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: T(
                                              item.uri,
                                              size: 11,
                                              mono: true,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                          if (item.mimeType != null)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: p.muted.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: T(
                                                item.mimeType!,
                                                size: 10,
                                                mono: true,
                                                color: p.accent,
                                              ),
                                            ),
                                        ],
                                      ),
                                      Container(height: 1, color: p.border),
                                      SelectableText(
                                        item.text ??
                                            (item.blob != null
                                                ? '[Binary Blob: ${item.blob!.length} chars]'
                                                : '<empty>'),
                                        style: TextStyle(
                                          fontFamily: monoFamily,
                                          fontSize: 12,
                                          color: p.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _item({
    required Pal p,
    required String title,
    required String subtitle,
    required String badge,
    required IconData icon,
    required bool isSubscribed,
    required bool isSelected,
    required VoidCallback onClick,
  }) {
    return ItemTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      monoSubtitle: true,
      selected: isSelected,
      onClick: onClick,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          if (isSubscribed) Ico(Ic.subscribe, size: 12, tint: p.ok),
          TileBadge(badge),
        ],
      ),
    );
  }
}

/// The icon for a resource, chosen by its MIME type.
IconData _resourceIcon(String? mimeType) {
  final mime = (mimeType ?? '').toLowerCase();
  if (mime.startsWith('image/')) return Ic.image;
  if (mime.startsWith('audio/')) return Ic.audio;
  if (mime.startsWith('video/')) return Ic.video;
  if (mime.contains('json')) return Ic.fmtJson;
  if (mime.contains('html')) return Ic.fmtHtml;
  if (mime.contains('xml')) return Ic.fmtXml;
  if (mime.contains('pdf')) return Ic.pdf;
  if (mime.startsWith('text/')) return Ic.fmtRaw;
  return Ic.resource;
}
