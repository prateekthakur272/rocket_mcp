// ignore_for_file: constant_identifier_names, non_constant_identifier_names, deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/components/segmented.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/theme.dart';

enum _Section {
  General('General', 'How ${AppConfig.NAME} behaves day to day.'),
  Appearance('Appearance', 'Theme, size and layout.'),
  Connections('Connections', 'Defaults applied to every server connection.'),
  Network('Network', 'Certificates and proxy.'),
  Shortcuts(
    'Shortcuts',
    'Keyboard shortcuts. Use Ctrl instead of ⌘ on Windows and Linux.',
  ),
  Data('Data', 'Where ${AppConfig.NAME} keeps your files.');

  const _Section(this.label, this.blurb);
  final String label;
  final String blurb;
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

class _Toggle extends StatelessWidget {
  const _Toggle({required this.on, required this.onChange});
  final bool on;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Clickable(
      onClick: () => onChange(!on),
      cursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        width: 38,
        height: 22,
        padding: const EdgeInsets.all(3),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? p.accent : p.border,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFFFFFFF),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.selected,
    required this.onClick,
  });
  final String label;
  final bool selected;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      indicate: true,
      borderRadius: BorderRadius.circular(7),
      cursor: SystemMouseCursors.click,
      onTap: onClick,
      builder: (ctx, hov) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? p.accent.withValues(alpha: 0.16)
              : (hov ? p.hover : const Color(0x00000000)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: T(
          label,
          color: selected ? p.accent : p.text,
          weight: selected ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}

/// App-level preferences: sections on the left, settings with a line of explanation each on the right, and a search across all of them.
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
        _Toggle(
          on: s.autoSave,
          onChange: (v) => set(s.copyWith(autoSave: v)),
        ),
        desc: 'Saves a request just before it is sent.',
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
        _Toggle(
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
        _Toggle(
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
      for (final (what, keys) in const <(String, String)>[
        ('Command palette', '⌘K'),
        ('Show / hide sidebar', '⌘B'),
        ('Switch workspace layout', '⌘⇧L'),
        ('Zoom in / out / reset', '⌘+  ⌘−  ⌘0'),
        ('Preferences', '⌘,'),
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
        desc: 'Restore every setting to its default. Your collections and environments are not touched.',
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

    return ModalBox(
      title: 'Preferences',
      onClose: () => state.modal = null,
      width: 900,
      height: 620,
      actions: [
        Expanded(
          child: T(
            'Changes are saved as you make them.',
            color: p.muted,
            size: 12,
          ),
        ),
        Btn(label: 'Done', onClick: () => state.modal = null, primary: true),
      ],
      content: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              SizedBox(
                width: 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    Field(
                      value: query,
                      onChange: (v) => setState(() => query = v),
                      placeholder: 'Search settings',
                      highlightVars: false,
                    ),
                    const SizedBox(height: 6),
                    for (final sec in _Section.values)
                      _NavItem(
                        label: sec.label,
                        selected: !searching && sec == section,
                        onClick: () => setState(() {
                          query = '';
                          section = sec;
                        }),
                      ),
                  ],
                ),
              ),
              Container(width: 1, color: p.border),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 14,
                    children: [
                      if (!searching)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 2,
                          children: [
                            T(section.label, size: 18, weight: FontWeight.w700),
                            T(section.blurb, color: p.muted, size: 12),
                          ],
                        )
                      else
                        T(
                          shown.isEmpty
                              ? 'No settings match “$q”.'
                              : '${shown.length} setting${shown.length == 1 ? '' : 's'} matching “$q”',
                          color: p.muted,
                          size: 13,
                        ),
                      for (final e in groups.entries) ...[
                        if (searching) SectionLabel(e.key.label.toUpperCase()),
                        // The fill paints over the 1px border, which therefore stays visible.
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
                                              ),
                                              if (e.value[i].desc
                                                  .trim()
                                                  .isNotEmpty)
                                                T(
                                                  e.value[i].desc,
                                                  color:
                                                      e.value[i].descColor ??
                                                      p.muted,
                                                  size: 12,
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
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
