// ignore_for_file: constant_identifier_names, non_constant_identifier_names, deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/segmented.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/toggle.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';

enum _Section {
  General(
    'General',
    'How ${AppConfig.NAME} behaves day to day.',
    Icons.tune_rounded,
  ),
  Appearance('Appearance', 'Theme, size and layout.', Icons.palette_rounded),
  Connections(
    'Connections',
    'Defaults applied to every server connection.',
    Icons.hub_rounded,
  ),
  Network('Network', 'Certificates and proxy.', Icons.language_rounded),
  Shortcuts(
    'Shortcuts',
    'Keyboard shortcuts. Use Ctrl instead of ⌘ on Windows and Linux.',
    Icons.keyboard_outlined,
  ),
  Data(
    'Data',
    'Where ${AppConfig.NAME} keeps your files.',
    Icons.folder_outlined,
  );

  const _Section(this.label, this.blurb, this.icon);
  final String label;
  final String blurb;
  final IconData icon;
}

/// One setting: what it is, a line of explanation, and the control that changes it.
class _Pref {
  const _Pref(
    this.section,
    this.title,
    this.control, {
    this.desc = '',
    this.descColor,
  });
  final _Section section;
  final String title;
  final String desc;
  final Color? descColor;
  final Widget control;
}

class _BorderThenFill extends CustomPainter {
  _BorderThenFill({
    required this.border,
    required this.fill,
    required this.radius,
  });
  final Color border;
  final Color fill;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    canvas.drawRRect(
      r.deflate(0.5),
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawRRect(r, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_BorderThenFill o) =>
      o.border != border || o.fill != fill || o.radius != radius;
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.value,
    required this.onChange,
    this.suffix = '',
    this.width = 100,
  });
  final int value;
  final String suffix;
  final double width;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 8,
    children: [
      SizedBox(
        width: width,
        child: Field(
          value: value.toString(),
          onChange: (v) {
            final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
            onChange(
              int.tryParse(
                    digits.length > 7 ? digits.substring(0, 7) : digits,
                  ) ??
                  0,
            );
          },
          highlightVars: false,
        ),
      ),
      if (suffix.isNotEmpty) T(suffix, color: context.pal.muted, size: 12),
    ],
  );
}

/// App-level preferences dialog modeled on DevSpace: top segmented pill bar, clean cards, search filter, and done action.
class PreferencesDialog extends StatefulWidget {
  const PreferencesDialog({super.key, required this.state});
  final AppState state;

