import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show SelectionArea, Tooltip;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/header_bar.dart';
import 'package:rocket_mcp/components/item_tile.dart';
import 'package:rocket_mcp/components/markdown_view.dart';
import 'package:rocket_mcp/components/resizable_pane.dart';
import 'package:rocket_mcp/components/segmented.dart';
import 'package:rocket_mcp/components/state_graphic.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/features/workspace/list_empty_state.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/uri_template.dart';

/// Available content rendering modes for MCP resources.
enum ResourceRenderMode {
  raw('Raw'),
  json('JSON'),
  markdown('.md');

  const ResourceRenderMode(this.label);
  final String label;

  static ResourceRenderMode fromLabel(String val) => switch (val) {
    'JSON' => ResourceRenderMode.json,
    '.md' || 'Markdown' => ResourceRenderMode.markdown,
    _ => ResourceRenderMode.raw,
  };
}

bool isMarkdownResource(String uri, String? mimeType, String? text) {
  final u = uri.toLowerCase();
  final m = (mimeType ?? '').toLowerCase();
  if (u.endsWith('.md') || u.endsWith('.markdown') || m.contains('markdown')) {
    return true;
  }
  if (text != null && text.trim().isNotEmpty) {
    final trimmed = text.trim();
    if (trimmed.startsWith('# ') ||
        trimmed.startsWith('## ') ||
        trimmed.startsWith('### ') ||
        trimmed.startsWith('```') ||
        (trimmed.contains('\n# ') && trimmed.contains('\n')) ||
        (trimmed.contains('\n```') && trimmed.contains('```'))) {
      return true;
    }
  }
  return false;
}

bool isJsonResource(String uri, String? mimeType, String? text) {
  final u = uri.toLowerCase();
  final m = (mimeType ?? '').toLowerCase();
  if (u.endsWith('.json') || m.contains('json')) {
    return true;
  }
  if (text != null && text.trim().isNotEmpty) {
    final trimmed = text.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      try {
        jsonDecode(trimmed);
        return true;
      } catch (_) {}
    }
  }
  return false;
}

ResourceRenderMode detectResourceMode(
  String uri,
  String? mimeType,
  String? text,
) {
  if (isMarkdownResource(uri, mimeType, text)) {
    return ResourceRenderMode.markdown;
  }
  if (isJsonResource(uri, mimeType, text)) return ResourceRenderMode.json;
  return ResourceRenderMode.raw;
}

/// Interactive viewer and runner for MCP resources and resource templates.
class ResourceRunnerView extends StatefulWidget {
  const ResourceRunnerView({super.key, required this.session});
  final McpSession session;

  @override
  State<ResourceRunnerView> createState() => _ResourceRunnerViewState();
}

