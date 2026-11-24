import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show SelectableText, Icons;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

enum _LogLevelFilter {
  all('ALL'),
  error('ERROR'),
  warn('WARN'),
  info('INFO'),
  debug('DEBUG'),
  stderr('STDERR');

  const _LogLevelFilter(this.label);
  final String label;
}

/// Live developer console viewer for server stderr logs and MCP notifications/message logs.
class ServerLogsView extends StatefulWidget {
  const ServerLogsView({super.key, required this.session});
  final McpSession session;

  @override
  State<ServerLogsView> createState() => _ServerLogsViewState();
}

class _ServerLogsViewState extends State<ServerLogsView> {
  String _filter = '';
  _LogLevelFilter _selectedFilter = _LogLevelFilter.all;
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  int _lastLogCount = 0;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionUpdate);
  }

  @override
  void didUpdateWidget(ServerLogsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSessionUpdate);
      widget.session.addListener(_onSessionUpdate);
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSessionUpdate() {
    if (mounted) {
      setState(() {});
      _maybeAutoScroll();
    }
  }

  void _maybeAutoScroll() {
    if (!_autoScroll || !_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _autoScroll) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    setState(() => _autoScroll = true);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  String _formatTimestamp(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    final ms = t.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final client = widget.session.client;
    final stderrEntries = client?.stderrEntries ?? const [];
    final serverLogs = client?.serverLogs ?? const [];

    // Combine stderr and notifications/message logs sorted by timestamp
    final combined = <_LogEntry>[
      for (final err in stderrEntries)
        _LogEntry(
          type: 'STDERR',
          text: err.text,
          timestamp: err.timestamp,
          level: McpLogLevel.error,
          isStderr: true,
        ),
      for (final msg in serverLogs)
        _LogEntry(
          type: msg.level.name.toUpperCase(),
          text: msg.dataString,
          logger: msg.logger,
          timestamp: msg.timestamp,
          level: msg.level,
        ),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (combined.length != _lastLogCount) {
      _lastLogCount = combined.length;
      _maybeAutoScroll();
    }

    // Counts for filter pills
    int errorCount = 0;
    int warnCount = 0;
    int infoCount = 0;
    int debugCount = 0;
    int stderrCount = 0;

    for (final entry in combined) {
      if (entry.isStderr) stderrCount++;
      switch (entry.level) {
        case McpLogLevel.error ||
            McpLogLevel.critical ||
            McpLogLevel.alert ||
            McpLogLevel.emergency:
          errorCount++;
        case McpLogLevel.warning:
          warnCount++;
        case McpLogLevel.info || McpLogLevel.notice:
          infoCount++;
        case McpLogLevel.debug:
          debugCount++;
        case null:
          break;
      }
    }

    // Filter by category and text search
    final filtered = combined.where((l) {
      if (_selectedFilter != _LogLevelFilter.all) {
        switch (_selectedFilter) {
          case _LogLevelFilter.stderr:
            if (!l.isStderr) return false;
          case _LogLevelFilter.error:
            if (l.level != McpLogLevel.error &&
                l.level != McpLogLevel.critical &&
                l.level != McpLogLevel.alert &&
                l.level != McpLogLevel.emergency) {
              return false;
            }
          case _LogLevelFilter.warn:
            if (l.level != McpLogLevel.warning) return false;
          case _LogLevelFilter.info:
            if (l.level != McpLogLevel.info && l.level != McpLogLevel.notice) {
              return false;
            }
          case _LogLevelFilter.debug:
            if (l.level != McpLogLevel.debug) return false;
          case _LogLevelFilter.all:
            break;
        }
      }

      if (_filter.isNotEmpty) {
        final q = _filter.toLowerCase();
        final matchesText = l.text.toLowerCase().contains(q);
        final matchesLogger = l.logger?.toLowerCase().contains(q) ?? false;
        final matchesType = l.type.toLowerCase().contains(q);
        return matchesText || matchesLogger || matchesType;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Controls & Filter Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Field(
                      value: _filter,
                      onChange: (v) => setState(() => _filter = v),
                      placeholder: 'Filter server logs…',
                      prefixIcon: Ic.search,
                      clearable: true,
                      highlightVars: false,
                    ),
                  ),
                  Btn(
                    label: _autoScroll ? 'Auto-scroll: ON' : 'Auto-scroll: OFF',
                    icon: _autoScroll
                        ? Icons.arrow_downward_rounded
                        : Icons.pause_rounded,
                    primary: _autoScroll,
                    onClick: () {
                      setState(() => _autoScroll = !_autoScroll);
                      if (_autoScroll) _scrollToBottom();
                    },
                  ),
                  Btn(
                    label: 'Copy All',
                    icon: Ic.copy,
                    onClick: () {
                      if (filtered.isEmpty) return;
                      final buffer = StringBuffer();
                      for (var i = 0; i < filtered.length; i++) {
                        final item = filtered[i];
                        final loggerPart = item.logger != null
                            ? ' [${item.logger}]'
                            : '';
                        buffer.writeln(
                          '${_formatTimestamp(item.timestamp)} [${item.type}]$loggerPart ${item.text}',
                        );
                      }
                      Platform.copy(buffer.toString());
                      AppScope.of(context).showToast(
                        'Copied ${filtered.length} log lines to clipboard',
                      );
                    },
                  ),
                  Btn(
                    label: 'Clear',
                    icon: Ic.delete,
                    onClick: () {
                      client?.clearLogs();
                      setState(() {});
                    },
                  ),
                ],
              ),

              // Filter segmented button row
              Row(
                children: [
                  Container(
                    height: 28,
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: p.field,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: p.border, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSegment(
                          p: p,
                          filter: _LogLevelFilter.all,
                          label: 'ALL',
                          count: combined.length,
                        ),
                        _buildDivider(p, 0),
                        _buildSegment(
                          p: p,
                          filter: _LogLevelFilter.error,
                          label: 'ERROR',
                          count: errorCount,
                          accentColor: p.err,
                        ),
                        _buildDivider(p, 1),
                        _buildSegment(
                          p: p,
                          filter: _LogLevelFilter.warn,
                          label: 'WARN',
                          count: warnCount,
                          accentColor: p.warn,
                        ),
                        _buildDivider(p, 2),
                        _buildSegment(
                          p: p,
                          filter: _LogLevelFilter.info,
                          label: 'INFO',
                          count: infoCount,
                          accentColor: p.ok,
                        ),
                        _buildDivider(p, 3),
                        _buildSegment(
                          p: p,
                          filter: _LogLevelFilter.debug,
                          label: 'DEBUG',
                          count: debugCount,
                        ),
                        _buildDivider(p, 4),
                        _buildSegment(
                          p: p,
                          filter: _LogLevelFilter.stderr,
                          label: 'STDERR',
                          count: stderrCount,
                          accentColor: p.err,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  T(
                    filtered.length == combined.length
                        ? '${combined.length} lines'
                        : '${filtered.length} of ${combined.length} lines',
                    mono: true,
                    size: 11,
                    color: p.muted,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Terminal Console Body Area
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  icon: Ic.fmtRaw,
                  title: 'No server logs yet',
                  message: 'Standard error output and MCP notifications/message logs from the active server will stream here in real time.',
                )
              : NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      // If user scrolled up significantly, pause auto-scroll
                      if (_scrollController.hasClients) {
                        final isAtBottom =
                            _scrollController.position.pixels >=
                            _scrollController.position.maxScrollExtent - 20;
                        if (!isAtBottom && _autoScroll) {
                          setState(() => _autoScroll = false);
                        }
                      }
                    }
                    return false;
                  },
                  child: Container(
                    color: p.dark
                        ? const Color(0xFF131518)
                        : const Color(0xFFF6F8FA),
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final isErr =
                            item.isStderr ||
                            item.level == McpLogLevel.error ||
                            item.level == McpLogLevel.critical ||
                            item.level == McpLogLevel.alert ||
                            item.level == McpLogLevel.emergency;
                        final isWarn = item.level == McpLogLevel.warning;

                        return HoverBuilder(
                          builder: (context, hovered) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: hovered
                                  ? p.hover.withValues(alpha: 0.5)
                                  : (i.isEven
                                        ? p.hover.withValues(alpha: 0.18)
                                        : const Color(0x00000000)),
                              border: Border(
                                bottom: BorderSide(
                                  color: p.border.withValues(alpha: 0.2),
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 8,
                              children: [
                                // Line number (fixed width, aligned right)
                                SizedBox(
                                  width: 34,
                                  child: Text(
                                    '${i + 1}',
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontFamily: monoFamily,
                                      fontSize: 11,
                                      height: 1.4,
                                      color: p.muted.withValues(alpha: 0.5),
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),

                                // Timestamp (fixed width, single line)
                                SizedBox(
                                  width: 94,
                                  child: Text(
                                    _formatTimestamp(item.timestamp),
                                    maxLines: 1,
                                    softWrap: false,
                                    style: TextStyle(
                                      fontFamily: monoFamily,
                                      fontSize: 11,
                                      height: 1.4,
                                      color: p.muted.withValues(alpha: 0.75),
                                    ),
                                  ),
                                ),

                                // Type / Severity badge (fixed width for perfect horizontal alignment)
                                SizedBox(
                                  width: 58,
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 1),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _badgeBg(p, item),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.type,
                                      style: TextStyle(
                                        fontFamily: monoFamily,
                                        fontSize: 9,
                                        height: 1.15,
                                        fontWeight: FontWeight.w700,
                                        color: _badgeFg(p, item),
                                      ),
                                    ),
                                  ),
                                ),

                                // Main Message Text with optional logger prefix
                                Expanded(
                                  child: SelectableText.rich(
                                    TextSpan(
                                      children: [
                                        if (item.logger != null &&
                                            item.logger!.isNotEmpty)
                                          TextSpan(
                                            text: '[${item.logger}] ',
                                            style: TextStyle(
                                              color: p.accent.withValues(
                                                alpha: 0.85,
                                              ),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        TextSpan(
                                          text: item.text,
                                          style: TextStyle(
                                            color: isErr
                                                ? p.err
                                                : (isWarn ? p.warn : p.text),
                                          ),
                                        ),
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontFamily: monoFamily,
                                      fontSize: 11.5,
                                      height: 1.4,
                                    ),
                                  ),
                                ),

                                // Quick Copy Line Button (visible on hover)
                                if (hovered)
                                  Clickable(
                                    onClick: () {
                                      final copyText =
                                          item.logger != null &&
                                              item.logger!.isNotEmpty
                                          ? '[${item.logger}] ${item.text}'
                                          : item.text;
                                      Platform.copy(copyText);
                                      AppScope.of(context)
                                          .showToast('Log line copied');
                                    },
                                    cursor: SystemMouseCursors.click,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Ic.copy,
                                        size: 13,
                                        color: p.muted,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ),

        // 3. Status Bar Footer
        Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: p.panel,
            border: Border(
              top: BorderSide(color: p.border.withValues(alpha: 0.7)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _autoScroll ? p.ok : p.warn,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              T(
                _autoScroll ? 'STREAM LIVE' : 'AUTO-SCROLL PAUSED',
                size: 9.5,
                mono: true,
                weight: FontWeight.w600,
                color: _autoScroll ? p.ok : p.warn,
              ),
              if (!_autoScroll) ...[
                const SizedBox(width: 8),
                Clickable(
                  onClick: _scrollToBottom,
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_downward_rounded,
                        size: 11,
                        color: p.accent,
                      ),
                      const SizedBox(width: 3),
                      T(
                        'Jump to bottom',
                        size: 10,
                        mono: true,
                        color: p.accent,
                        weight: FontWeight.w600,
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              if (errorCount > 0) ...[
                T(
                  '$errorCount errors',
                  size: 10,
                  mono: true,
                  weight: FontWeight.w600,
                  color: p.err,
                ),
                const SizedBox(width: 10),
              ],
              if (warnCount > 0) ...[
                T(
                  '$warnCount warnings',
                  size: 10,
                  mono: true,
                  weight: FontWeight.w600,
                  color: p.warn,
                ),
                const SizedBox(width: 10),
              ],
              T(
                '${filtered.length} visible lines',
                size: 10,
                mono: true,
                color: p.muted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(Pal p, int index) {
    final prev = _LogLevelFilter.values[index];
    final next = _LogLevelFilter.values[index + 1];
    final hideDivider = _selectedFilter == prev || _selectedFilter == next;
    return Container(
      width: 1,
      height: 14,
      color: hideDivider
          ? const Color(0x00000000)
          : p.border.withValues(alpha: 0.65),
    );
  }

  Widget _buildSegment({
    required Pal p,
    required _LogLevelFilter filter,
    required String label,
    required int count,
    Color? accentColor,
  }) {
    final selected = _selectedFilter == filter;

    return SizedBox(
      width: 82,
      height: 24,
      child: Clickable(
        onClick: () => setState(() => _selectedFilter = filter),
        cursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? p.panel : const Color(0x00000000),
            borderRadius: BorderRadius.circular(4),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: monoFamily,
                      fontSize: 10,
                      height: 1.15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? (accentColor ?? p.text) : p.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? (selected && accentColor != null
                                ? accentColor.withValues(alpha: 0.16)
                                : (accentColor == p.err
                                      ? p.err.withValues(alpha: 0.14)
                                      : p.border.withValues(alpha: 0.5)))
                          : p.border.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontFamily: monoFamily,
                        fontSize: 8.5,
                        height: 1.15,
                        fontWeight: count > 0
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: count > 0
                            ? (selected
                                  ? (accentColor ?? p.text)
                                  : (accentColor == p.err ? p.err : p.text))
                            : p.muted.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _badgeBg(Pal p, _LogEntry item) {
    if (item.isStderr) return p.err.withValues(alpha: 0.15);
    switch (item.level) {
      case McpLogLevel.error ||
          McpLogLevel.critical ||
          McpLogLevel.alert ||
          McpLogLevel.emergency:
        return p.err.withValues(alpha: 0.15);
      case McpLogLevel.warning:
        return p.warn.withValues(alpha: 0.15);
      case McpLogLevel.info || McpLogLevel.notice:
        return p.ok.withValues(alpha: 0.15);
      case McpLogLevel.debug:
        return p.muted.withValues(alpha: 0.15);
      case null:
        return p.muted.withValues(alpha: 0.15);
    }
  }

  Color _badgeFg(Pal p, _LogEntry item) {
    if (item.isStderr) return p.err;
    switch (item.level) {
      case McpLogLevel.error ||
          McpLogLevel.critical ||
          McpLogLevel.alert ||
          McpLogLevel.emergency:
        return p.err;
      case McpLogLevel.warning:
        return p.warn;
      case McpLogLevel.info || McpLogLevel.notice:
        return p.ok;
      case McpLogLevel.debug:
        return p.muted;
      case null:
        return p.muted;
    }
  }
}

class _LogEntry {
  const _LogEntry({
    required this.type,
    required this.text,
    this.logger,
    required this.timestamp,
    this.level,
    this.isStderr = false,
  });

  final String type;
  final String text;
  final String? logger;
  final DateTime timestamp;
  final McpLogLevel? level;
  final bool isStderr;
}
