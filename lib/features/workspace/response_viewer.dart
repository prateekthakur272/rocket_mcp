import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/icon_btn_group.dart';
import 'package:rocket_mcp/components/header_bar.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/json_tree.dart';
import 'package:rocket_mcp/components/response_controls.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/json.dart';

/// Right or bottom pane: displays execution responses, image previews, and traffic inspection details.
class ResponseViewer extends StatefulWidget {
  const ResponseViewer({
    super.key,
    required this.session,
    required this.onToggleLayout,
    required this.isVertical,
  });

  final McpSession session;
  final VoidCallback onToggleLayout;
  final bool isVertical;

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer> {
  /// An icon button sized for an [IconBtnGroup].
  Widget _groupBtn(
    IconData icon,
    String tooltip,
    VoidCallback onClick, {
    Color? color,
  }) => IconBtn(
    icon: icon,
    tooltip: tooltip,
    color: color,
    boxSize: IconBtnGroup.boxSize,
    size: IconBtnGroup.iconSize,
    onClick: onClick,
  );

  String _viewMode = 'Tree';
  int _treeExpandSignal = 0;
  bool _wrapCode = true;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final session = widget.session;

    // Check if we are inspecting a traffic entry
    if (session.activeTab == WorkspaceTab.inspector &&
        session.selectedTrafficEntry != null) {
      return _buildTrafficDetails(p, session.selectedTrafficEntry!);
    }

    final toolResult = session.lastToolResult;
    final isRunning = session.isRunningTool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Response Header Bar
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: HeaderBar(
            leading: [
              Ico(Ic.history, tint: p.muted, size: 14),
              const T(
                'Response',
                weight: FontWeight.w600,
                size: 12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (toolResult != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: toolResult.isError
                        ? p.err.withValues(alpha: 0.15)
                        : p.ok.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: T(
                    toolResult.isError ? 'ERROR' : 'SUCCESS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    size: 10,
                    mono: true,
                    weight: FontWeight.w700,
                    color: toolResult.isError ? p.err : p.ok,
                  ),
                ),
                if (session.lastToolDurationMs != null)
                  T(
                    '${session.lastToolDurationMs}ms',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    size: 11,
                    mono: true,
                    color: p.muted,
                  ),
              ],
            ],
            trailing: [
              if (toolResult != null) ...[
                ViewModeMenu(
                  current: _viewMode,
                  options: [
                    const MenuOpt('Formatted', 'Formatted', Ic.fmtRaw),
                    const MenuOpt('Raw JSON', 'Raw JSON', Ic.fmtJson),
                    const MenuOpt('Tree', 'Tree', Ic.workflow),
                    if (toolResult.content.any((c) => c.isImage))
                      const MenuOpt('Images', 'Images', Ic.image),
                  ],
                  onSelect: (m) => setState(() => _viewMode = m),
                ),
                IconBtnGroup(
                  children: [
                    if (_viewMode == 'Tree') ...[
                      _groupBtn(
                        Ic.expandAll,
                        'Expand all',
                        () => setState(() => _treeExpandSignal++),
                      ),
                      _groupBtn(
                        Ic.collapseAll,
                        'Collapse all',
                        () => setState(() => _treeExpandSignal--),
                      ),
                    ],
                    if (_viewMode == 'Raw JSON' || _viewMode == 'Formatted')
                      _groupBtn(
                        Ic.wrap,
                        'Wrap lines',
                        () => setState(() => _wrapCode = !_wrapCode),
                        color: _wrapCode ? p.accent : null,
                      ),
                    _groupBtn(Ic.copy, 'Copy', () {
                      final text =
                          _viewMode == 'Raw JSON' || _viewMode == 'Tree'
                          ? Json.stringify(toolResult.raw ?? {}, pretty: true)
                          : toolResult.fullText;
                      Clipboard.setData(ClipboardData(text: text));
                    }),
                    _groupBtn(
                      widget.isVertical ? Ic.splitH : Ic.splitV,
                      'Switch layout',
                      widget.onToggleLayout,
                    ),
                  ],
                ),
              ] else
                IconBtnGroup(
                  children: [
                    _groupBtn(
                      widget.isVertical ? Ic.splitH : Ic.splitV,
                      'Switch layout',
                      widget.onToggleLayout,
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Response Body
        Expanded(
          child: isRunning
              ? const Center(child: T('Executing request…'))
              : (toolResult == null
                    ? const EmptyState(
                        icon: Ic.send,
                        title: 'No response yet',
                        message: 'Run a tool, fetch a prompt or read a resource, and the output shows up here.',
                      )
                    : _buildToolOutput(p, toolResult)),
        ),
      ],
    );
  }

  Widget _buildToolOutput(Pal p, McpToolResult result) {
    if (_viewMode == 'Tree') {
      final dynamic rootObj =
          result.raw ??
          {
            'content': result.content.map((c) => c.toJson()).toList(),
            'isError': result.isError,
          };
      return Padding(
        padding: const EdgeInsets.all(8),
        child: JsonTree(
          root: rootObj,
          expandSignal: _treeExpandSignal,
          onCopy: (val, msg) {
            Clipboard.setData(ClipboardData(text: val));
          },
        ),
      );
    }

    if (_viewMode == 'Raw JSON') {
      final jsonText = Json.stringify(result.raw ?? {}, pretty: true);
      return Padding(
        padding: const EdgeInsets.all(8),
        child: CodeView(text: jsonText, lang: 'json', wrap: _wrapCode),
      );
    }

    if (_viewMode == 'Images') {
      final imageItems = result.content.where((c) => c.isImage).toList();
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: imageItems.length,
        itemBuilder: (context, i) {
          final item = imageItems[i];
          final rawData = item.data;
          if (rawData == null) return const SizedBox.shrink();
          try {
            final bytes = base64Decode(rawData);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: p.field,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  T(
                    item.mimeType ?? 'image',
                    size: 10,
                    mono: true,
                    color: p.muted,
                  ),
                  Image.memory(bytes),
                ],
              ),
            );
          } catch (e) {
            return T('Failed to decode image data: $e', color: p.err);
          }
        },
      );
    }