class _ResourceRunnerViewState extends State<ResourceRunnerView> {
  String _uriInput = '';
  McpResourceTemplate? _selectedTemplate;
  final Map<String, String> _templateValues = {};
  ResourceRenderMode _renderMode = ResourceRenderMode.raw;
  bool _wrapCode = true;
  int _selectedContentIndex = 0;
  List<McpResourceContent>? _lastContents;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _uriInput = widget.session.selectedResource?.uri ?? '';
  }

  @override
  void didUpdateWidget(ResourceRunnerView old) {
    super.didUpdateWidget(old);
    if (widget.session.selectedResource != null &&
        widget.session.selectedResource != old.session.selectedResource) {
      _selectedTemplate = null;
      _templateValues.clear();
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

    final templateVars = extractTemplateVariables(
      _selectedTemplate?.uriTemplate ?? _uriInput,
    );
    final isTemplate = _selectedTemplate != null || templateVars.isNotEmpty;
    final hasUnresolved = hasUnresolvedVariables(_uriInput);

    final contents = session.resourceContents;
    if (contents != null && !identical(contents, _lastContents)) {
      _lastContents = contents;
      _selectedContentIndex = 0;
      if (contents.isNotEmpty) {
        final first = contents.first;
        _renderMode = detectResourceMode(first.uri, first.mimeType, first.text);
      }
    }

    final q = _searchQuery.trim().toLowerCase();
    final filteredResources = q.isEmpty
        ? resources
        : resources
              .where(
                (r) =>
                    r.name.toLowerCase().contains(q) ||
                    r.uri.toLowerCase().contains(q) ||
                    (r.description?.toLowerCase().contains(q) ?? false),
              )
              .toList();

    final filteredTemplates = q.isEmpty
        ? templates
        : templates
              .where(
                (t) =>
                    t.name.toLowerCase().contains(q) ||
                    t.uriTemplate.toLowerCase().contains(q) ||
                    (t.description?.toLowerCase().contains(q) ?? false),
              )
              .toList();

    final titleName = _selectedTemplate?.name ?? selectedRes?.name;
    final titleDesc =
        _selectedTemplate?.description ?? selectedRes?.description;
    final mimeType =
        _selectedTemplate?.mimeType ??
        selectedRes?.mimeType ??
        (contents != null && contents.isNotEmpty
            ? contents.first.mimeType
            : null);

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
                // Search filter input
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  child: Field(
                    value: _searchQuery,
                    onChange: (v) => setState(() => _searchQuery = v),
                    placeholder: 'Filter resources & templates…',
                    prefixIcon: Ic.search,
                    clearable: true,
                    highlightVars: false,
                  ),
                ),
                Container(height: 1, color: p.border),

                Expanded(
                  child:
                      (resources.isEmpty && templates.isEmpty) ||
                          (filteredResources.isEmpty &&
                              filteredTemplates.isEmpty)
                      ? ListEmptyState(
                          noun: 'resources',
                          loading: session.isDiscovering,
                          icon: Ic.resource,
                          filtered: _searchQuery.isNotEmpty,
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          children: [
                            if (filteredResources.isNotEmpty) ...[
                              if (filteredTemplates.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    top: 4,
                                    bottom: 4,
                                  ),
                                  child: T(
                                    'STATIC RESOURCES (${filteredResources.length})',
                                    size: 10,
                                    weight: FontWeight.w600,
                                    color: p.muted,
                                  ),
                                ),
                              for (final res in filteredResources)
                                _item(
                                  p: p,
                                  title: res.name,
                                  subtitle: res.uri,
                                  badge: res.mimeType ?? 'resource',
                                  icon: _resourceIcon(res.mimeType),
                                  isSubscribed: session.isSubscribed(res.uri),
                                  isSelected:
                                      _selectedTemplate == null &&
                                      res.uri == selectedRes?.uri,
                                  onClick: () {
                                    setState(() {
                                      _selectedTemplate = null;
                                      _templateValues.clear();
                                      session.selectedResource = res;
                                      _uriInput = res.uri;
                                    });
                                  },
                                ),
                            ],
                            if (filteredTemplates.isNotEmpty) ...[
                              Padding(
                                padding: EdgeInsets.only(
                                  left: 10,
                                  top: filteredResources.isNotEmpty ? 12 : 4,
                                  bottom: 4,
                                ),
                                child: T(
                                  'DYNAMIC TEMPLATES (${filteredTemplates.length})',
                                  size: 10,
                                  weight: FontWeight.w600,
                                  color: p.muted,
                                ),
                              ),
                              for (final tmpl in filteredTemplates)
                                _item(
                                  p: p,
                                  title: tmpl.name,
                                  subtitle: tmpl.uriTemplate,
                                  badge: tmpl.mimeType,
                                  icon: Ic.resourceTemplate,
                                  isSubscribed: false,
                                  isSelected:
                                      _selectedTemplate == tmpl ||
                                      (_selectedTemplate == null &&
                                          _uriInput == tmpl.uriTemplate),
                                  onClick: () {
                                    setState(() {
                                      _selectedTemplate = tmpl;
                                      _templateValues.clear();
                                      session.selectedResource = null;
                                      _uriInput = tmpl.uriTemplate;
                                    });
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
              // Redesigned Resource View Header with read-only URL
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: p.panel,
                  border: Border(bottom: BorderSide(color: p.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Ico(
                        isTemplate
                            ? Ic.resourceTemplate
                            : _resourceIcon(mimeType),
                        size: 13,
                        tint: p.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (titleName != null &&
                        titleName.isNotEmpty &&
                        titleName != _uriInput) ...[
                      Flexible(
                        flex: 0,
                        child: Tooltip(
                          message: titleDesc ?? titleName,
                          child: T(
                            titleName,
                            size: 13,
                            weight: FontWeight.w600,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Read-only URL box
                    Expanded(
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.only(left: 8, right: 3),
                        decoration: BoxDecoration(
                          color: p.field,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(
                          children: [
                            Ico(Ic.link, size: 12, tint: p.muted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Tooltip(
                                message: _uriInput.isEmpty
                                    ? 'No resource selected'
                                    : _uriInput,
                                child: SelectionArea(
                                  child: T(
                                    _uriInput.isEmpty
                                        ? 'No resource selected'
                                        : _uriInput,
                                    mono: true,
                                    size: 11,
                                    color: _uriInput.isEmpty ? p.muted : p.text,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                            if (_uriInput.isNotEmpty)
                              IconBtn(
                                icon: Ic.copy,
                                size: 12,
                                boxSize: 20,
                                tooltip: 'Copy URI',
                                onClick: () {
                                  Platform.copy(_uriInput);
                                  AppScope.read(context)
                                      .showToast('URI copied');
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (mimeType != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: p.muted.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: T(
                          mimeType,
                          size: 10,
                          mono: true,
                          color: p.accent,
                        ),
                      ),
                    ],

                    const SizedBox(width: 8),
                    if (canSubscribe &&
                        _uriInput.trim().isNotEmpty &&
                        !hasUnresolved) ...[
                      Btn(
                        label: session.isSubscribed(_uriInput.trim())
                            ? 'Subscribed'
                            : 'Subscribe',
                        icon: session.isSubscribed(_uriInput.trim())
                            ? Ic.check
                            : Ic.subscribe,
                        outlined: true,
                        height: 26,
                        fontSize: 11.5,
                        onClick: () => session.toggleResourceSubscription(
                          _uriInput.trim(),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Tooltip(
                      message: hasUnresolved
                          ? 'Fill in all template parameters to read'
                          : (session.isLoadingResource
                                ? 'Fetching resource…'
                                : (_uriInput.isEmpty
                                      ? 'Select a resource or template'
                                      : 'Fetch resource content')),
                      child: Btn(
                        label: session.isLoadingResource
                            ? 'Reading…'
                            : (contents != null ? 'Refresh' : 'Read'),
                        icon: session.isLoadingResource
                            ? null
                            : (contents != null ? Ic.refresh : Ic.readResource),
                        primary: contents == null,
                        outlined: contents != null,
                        height: 26,
                        fontSize: 11.5,
                        enabled:
                            !session.isLoadingResource &&
                            _uriInput.trim().isNotEmpty &&
                            !hasUnresolved &&
                            session.status == McpServerStatus.connected,
                        onClick: () => session.readResource(_uriInput.trim()),
                      ),
                    ),
                  ],
                ),
              ),

              // Template Parameters Input Section (if template variables exist)
              if (templateVars.isNotEmpty)
                _buildTemplateParameters(p, templateVars),

              // Preview of read content
              Expanded(
                child: session.isLoadingResource
                    ? const Center(child: T('Fetching resource content…'))
                    : (contents == null
                          ? (isTemplate
                                ? EmptyState(
                                    graphic: const StateGraphic.resources(),
                                    title: hasUnresolved
                                        ? 'Configure Template Parameters'
                                        : 'Ready to Read Resource',
                                    message: hasUnresolved
                                        ? 'Fill in the parameters above to resolve this dynamic URI template.'
                                        : 'Template resolved to:\n$_uriInput',
                                    actions: [
                                      if (!hasUnresolved &&
                                          _uriInput.trim().isNotEmpty)
                                        Btn(
                                          label: 'Read Resource',
                                          icon: Ic.readResource,
                                          primary: true,
                                          enabled:
                                              session.status ==
                                              McpServerStatus.connected,
                                          onClick: () => session.readResource(
                                            _uriInput.trim(),
                                          ),
                                        ),
                                    ],
                                  )
                                : EmptyState(
                                    graphic: const StateGraphic.resources(),
                                    title: 'Select a Resource',
                                    message: _uriInput.isEmpty
                                        ? 'Choose a resource or template from the sidebar to inspect.'
                                        : 'Click "Read" to fetch content for this URI.',
                                    actions: [
                                      if (_uriInput.trim().isNotEmpty)
                                        Btn(
                                          label: 'Read Resource',
                                          icon: Ic.readResource,
                                          primary: true,
                                          enabled:
                                              session.status ==
                                              McpServerStatus.connected,
                                          onClick: () => session.readResource(
                                            _uriInput.trim(),
                                          ),
                                        ),
                                    ],
                                  ))
                          : (contents.isEmpty
                                ? const EmptyState(
                                    title: 'No content',
                                    message: 'No content returned for this resource.',
                                  )
                                : _buildContentPreview(p, contents))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateParameters(Pal p, List<String> vars) {
    final filledCount = _templateValues.values
        .where((v) => v.isNotEmpty)
        .length;
    final allFilled = filledCount == vars.length;
    final canRead =
        allFilled &&
        _uriInput.trim().isNotEmpty &&
        !hasUnresolvedVariables(_uriInput) &&
        widget.session.status == McpServerStatus.connected &&
        !widget.session.isLoadingResource;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: p.panel,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            children: [
              Ico(Ic.resourceTemplate, size: 14, tint: p.accent),
              const SizedBox(width: 6),
              const T('TEMPLATE PARAMETERS', size: 11, weight: FontWeight.w700),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: allFilled
                      ? p.ok.withValues(alpha: 0.15)
                      : p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 4,
                  children: [
                    if (allFilled) Ico(Ic.check, size: 9, tint: p.ok),
                    T(
                      allFilled
                          ? 'All ${vars.length} filled'
                          : '$filledCount/${vars.length} filled',
                      size: 9,
                      mono: true,
                      lineHeight: 1.1,
                      color: allFilled ? p.ok : p.accent,
                      weight: FontWeight.w600,
                    ),
                  ],
                ),
              ),
              if (_selectedTemplate?.description != null &&
                  _selectedTemplate!.description!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: T(
                    _selectedTemplate!.description!,
                    size: 11,
                    color: p.muted,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (_templateValues.isNotEmpty) ...[
                const SizedBox(width: 6),
                IconBtn(
                  icon: Ic.refresh,
                  size: 12,
                  boxSize: 22,
                  tooltip: 'Reset parameters',
                  onClick: () {
                    setState(() {
                      _templateValues.clear();
                      _uriInput = _selectedTemplate?.uriTemplate ?? '';
                    });
                  },
                ),
              ],
            ],
          ),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              for (final v in vars)
                Builder(
                  builder: (context) {
                    final isQuery = isQueryTemplateVariable(
                      _selectedTemplate?.uriTemplate ?? _uriInput,
                      v,
                    );
                    final isFilled = (_templateValues[v] ?? '').isNotEmpty;
                    return SizedBox(
                      width: vars.length == 1 ? double.infinity : 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Row(
                            children: [
                              T(
                                '{$v}',
                                mono: true,
                                size: 11,
                                weight: FontWeight.w600,
                                color: isFilled ? p.accent : p.text,
                              ),
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: p.muted.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: T(
                                  isQuery ? 'QUERY' : 'PATH',
                                  size: 8.5,
                                  mono: true,
                                  lineHeight: 1.1,
                                  color: p.muted,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (isFilled)
                                Ico(Ic.check, size: 11, tint: p.ok)
                              else
                                T('required', size: 9, color: p.muted),
                            ],
                          ),
                          Field(
                            key: ValueKey(
                              'template_${_selectedTemplate?.uriTemplate}_$v',
                            ),
                            prefixIcon: Ic.variables,
                            placeholder: 'Value for $v…',
                            clearable: true,
                            value: _templateValues[v] ?? '',
                            onChange: (val) {
                              setState(() {
                                if (val.trim().isEmpty) {
                                  _templateValues.remove(v);
                                } else {
                                  _templateValues[v] = val.trim();
                                }
                                final base =
                                    _selectedTemplate?.uriTemplate ?? _uriInput;
                                _uriInput = resolveUriTemplate(
                                  base,
                                  _templateValues,
                                );
                              });
                            },
                            onEnter: canRead
                                ? () => widget.session.readResource(
                                    _uriInput.trim(),
                                  )
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentPreview(Pal p, List<McpResourceContent> contents) {
    final selectedRes = widget.session.selectedResource;
    final safeIndex = _selectedContentIndex.clamp(0, contents.length - 1);
    final current = contents[safeIndex];
    final rawText =
        current.text ??
        (current.blob != null
            ? '[Binary Blob: ${current.blob!.length} chars]'
            : '<empty>');

    final hasJson = isJsonResource(current.uri, current.mimeType, current.text);
    final hasMd = isMarkdownResource(
      current.uri,
      current.mimeType,
      current.text,
    );

    // Raw is always available; only include applicable format options (.md / JSON)
    final availableOptions = <String>['Raw'];
    if (hasJson) availableOptions.add('JSON');
    if (hasMd) availableOptions.add('.md');

    if (!availableOptions.contains(_renderMode.label)) {
      _renderMode = availableOptions.length > 1
          ? ResourceRenderMode.fromLabel(availableOptions.last)
          : ResourceRenderMode.raw;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Content Preview Header Toolbar
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: HeaderBar(
            spacing: 8,
            leading: [
              if (contents.length > 1)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    T(
                      'Item ${safeIndex + 1}/${contents.length}',
                      size: 11,
                      mono: true,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(width: 4),
                    IconBtn(
                      icon: Ic.chevronLeft,
                      size: 13,
                      boxSize: 22,
                      onClick: safeIndex > 0
                          ? () => setState(
                              () => _selectedContentIndex = safeIndex - 1,
                            )
                          : () {},
                    ),
                    IconBtn(
                      icon: Ic.chevronRight,
                      size: 13,
                      boxSize: 22,
                      onClick: safeIndex < contents.length - 1
                          ? () => setState(
                              () => _selectedContentIndex = safeIndex + 1,
                            )
                          : () {},
                    ),
                  ],
                ),
              if (selectedRes?.description != null &&
                  selectedRes!.description!.isNotEmpty)
                T(
                  selectedRes.description!,
                  size: 11,
                  color: p.muted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
            trailing: [
              if (_renderMode != ResourceRenderMode.markdown)
                IconBtn(
                  icon: Ic.wrap,
                  tooltip: 'Wrap lines',
                  color: _wrapCode ? p.accent : null,
                  boxSize: 26,
                  size: 14,
                  onClick: () => setState(() => _wrapCode = !_wrapCode),
                ),
              IconBtn(
                icon: Ic.copy,
                tooltip: 'Copy content',
                boxSize: 26,
                size: 14,
                onClick: () {
                  Platform.copy(rawText);
                  AppScope.read(context).showToast('Copied to clipboard');
                },
              ),
              // Show Raw and applicable format option (.md / JSON) if available
              Segmented(
                options: availableOptions,
                selected: _renderMode.label,
                onSelect: (v) => setState(
                  () => _renderMode = ResourceRenderMode.fromLabel(v),
                ),
              ),
            ],
          ),
        ),

        // Main preview body
        Expanded(
          child: switch (_renderMode) {
            ResourceRenderMode.markdown =>
              current.text != null && current.text!.isNotEmpty
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: SelectionArea(child: MarkdownView(current.text!)),
                    )
                  : Center(
                      child: T(
                        current.blob != null
                            ? '[Binary Blob: ${current.blob!.length} chars]'
                            : '<empty>',
                        color: p.muted,
                        mono: true,
                      ),
                    ),
            ResourceRenderMode.json => _buildJsonView(current, p),
            ResourceRenderMode.raw => CodeView(
              text: rawText,
              lang: 'text',
              wrap: _wrapCode,
              borderRadius: BorderRadius.zero,
              bordered: false,
            ),
          },
        ),
      ],
    );
  }

  Widget _buildJsonView(McpResourceContent current, Pal p) {
    if (current.text == null || current.text!.trim().isEmpty) {
      return Center(
        child: T(
          current.blob != null
              ? '[Binary Blob: ${current.blob!.length} chars]'
              : '<empty>',
          color: p.muted,
          mono: true,
        ),
      );
    }

    String textToDisplay;
    bool isValidJson = false;
    String? jsonError;

    try {
      final decoded = jsonDecode(current.text!);
      textToDisplay = const JsonEncoder.withIndent('  ').convert(decoded);
      isValidJson = true;
    } catch (e) {
      textToDisplay = current.text!;
      jsonError = '$e';
    }

    if (!isValidJson) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: p.err.withValues(alpha: 0.1),
            child: Row(
              children: [
                Ico(Ic.error, tint: p.err, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: T(
                    'Invalid JSON ($jsonError) — showing raw text',
                    size: 11,
                    color: p.err,
                    mono: true,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CodeView(
              text: textToDisplay,
              lang: 'text',
              wrap: _wrapCode,
              borderRadius: BorderRadius.zero,
              bordered: false,
            ),
          ),
        ],
      );
    }

    return CodeView(
      text: textToDisplay,
      lang: 'json',
      wrap: _wrapCode,
      borderRadius: BorderRadius.zero,
      bordered: false,
    );
  }

  Widget _item({
    required Pal p,
    required String title,
    required String subtitle,
    required String? badge,
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
          if (badge != null && badge.isNotEmpty) TileBadge(badge),
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
