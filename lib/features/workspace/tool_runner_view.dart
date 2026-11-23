import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show SelectableText, Tooltip;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/overlay.dart';
import 'package:rocket_mcp/components/resizable_pane.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/features/workspace/list_empty_state.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/badge_icon_btn.dart';
import 'package:rocket_mcp/components/header_bar.dart';
import 'package:rocket_mcp/components/icon_btn_group.dart';
import 'package:rocket_mcp/components/item_tile.dart';
import 'package:rocket_mcp/components/mini_spinner.dart';
import 'package:rocket_mcp/features/workspace/tool_argument_field.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/utils/json_check.dart';
import 'package:rocket_mcp/components/response_controls.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Interactive tool runner for exploring, configuring arguments, and executing MCP tools.
class ToolRunnerView extends StatefulWidget {
  const ToolRunnerView({super.key, required this.session});
  final McpSession session;

  @override
  State<ToolRunnerView> createState() => _ToolRunnerViewState();
}

class _ToolRunnerViewState extends State<ToolRunnerView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final session = widget.session;
    final tools = session.tools;
    final filteredTools = _searchQuery.isEmpty
        ? tools
        : tools
              .where(
                (t) =>
                    t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (t.description?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();

    final selectedTool = session.selectedTool;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tools list sidebar
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
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Field(
                    value: _searchQuery,
                    onChange: (v) => setState(() => _searchQuery = v),
                    placeholder: 'Filter tools…',
                  ),
                ),
                Container(height: 1, color: p.border),
                Expanded(
                  child: filteredTools.isEmpty
                      ? ListEmptyState(
                          noun: 'tools',
                          icon: Ic.tool,
                          filtered: tools.isNotEmpty,
                          onRefresh: session.refreshTools,
                        )
                      : ListView.builder(
                          itemCount: filteredTools.length,
                          itemBuilder: (context, i) {
                            final tool = filteredTools[i];
                            return ItemTile(
                              icon: Ic.tool,
                              title: tool.name,
                              subtitle: tool.description,
                              selected: tool.name == selectedTool?.name,
                              onClick: () => session.selectedTool = tool,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Tool execution builder
        Expanded(
          child: selectedTool == null
              ? EmptyState(
                  icon: Ic.tool,
                  title: 'Select a tool',
                  message: tools.isEmpty
                      ? 'Tools the server exposes appear in the list.'
                      : 'Pick a tool from the list to fill in its arguments and run it.',
                  suggestions: [
                    for (final t in tools.take(4))
                      EmptySuggestion(
                        t.name,
                        () => session.selectedTool = t,
                        icon: Ic.tool,
                      ),
                  ],
                )
              : _ToolForm(session: session, tool: selectedTool),
        ),
      ],
    );
  }
}

class _ToolForm extends StatefulWidget {
  const _ToolForm({required this.session, required this.tool});
  final McpSession session;
  final McpTool tool;

  @override
  State<_ToolForm> createState() => _ToolFormState();
}

class _ToolFormState extends State<_ToolForm> {
  /// Set once a run was attempted with required values missing, so empty required inputs are outlined in red.
  bool _attempted = false;

  /// One key per argument so a warning can scroll its field into view.
  final Map<String, GlobalKey> _fieldKeys = {};

  /// One focus node per argument, so a warning can put the cursor in its input.
  final Map<String, FocusNode> _focusNodes = {};

  /// The argument shown with a red highlight after being picked from the warnings list.
  String? _flashed;
  Timer? _flashTimer;

  McpSession get _session => widget.session;

  @override
  void dispose() {
    _flashTimer?.cancel();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Everything that blocks a run right now: an invalid JSON body, or required arguments without a value.
  List<_Warning> get _warnings {
    final jsonProblem = _jsonProblem;
    return [
      if (jsonProblem != null)
        _Warning(title: 'Invalid JSON', message: jsonProblem),
      for (final name in _missingRequired)
        _Warning(
          title: name,
          message: 'Required, but has no value',
          field: name,
        ),
    ];
  }

  Future<void> _showWarnings(BuildContext anchor) async {
    final warnings = _warnings;
    final picked = await showAnchoredPopup<_Warning>(
      anchor,
      anchor: anchorRectOf(anchor),
      width: 320,
      offset: const Offset(0, 4),
      builder: (context, close) =>
          _WarningsList(warnings: warnings, onPick: close),
    );
    if (picked?.field != null) _reveal(picked!.field!);
  }

  /// Scrolls the argument into view, puts the cursor in its input and flashes it red for a moment.
  void _reveal(String field) {
    setState(() => _flashed = field);
    final target = _fieldKeys[field]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(
        target,
        alignment: 0.15,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
    _focusNodes[field]?.requestFocus();
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _flashed = null);
    });
  }

  @override
  void didUpdateWidget(_ToolForm old) {
    super.didUpdateWidget(old);
    if (old.tool.name != widget.tool.name) _attempted = false;
  }

  void _updateArg(String key, Object? value) {
    _session.toolArguments[key] = value;
    _session.toolJsonString = const JsonEncoder.withIndent('  ')
        .convert(_session.toolArguments);
    setState(() {});
  }

  bool _isMissing(String key) {
    final value = _session.toolArguments[key];
    return value == null || (value is String && value.trim().isEmpty);
  }

  /// What is wrong with the JSON in the editor, or null; only checked in JSON mode.
  String? get _jsonProblem => _session.toolJsonMode
      ? argumentsJsonProblem(_session.toolJsonString)
      : null;

  List<String> get _missingRequired => _session.toolJsonMode
      ? const []
      : [
          for (final key in widget.tool.requiredProperties)
            if (_isMissing(key)) key,
        ];

  void _run() {
    if (_session.isRunningTool ||
        _session.status != McpServerStatus.connected) {
      return;
    }
    final problem = _jsonProblem;
    if (problem != null) {
      AppScope.read(context).showToast('Fix the JSON first: $problem');
      return;
    }
    final missing = _missingRequired;
    if (missing.isNotEmpty) {
      setState(() => _attempted = true);
      AppScope.read(context).showToast('Fill in: ${missing.join(', ')}');
      return;
    }
    _session.executeTool();
  }

  /// Switches between the form and the JSON editor, carrying the typed arguments across in either direction.
  void _setJsonMode(bool json) {
    if (json == _session.toolJsonMode) return;
    if (!json) {
      try {
        final decoded = jsonDecode(_session.toolJsonString);
        if (decoded is Map) {
          _session.toolArguments
            ..clear()
            ..addAll(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        // The JSON is not valid yet: keep the form's current values rather than losing them.
      }
    }
    _session.toolJsonMode = json;
  }

  /// Re-indents the JSON in the editor; leaves it alone when it does not parse.
  void _formatJson() {
    if (_jsonProblem != null) return;
    _session.toolJsonString = const JsonEncoder.withIndent('  ')
        .convert(jsonDecode(_session.toolJsonString));
  }

  void _reset() {
    _session.toolArguments.clear();
    _session.toolJsonString = '{\n}';
    setState(() => _attempted = false);
  }

  void _copyArguments() {
    final args = _session.toolJsonMode
        ? _session.toolJsonString
        : const JsonEncoder.withIndent('  ').convert(_session.toolArguments);
    Platform.copy(args);
    AppScope.read(context).showToast('Arguments copied');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final session = _session;
    final tool = widget.tool;
    final props = tool.properties;
    final requiredNames = tool.requiredProperties.toSet();
    final description = tool.description;

    // One full-bleed panel: identity and the Form / JSON switch with the run controls stay at the top, and the
    // arguments fill and scroll in the rest of the height. Cmd / Ctrl + Enter runs the tool from any input.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _run,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _run,
      },
      child: ColoredBox(
        color: p.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The header holds only what the tool is: its name and full description.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  T(
                    tool.name,
                    size: 16,
                    lineHeight: 1.5,
                    weight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description != null && description.isNotEmpty)
                    // The full description; a very long one scrolls inside its own box so the arguments below keep
                    // their room.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: SingleChildScrollView(
                        primary: false,
                        child: SelectableText(
                          description,
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 12,
                            height: 1.55,
                            letterSpacing: bodyLetterSpacing,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // The form section's toolbar: input mode on the left; on the right the warnings button, the copy / clear
            // actions and Run. It adapts to the pane width (see [_ToolbarSize]).
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: p.field,
              child: _toolbar(p),
            ),
            Expanded(
              // The "no arguments" message sits outside the scroll view so it can centre in the free space.
              child: ColoredBox(
                color: p.panel,
                child: !session.toolJsonMode && props.isEmpty
                    ? const EmptyState(
                        compact: true,
                        icon: Ic.checkCircle,
                        title: 'No arguments',
                        message: 'This tool takes no parameters.',
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: session.toolJsonMode
                            ? _jsonEditor(p)
                            : _arguments(p, props, requiredNames),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The form section's toolbar contents: the input mode menu on the left; the warnings button, the copy / clear /
  /// format actions and Run on the right.
  Widget _toolbar(Pal p) {
    final session = _session;
    final running = session.isRunningTool;
    final canRun = session.status == McpServerStatus.connected && !running;
    return HeaderBar(
      spacing: 10,
      leading: [
        ViewModeMenu(
          current: session.toolJsonMode ? 'JSON' : 'Form',
          options: const [
            MenuOpt('Form', 'Form', Ic.formBody),
            MenuOpt('JSON', 'JSON', Ic.fmtJson),
          ],
          onSelect: (mode) => _setJsonMode(mode == 'JSON'),
        ),
      ],
      trailing: [
        if (_warnings.isNotEmpty)
          Builder(
            builder: (anchor) => BadgeIconBtn(
              icon: Ic.warning,
              count: _warnings.length,
              color: p.warn,
              tooltip: 'Show warnings',
              onClick: () => _showWarnings(anchor),
            ),
          ),
        IconBtnGroup(
          children: [
            if (session.toolJsonMode)
              IconBtn(
                icon: Ic.fmtRaw,
                tooltip: 'Format JSON',
                boxSize: IconBtnGroup.boxSize,
                size: IconBtnGroup.iconSize,
                onClick: () => setState(_formatJson),
              ),
            IconBtn(
              icon: Ic.copy,
              tooltip: 'Copy arguments as JSON',
              boxSize: IconBtnGroup.boxSize,
              size: IconBtnGroup.iconSize,
              onClick: _copyArguments,
            ),
            IconBtn(
              icon: Ic.refresh,
              tooltip: 'Clear arguments',
              boxSize: IconBtnGroup.boxSize,
              size: IconBtnGroup.iconSize,
              onClick: _reset,
            ),
          ],
        ),
        Tooltip(
          message: 'Run (${Platform.isMac ? '⌘' : 'Ctrl'}+Enter)',
          child: Btn(
            label: running ? 'Running…' : 'Run',
            icon: running ? null : Ic.send,
            leading: running ? const MiniSpinner(size: 13) : null,
            primary: true,
            enabled: canRun,
            onClick: _run,
          ),
        ),
      ],
    );
  }

  /// The raw JSON editor with its validation: a red outline and the problem under it, or a green "Valid JSON".
  Widget _jsonEditor(Pal p) {
    final problem = _jsonProblem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Container(
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: problem == null ? const Color(0x00000000) : p.err,
            ),
          ),
          child: AreaField(
            value: _session.toolJsonString,
            onChange: (v) {
              _session.toolJsonString = v;
              setState(() {});
            },
            placeholder: '{\n  "arg": "value"\n}',
            minHeight: 280,
            mono: true,
          ),
        ),
        Row(
          spacing: 6,
          children: [
            Ico(
              problem == null ? Ic.checkCircle : Ic.error,
              size: 14,
              tint: problem == null ? p.ok : p.err,
            ),
            Expanded(
              child: T(
                problem ?? 'Valid JSON',
                size: 11.5,
                lineHeight: 1.4,
                color: problem == null ? p.ok : p.err,
                weight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The argument inputs, required ones first, under small section headings when both kinds exist.
  Widget _arguments(
    Pal p,
    Map<String, dynamic> props,
    Set<String> requiredNames,
  ) {
    final required = [
      for (final e in props.entries)
        if (requiredNames.contains(e.key)) e,
    ];
    final optional = [
      for (final e in props.entries)
        if (!requiredNames.contains(e.key)) e,
    ];
    Widget section(String title, List<MapEntry<String, dynamic>> entries) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            if (required.isNotEmpty && optional.isNotEmpty)
              _SectionHeading(title: title, count: entries.length),
            for (final e in entries)
              ToolArgumentField(
                key: _fieldKeys.putIfAbsent(e.key, GlobalKey.new),
                focusNode: _focusNodes.putIfAbsent(e.key, FocusNode.new),
                name: e.key,
                schema: e.value is Map ? e.value as Map : const {},
                isRequired: requiredNames.contains(e.key),
                value: _session.toolArguments[e.key],
                onChange: (v) => _updateArg(e.key, v),
                showError:
                    (_attempted && _isMissing(e.key)) || _flashed == e.key,
              ),
          ],
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 26,
      children: [
        if (required.isNotEmpty) section('REQUIRED', required),
        if (optional.isNotEmpty) section('OPTIONAL', optional),
      ],
    );
  }
}

/// One thing that blocks a run, shown in the warnings popup. [field] is the argument to drill down to, if any.
class _Warning {
  const _Warning({required this.title, required this.message, this.field});
  final String title;
  final String message;
  final String? field;
}

/// The warnings popup: one row per problem; a row that names an argument takes you to it when clicked.
class _WarningsList extends StatelessWidget {
  const _WarningsList({required this.warnings, required this.onPick});
  final List<_Warning> warnings;
  final void Function(_Warning) onPick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
          child: T(
            '${warnings.length} ${warnings.length == 1 ? 'WARNING' : 'WARNINGS'}',
            size: 10.5,
            lineHeight: 1.3,
            weight: FontWeight.w700,
            color: p.muted,
          ),
        ),
        for (final w in warnings)
          PopupRow(
            onClick: () => onPick(w),
            child: Row(
              spacing: 10,
              children: [
                Ico(Ic.warning, size: 16, tint: p.warn),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      T(
                        w.title,
                        size: 12.5,
                        lineHeight: 1.3,
                        mono: w.field != null,
                        weight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      T(
                        w.message,
                        size: 11,
                        lineHeight: 1.4,
                        color: p.muted,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (w.field != null)
                  Ico(Ic.chevronRight, size: 15, tint: p.muted),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Row(
      spacing: 6,
      children: [
        T(
          title,
          size: 10.5,
          lineHeight: 1.3,
          weight: FontWeight.w700,
          color: p.muted,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: p.muted.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8),
          ),
          child: T(
            '$count',
            size: 10,
            lineHeight: 1.2,
            mono: true,
            weight: FontWeight.w600,
            color: p.muted,
          ),
        ),
        Expanded(child: Container(height: 1, color: p.border)),
      ],
    );
  }
}