  @override
  State<PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<PreferencesDialog> {
  late _Section section;
  String query = '';
  bool confirmReset = false;

  @override
  void initState() {
    super.initState();
    section = _Section.values.firstWhere(
      (s) => s.label == widget.state.prefsSection,
      orElse: () => _Section.General,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.state.prefsSection = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = widget.state;
    final s = state.settings;
    void set(AppSettings n) => state.updateSettings(n);

    final prefs = <_Pref>[
      _Pref(
        _Section.General,
        'Save automatically',
        Toggle(
          on: s.autoSave,
          onChange: (v) => set(s.copyWith(autoSave: v)),
        ),
        desc: 'Saves tool parameters and prompt fields just before requests are dispatched.',
      ),
      _Pref(
        _Section.Appearance,
        'Theme',
        Segmented(
          options: [for (final m in ThemeMode.values) m.label],
          selected: s.theme.label,
          onSelect: (l) => set(
            s.copyWith(theme: ThemeMode.values.firstWhere((m) => m.label == l)),
          ),
        ),
        desc: s.theme == ThemeMode.system
            ? "Follows your operating system's light / dark setting (currently ${p.dark ? 'dark' : 'light'})."
            : 'Light or dark interface, or follow the operating system.',
      ),
      _Pref(
        _Section.Appearance,
        'Interface size',
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Btn(
              label: '−',
              onClick: () =>
                  set(s.copyWith(fontSize: (s.fontSize - 1).clamp(10, 20))),
              enabled: s.fontSize > 10,
            ),
            SizedBox(
              width: 48,
              child: T(
                '${s.fontSize * 100 ~/ 13}%',
                mono: true,
                weight: FontWeight.w600,
              ),
            ),
            Btn(
              label: '+',
              onClick: () =>
                  set(s.copyWith(fontSize: (s.fontSize + 1).clamp(10, 20))),
              enabled: s.fontSize < 20,
            ),
            if (s.fontSize != 13)
              Clickable(
                onClick: () => set(s.copyWith(fontSize: 13)),
                cursor: SystemMouseCursors.click,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: T('Reset', color: p.accent, size: 12),
                ),
              ),
          ],
        ),
        desc: 'Scales text and controls (also ⌘+ and ⌘−).',
      ),
      _Pref(
        _Section.Appearance,
        'Workspace layout',
        Segmented(
          options: const ['Stacked', 'Side by side'],
          selected: s.verticalLayout ? 'Stacked' : 'Side by side',
          onSelect: (v) => set(s.copyWith(verticalLayout: v == 'Stacked')),
        ),
        desc: 'Show the response below the request, or beside it.',
      ),
      _Pref(
        _Section.Connections,
        'Timeout',
        _NumberField(
          value: s.timeoutMs,
          suffix: 'ms',
          onChange: (v) => set(s.copyWith(timeoutMs: v)),
        ),
        desc: 'How long to wait for a server to answer a request. 0 means no limit.',
      ),
      _Pref(
        _Section.Connections,
        'User-Agent',
        SizedBox(
          width: 260,
          child: Field(
            value: s.userAgent,
            onChange: (v) => set(s.copyWith(userAgent: v)),
            placeholder: AppSettings.defaultUserAgent,
            highlightVars: false,
          ),
        ),
        desc: 'Sent when connecting over HTTP transports. Leave empty for the default.',
      ),
      _Pref(
        _Section.Network,
        'Verify SSL certificates',
        Toggle(
          on: s.sslVerify,
          onChange: (v) => set(s.copyWith(sslVerify: v)),
        ),
        desc: s.sslVerify
            ? 'Reject servers whose certificate cannot be verified.'
            : 'Off: connections are not verified. Use only for servers you trust, such as local development.',
        descColor: s.sslVerify ? null : p.err,
      ),
      _Pref(
        _Section.Network,
        'Use an HTTP proxy',
        Toggle(
          on: s.proxyEnabled,
          onChange: (v) => set(s.copyWith(proxyEnabled: v)),
        ),
        desc: 'Route every connection through the proxy below.',
      ),
      if (s.proxyEnabled) ...[
        _Pref(
          _Section.Network,
          'Proxy host',
          SizedBox(
            width: 260,
            child: Field(
              value: s.proxyHost,
              onChange: (v) => set(s.copyWith(proxyHost: v)),
              placeholder: 'proxy.example.com',
              highlightVars: false,
            ),
          ),
          desc: 'Host name or address of the proxy.',
        ),
        _Pref(
          _Section.Network,
          'Proxy port',
          _NumberField(
            value: s.proxyPort,
            width: 90,
            onChange: (v) => set(s.copyWith(proxyPort: v > 65535 ? 65535 : v)),
          ),
        ),
      ],
      for (final (what, keys) in [
        (
          'Command palette',
          '${Platform.isMac ? '⌘' : 'Ctrl+'}K  /  ${Platform.isMac ? '⌘' : 'Ctrl+'}P',
        ),
        ('Show / hide sidebar', '${Platform.isMac ? '⌘' : 'Ctrl+'}B'),
        (
          'Switch workspace layout',
          '${Platform.isMac ? '⌘⇧' : 'Ctrl+Shift+'}L',
        ),
        ('Switch workspace tabs', '${Platform.isMac ? '⌘' : 'Ctrl+'}1 – 6'),
        (
          'Next / previous tab',
          Platform.isMac
              ? '⌃⇥  /  ⌃⇧⇥  (${Platform.isMac ? '⌘' : 'Ctrl+'}[ / ])'
              : 'Ctrl+Tab  /  Ctrl+Shift+Tab',
        ),
        ('New server', '${Platform.isMac ? '⌘' : 'Ctrl+'}N'),
        (
          'Connect / reconnect active server',
          '${Platform.isMac ? '⌘' : 'Ctrl+'}R',
        ),
        (
          'Disconnect active server',
          '${Platform.isMac ? '⌘⇧' : 'Ctrl+Shift+'}D',
        ),
        ('Refresh capabilities', '${Platform.isMac ? '⌘⇧' : 'Ctrl+Shift+'}R'),
        ('Ping active server', '${Platform.isMac ? '⌘⇧' : 'Ctrl+Shift+'}P'),
        (
          'Import / export servers',
          '${Platform.isMac ? '⌘⇧' : 'Ctrl+Shift+'}I',
        ),
        ('Open data folder', '${Platform.isMac ? '⌘⇧' : 'Ctrl+Shift+'}O'),
        (
          'Zoom in / out / reset',
          '${Platform.isMac ? '⌘+' : 'Ctrl+='}  ${Platform.isMac ? '⌘−' : 'Ctrl+-'}  ${Platform.isMac ? '⌘0' : 'Ctrl+0'}',
        ),
        (
          'Preferences / Settings',
          Platform.isMac ? '⌘,  /  ⌘/' : 'Ctrl+,  /  F1',
        ),
      ])
        _Pref(
          _Section.Shortcuts,
          what,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: p.bg,
              borderRadius: BorderRadius.circular(5),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: p.border, width: 1),
            ),
            child: T(keys, mono: true, size: 12),
          ),
        ),
      _Pref(
        _Section.Data,
        'Storage location',
        Btn(
          label: Platform.revealLabel,
          onClick: () => Platform.reveal(AppStore.dir),
        ),
        desc: AppStore.dir,
      ),
      _Pref(
        _Section.Data,
        'Reset preferences',
        !confirmReset
            ? Btn(
                label: 'Reset…',
                onClick: () => setState(() => confirmReset = true),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  T('Are you sure?', color: p.err, size: 12),
                  Btn(
                    label: 'Cancel',
                    onClick: () => setState(() => confirmReset = false),
                  ),
                  Btn(
                    label: 'Reset',
                    onClick: () {
                      set(const AppSettings());
                      setState(() => confirmReset = false);
                      state.showToast('Preferences reset to defaults');
                    },
                    danger: true,
                  ),
                ],
              ),
        desc: 'Restore every setting to its default. Your server configurations are not touched.',
      ),
    ];

    final q = query.trim();
    final searching = q.isNotEmpty;
    final ql = q.toLowerCase();
    final shown = searching
        ? prefs
              .where(
                (x) =>
                    x.title.toLowerCase().contains(ql) ||
                    x.desc.toLowerCase().contains(ql) ||
                    x.section.label.toLowerCase().contains(ql),
              )
              .toList()
        : prefs.where((x) => x.section == section).toList();
    final groups = <_Section, List<_Pref>>{};
    for (final x in shown) {
      groups.putIfAbsent(x.section, () => []).add(x);
    }

    return ModalScaffold(
      title: 'Preferences',
      width: 680,
      onClose: () => state.modal = null,
      actions: [
        Expanded(
          child: T(
            'Changes are saved as you make them.',
            color: p.muted,
            size: 11.5,
          ),
        ),
        Btn(
          label: 'Done',
          primary: true,
          height: 32,
          onClick: () => state.modal = null,
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Category Segmented Pills Bar (matching DevSpace)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: p.field,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.border, width: 1),
              ),
              child: Row(
                children: [
                  for (final cat in _Section.values)
                    Expanded(
                      child: ClickableNoRipple(
                        onClick: () => setState(() {
                          query = '';
                          section = cat;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: !searching && section == cat
                                ? p.panel
                                : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: !searching && section == cat
                                  ? p.border
                                  : const Color(0x00000000),
                              width: 1,
                            ),
                            boxShadow: !searching && section == cat
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF000000,
                                      ).withValues(alpha: p.dark ? 0.3 : 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.icon,
                                size: 13,
                                color: !searching && section == cat
                                    ? p.accent
                                    : p.muted,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: T(
                                  cat.label,
                                  size: 11.5,
                                  weight: !searching && section == cat
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: !searching && section == cat
                                      ? p.text
                                      : p.muted,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Search input field
            Field(
              value: query,
              onChange: (v) => setState(() => query = v),
              placeholder: 'Search preferences…',
              highlightVars: false,
            ),

            const SizedBox(height: 12),

            // 2. Active Category Content Area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!searching) ...[
                      Row(
                        children: [
                          Icon(section.icon, size: 16, color: p.accent),
                          const SizedBox(width: 8),
                          T(section.label, size: 13.5, weight: FontWeight.w700),
                        ],
                      ),
                      const SizedBox(height: 2),
                      T(section.blurb, color: p.muted, size: 11.5),
                      const SizedBox(height: 12),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: T(
                          shown.isEmpty
                              ? 'No settings match “$q”.'
                              : '${shown.length} setting${shown.length == 1 ? '' : 's'} matching “$q”',
                          color: p.muted,
                          size: 12,
                        ),
                      ),
                    ],

                    for (final e in groups.entries) ...[
                      if (searching)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: SectionLabel(e.key.label.toUpperCase()),
                        ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: _BorderThenFill(
                            border: p.border,
                            fill: p.field.withValues(alpha: 0.5),
                            radius: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var i = 0; i < e.value.length; i++) ...[
                                if (i > 0)
                                  Container(height: 1, color: p.border),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    spacing: 16,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          spacing: 2,
                                          children: [
                                            T(
                                              e.value[i].title,
                                              weight: FontWeight.w600,
                                              size: 12.5,
                                            ),
                                            if (e.value[i].desc
                                                .trim()
                                                .isNotEmpty)
                                              T(
                                                e.value[i].desc,
                                                color:
                                                    e.value[i].descColor ??
                                                    p.muted,
                                                size: 11.5,
                                                mono:
                                                    e.key == _Section.Data &&
                                                    e.value[i].title ==
                                                        'Storage location',
                                              ),
                                          ],
                                        ),
                                      ),
                                      e.value[i].control,
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
