import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/code_view.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/icon_btn_group.dart';
import 'package:rocket_mcp/components/json_tree.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/mini_spinner.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/response_controls.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/json_check.dart';

class _RpcPreset {
  const _RpcPreset({
    required this.method,
    required this.params,
    required this.description,
  });

  final String method;
  final String params;
  final String description;
}

const _kRpcPresets = [
  _RpcPreset(
    method: 'ping',
    params: '{\n}',
    description: 'Check server reachability and latency',
  ),
  _RpcPreset(
    method: 'tools/list',
    params: '{\n}',
    description: 'List all callable MCP tools',
  ),
  _RpcPreset(
    method: 'tools/call',
    params: '{\n  "name": "example_tool",\n  "arguments": {}\n}',
    description: 'Call a tool with arguments object',
  ),
  _RpcPreset(
    method: 'resources/list',
    params: '{\n}',
    description: 'List static resources available',
  ),
  _RpcPreset(
    method: 'resources/templates/list',
    params: '{\n}',
    description: 'List dynamic resource URI templates',
  ),
  _RpcPreset(
    method: 'resources/read',
    params: '{\n  "uri": "memo://today"\n}',
    description: 'Read contents of a resource URI',
  ),
  _RpcPreset(
    method: 'prompts/list',
    params: '{\n}',
    description: 'List available MCP prompts',
  ),
  _RpcPreset(
    method: 'prompts/get',
    params: '{\n  "name": "example_prompt",\n  "arguments": {}\n}',
    description: 'Get rendered prompt messages',
  ),
  _RpcPreset(
    method: 'logging/setLevel',
    params: '{\n  "level": "debug"\n}',
    description: 'Change active server logging level',
  ),
  _RpcPreset(
    method: 'completion/complete',
    params:
        '{\n  "ref": {\n    "type": "ref/prompt",\n    "name": "example"\n  },\n  "argument": {\n    "name": "input",\n    "value": ""\n  }\n}',
    description: 'Request argument completion suggestions',
  ),
];

/// Interactive raw JSON-RPC console: compose custom requests, explore standard
/// MCP presets, beautify parameters, and inspect responses as syntax-highlighted
/// JSON or interactive trees with timing and latency metrics.
class RawJsonRpcView extends StatefulWidget {
  const RawJsonRpcView({super.key, required this.session, this.state});

  final McpSession session;
  final AppState? state;

  @override
  State<RawJsonRpcView> createState() => _RawJsonRpcViewState();
}