    // Formatted mode
    final fullText = result.fullText;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: CodeView(
        text: fullText,
        lang: fullText.trim().startsWith('{') || fullText.trim().startsWith('[')
            ? 'json'
            : 'text',
        wrap: _wrapCode,
      ),
    );
  }

  Widget _buildTrafficDetails(Pal p, McpMessageLogEntry entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Traffic inspect header
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: HeaderBar(
            leading: [
              Ico(Ic.timer, tint: p.muted, size: 14),
              const T(
                'JSON-RPC Packet',
                weight: FontWeight.w600,
                size: 12,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: p.muted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: T(
                  entry.direction == McpMessageDirection.outgoing
                      ? 'OUTGOING'
                      : 'INCOMING',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  size: 9,
                  mono: true,
                  color: entry.direction == McpMessageDirection.outgoing
                      ? p.accent
                      : p.ok,
                ),
              ),
            ],
            trailing: [
              ViewModeMenu(
                current: _viewMode == 'Tree' ? 'Tree' : 'Raw JSON',
                options: const [
                  MenuOpt('Raw JSON', 'Raw JSON', Ic.fmtJson),
                  MenuOpt('Tree', 'Tree', Ic.workflow),
                ],
                onSelect: (m) => setState(() => _viewMode = m),
              ),
              IconBtnGroup(
                children: [
                  if (_viewMode == 'Tree') ...[
                    _groupBtn(
                      Ic.expandAll,
                      'Expand all',
                      () => setState(() => _treeExpandSignal++),
                    ),
                    _groupBtn(
                      Ic.collapseAll,
                      'Collapse all',
                      () => setState(() => _treeExpandSignal--),
                    ),
                  ],
                  _groupBtn(Ic.copy, 'Copy', () {
                    Clipboard.setData(
                      ClipboardData(text: entry.formattedPayload),
                    );
                  }),
                  _groupBtn(
                    widget.isVertical ? Ic.splitH : Ic.splitV,
                    'Switch layout',
                    widget.onToggleLayout,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Payload inspection
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: _viewMode == 'Tree'
                ? JsonTree(
                    root: entry.payload,
                    expandSignal: _treeExpandSignal,
                    onCopy: (val, msg) {
                      Clipboard.setData(ClipboardData(text: val));
                    },
                  )
                : CodeView(
                    text: entry.formattedPayload,
                    lang: 'json',
                    wrap: _wrapCode,
                  ),
          ),
        ),
      ],
    );
  }
}