class _RawJsonRpcViewState extends State<RawJsonRpcView> {
  String _viewMode = 'Raw JSON';
  int _treeExpandSignal = 0;
  bool _wrapCode = true;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionUpdate);
  }

  @override
  void didUpdateWidget(RawJsonRpcView old) {
    super.didUpdateWidget(old);
    if (old.session != widget.session) {
      old.session.removeListener(_onSessionUpdate);
      widget.session.addListener(_onSessionUpdate);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionUpdate);
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) setState(() {});
  }

  Widget _groupBtn(
    IconData icon,
    String tooltip,
    VoidCallback onClick, {
    Color? color,
  }) =>
      IconBtn(
        icon: icon,
        tooltip: tooltip,
        color: color,
        boxSize: IconBtnGroup.boxSize,
        size: IconBtnGroup.iconSize,
        onClick: onClick,
      );

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _beautifyParams() {
    final trimmed = widget.session.rawParams.trim();
    if (trimmed.isEmpty) return;
    try {
      final decoded = jsonDecode(trimmed);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      widget.session.rawParams = formatted;
      AppScope.of(context).showToast('Parameters beautified');
    } catch (_) {
      AppScope.of(context).showToast('Cannot beautify: invalid JSON syntax');
    }
  }

  void _clearParams() {
    widget.session.rawParams = '{\n}';
  }

  void _copyResponse() {
    final res = widget.session.lastRawResponse;
    if (res == null) return;
    Platform.copy(res);
    AppScope.of(context).showToast('Copied JSON-RPC response to clipboard');
  }

  void _clearResponse() {
    widget.session.clearRawResponse();
  }

  Future<void> _showPresets(BuildContext anchorCtx) async {
    final picked = await showAnchoredPopup<_RpcPreset>(
      anchorCtx,
      anchor: anchorRectOf(anchorCtx),
      width: 320,
      offset: const Offset(0, 4),
      builder: (ctx, close) => Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Ico(Ic.bolt, size: 12, tint: ctx.pal.accent),
                  const SizedBox(width: 6),
                  T(
                    'COMMON MCP METHODS',
                    mono: true,
                    size: 9.5,
                    weight: FontWeight.w700,
                    color: ctx.pal.muted,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(height: 1, color: ctx.pal.border),
            for (final p in _kRpcPresets)
              HoverBuilder(
                cursor: SystemMouseCursors.click,
                onTap: () => close(p),
                builder: (context, hovered) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  color: hovered ? ctx.pal.hover : const Color(0x00000000),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            T(
                              p.method,
                              mono: true,
                              size: 11,
                              weight: FontWeight.w600,
                              color: hovered ? ctx.pal.accent : ctx.pal.text,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1.5),
                            T(
                              p.description,
                              size: 10,
                              color: ctx.pal.muted,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Ico(Ic.chevronRight, size: 12, tint: ctx.pal.muted),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      widget.session.rawMethod = picked.method;
      widget.session.rawParams = picked.params;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final app = widget.state ?? AppScope.of(context);
    final isVertical = app.settings.verticalLayout;

    return SplitPane(
      vertical: isVertical,
      fraction: app.splitFraction,
      onFraction: (v) => app.splitFraction = v,
      first: _buildRequestPane(context, p, app, isVertical),
      second: _buildResponsePane(context, p, app, isVertical),
    );
  }

  Widget _buildRequestPane(
    BuildContext context,
    Pal p,
    AppState app,
    bool isVertical,
  ) {
    final session = widget.session;
    final canSend =
        !session.isRunningRaw &&
        session.rawMethod.trim().isNotEmpty &&
        session.status == McpServerStatus.connected;

    final jsonProblem = argumentsJsonProblem(session.rawParams);
    final rawTrimmed = session.rawParams.replaceAll(RegExp(r'\s+'), '');
    final hasParams = rawTrimmed.isNotEmpty && rawTrimmed != '{}';

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (canSend) session.sendRawJsonRpc();
        },
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (canSend) session.sendRawJsonRpc();
        },
      },
      child: Focus(
        autofocus: false,
        child: Container(
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(
              right: isVertical ? BorderSide.none : BorderSide(color: p.border),
              bottom:
                  isVertical ? BorderSide(color: p.border) : BorderSide.none,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: p.panel,
                  border: Border(bottom: BorderSide(color: p.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Ico(Ic.fmtJson, tint: p.accent, size: 14),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: T(
                              'REQUEST',
                              size: 11,
                              mono: true,
                              weight: FontWeight.w700,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.border.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: T(
                              'JSON-RPC 2.0',
                              size: 9.5,
                              mono: true,
                              color: p.muted,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (btnCtx) => Btn(
                        label: 'Presets',
                        icon: Ic.bolt,
                        onClick: () => _showPresets(btnCtx),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconBtnGroup(
                      children: [
                        _groupBtn(
                          Ic.fmtJson,
                          'Beautify JSON parameters',
                          _beautifyParams,
                        ),
                        _groupBtn(
                          Ic.delete,
                          'Reset parameters',
                          _clearParams,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Request Body Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      // Method Row (Height aligned to CONTROL_H)
                      Row(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height: CONTROL_H,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: p.accent.withValues(alpha: 0.25),
                              ),
                            ),
                            child: T(
                              'RPC',
                              size: 11,
                              mono: true,
                              weight: FontWeight.w800,
                              color: p.accent,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            child: Field(
                              value: session.rawMethod,
                              onChange: (v) => session.rawMethod = v,
                              placeholder:
                                  'Method (e.g. tools/list, ping, resources/read)',
                              mono: true,
                              clearable: true,
                            ),
                          ),
                          Btn(
                            label: session.isRunningRaw ? 'Sending…' : 'Send',
                            icon: session.isRunningRaw ? null : Ic.send,
                            primary: true,
                            enabled: canSend,
                            onClick: session.sendRawJsonRpc,
                          ),
                          Container(
                            height: CONTROL_H,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: p.border.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: T(
                              Platform.isMac ? '⌘↵' : 'Ctrl+↵',
                              mono: true,
                              size: 10,
                              color: p.muted,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Parameters Label & Validation pill
                      Row(
                        children: [
                          const Flexible(
                            child: T(
                              'PARAMETERS (JSON OBJECT)',
                              size: 10.5,
                              mono: true,
                              weight: FontWeight.w600,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          if (!hasParams)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.border.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: T(
                                'Empty { }',
                                size: 10,
                                mono: true,
                                color: p.muted,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          else if (jsonProblem == null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: p.ok.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                spacing: 4,
                                children: [
                                  Ico(Ic.check, size: 10, tint: p.ok),
                                  T(
                                    'Valid JSON',
                                    size: 10,
                                    mono: true,
                                    weight: FontWeight.w600,
                                    color: p.ok,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            )
                          else
                            Tooltip(
                              message: jsonProblem,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: p.err.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    Ico(Ic.warning, size: 10, tint: p.err),
                                    T(
                                      'Invalid JSON',
                                      size: 10,
                                      mono: true,
                                      weight: FontWeight.w600,
                                      color: p.err,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Parameters Editor
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: p.field,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: hasParams && jsonProblem != null
                                  ? p.err.withValues(alpha: 0.6)
                                  : p.border,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: AreaField(
                              value: session.rawParams,
                              onChange: (v) => session.rawParams = v,
                              placeholder: '{\n  "key": "value"\n}',
                              expands: true,
                              mono: true,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsePane(
    BuildContext context,
    Pal p,
    AppState app,
    bool isVertical,
  ) {
    final session = widget.session;
    final hasResponse = session.lastRawResponse != null;

    dynamic parsedJson;
    if (hasResponse) {
      try {
        parsedJson = jsonDecode(session.lastRawResponse!);
      } catch (_) {
        parsedJson = null;
      }
    }

    return Container(
      color: p.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Response Header
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: p.panel,
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Ico(
                        Ic.incoming,
                        tint: hasResponse
                            ? (session.lastRawIsError ? p.err : p.ok)
                            : p.muted,
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      const Flexible(
                        child: T(
                          'RESPONSE',
                          size: 11,
                          mono: true,
                          weight: FontWeight.w700,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasResponse) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (session.lastRawIsError ? p.err : p.ok)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: T(
                            session.lastRawIsError ? 'ERROR' : 'SUCCESS',
                            size: 9.5,
                            mono: true,
                            weight: FontWeight.w700,
                            color: session.lastRawIsError ? p.err : p.ok,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (session.lastRawDuration != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: p.border.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: T(
                              '⚡ ${session.lastRawDuration!.inMilliseconds}ms',
                              size: 9.5,
                              mono: true,
                              color: p.muted,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.border.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: T(
                            _formatSize(session.lastRawResponse!.length),
                            size: 9.5,
                            mono: true,
                            color: p.muted,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (session.lastRawTimestamp != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: T(
                              _formatTime(session.lastRawTimestamp!),
                              size: 9.5,
                              mono: true,
                              color: p.muted,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ViewModeMenu(
                  current: _viewMode,
                  options: const [
                    MenuOpt('Raw JSON', 'Raw JSON', Ic.fmtJson),
                    MenuOpt('Tree', 'Tree', Ic.workflow),
                  ],
                  onSelect: (m) => setState(() => _viewMode = m),
                ),
                const SizedBox(width: 8),
                IconBtnGroup(
                  children: [
                    if (_viewMode == 'Tree') ...[
                      _groupBtn(
                        Ic.expandAll,
                        'Expand all nodes',
                        () => setState(() => _treeExpandSignal++),
                      ),
                      _groupBtn(
                        Ic.collapseAll,
                        'Collapse all nodes',
                        () => setState(() => _treeExpandSignal--),
                      ),
                    ],
                    if (_viewMode == 'Raw JSON')
                      _groupBtn(
                        _wrapCode ? Ic.wrap : Ic.wrap,
                        _wrapCode ? 'Disable line wrap' : 'Enable line wrap',
                        () => setState(() => _wrapCode = !_wrapCode),
                      ),
                    _groupBtn(
                      Ic.copy,
                      'Copy response to clipboard',
                      _copyResponse,
                    ),
                    _groupBtn(
                      Ic.delete,
                      'Clear response',
                      _clearResponse,
                    ),
                    _groupBtn(
                      isVertical ? Ic.splitH : Ic.splitV,
                      isVertical
                          ? 'Switch to side-by-side'
                          : 'Switch to stacked',
                      app.toggleLayout,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Response Body
          Expanded(
            child: session.isRunningRaw
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 10,
                      children: [
                        const MiniSpinner(size: 22),
                        T(
                          'Executing JSON-RPC request…',
                          size: 12,
                          color: p.muted,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  )
                : !hasResponse
                    ? const EmptyState(
                        icon: Ic.fmtJson,
                        title: 'No response yet',
                        message:
                            'Enter an MCP method and parameters, then click Send (⌘↵) to execute.',
                      )
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: _viewMode == 'Tree' && parsedJson != null
                            ? JsonTree(
                                root: parsedJson,
                                expandSignal: _treeExpandSignal,
                                onCopy: (val, msg) {
                                  Clipboard.setData(ClipboardData(text: val));
                                  AppScope.of(context).showToast(msg);
                                },
                              )
                            : CodeView(
                                text: session.lastRawResponse!,
                                lang: 'json',
                                wrap: _wrapCode,
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
