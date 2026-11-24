// ignore_for_file: constant_identifier_names, non_constant_identifier_names, deprecated_member_use
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/components/item_tile.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/theme/icons.dart' show Ic, Ico;
import 'package:rocket_mcp/components/toggle.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/shell/update_dialog.dart';
import 'package:rocket_mcp/utils/app_metadata.dart';
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
    this.icon,
    this.choices,
  });
  final _Section section;
  final String title;
  final String desc;
  final Color? descColor;
  final Widget control;

  /// Badge shown at the start of the card.
  final IconData? icon;

  /// When set, the setting is a heading with these selectable cards beneath it.
  final Widget? choices;
}

/// A selectable card (as in devspace's settings): icon, title, hint, and a check when chosen.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Expanded(
      child: HoverBuilder(
        cursor: SystemMouseCursors.click,
        onTap: onTap,
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? p.accent.withValues(alpha: 0.12)
                : hovered
                ? p.hover
                : p.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? p.accent
                  : hovered
                  ? p.accent.withValues(alpha: 0.4)
                  : p.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Ico(icon, size: 18, tint: selected ? p.accent : p.muted),
                  const Spacer(),
                  if (selected)
                    Ico(Icons.check_circle_rounded, size: 15, tint: p.accent),
                ],
              ),
              const SizedBox(height: 10),
              T(
                title,
                size: 12.5,
                weight: FontWeight.w700,
                color: selected ? p.accent : p.text,
              ),
              const SizedBox(height: 2),
              T(hint, size: 10.5, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tinted rounded-square badge that leads a setting (the same badge the list tiles use).
class _IconBadge extends StatelessWidget {
  const _IconBadge(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Ico(icon, size: 14, tint: p.accent),
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

  Widget _card(Pal p, Widget child, {EdgeInsets? padding}) => Container(
    padding: padding ?? const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: p.field,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: p.border, width: 1),
    ),
    child: child,
  );

  Widget _row(Pal p, _Pref x, _Section section) => Row(
    spacing: 12,
    children: [
      if (x.icon != null) _IconBadge(x.icon!),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            T(x.title, weight: FontWeight.w600, size: 12.5),
            if (x.desc.trim().isNotEmpty)
              T(
                x.desc,
                color: x.descColor ?? p.muted,
                size: 11,
                mono: section == _Section.Data && x.title == 'Storage location',
              ),
          ],
        ),
      ),
      x.control,
    ],
  );

  Widget _choiceBlock(Pal p, _Pref x) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      T(x.title, size: 12.5, weight: FontWeight.w700),
      const SizedBox(height: 4),
      T(x.desc, size: 11.5, color: p.muted),
      const SizedBox(height: 10),
      x.choices!,
      const SizedBox(height: 8),
    ],
  );

  /// The app name and version, with the tour and update actions.
  Widget _about(Pal p) => _card(
    p,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        Row(
          spacing: 10,
          children: [
            Ico(Ic.logo, size: 28, withBg: true),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    children: [
                      const T(
                        AppConfig.NAME,
                        size: 13,
                        weight: FontWeight.w700,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: T(
                          'v${AppMetadata.version}',
                          size: 10,
                          weight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ],
                  ),
                  T(
                    'A desktop client for testing MCP servers.',
                    size: 11,
                    color: p.muted,
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Btn(
              label: 'Welcome Tour…',
              icon: Icons.explore_outlined,
              onClick: () => widget.state.modal = const ModalOnboarding(),
            ),
            Btn(
              label: 'Check for Updates…',
              icon: Icons.update_rounded,
              onClick: () => checkForUpdates(widget.state),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final state = widget.state;
    final s = state.settings;
    void set(AppSettings n) => state.updateSettings(n);

    final prefs = <_Pref>[
      _Pref(
        _Section.Appearance,
        'Theme',
        const SizedBox.shrink(),
        desc: s.theme == ThemeMode.system
            ? "Follows your operating system's light / dark setting (currently ${p.dark ? 'dark' : 'light'})."
            : 'Choose your preferred interface theme.',
        choices: Row(
          spacing: 10,
          children: [
            for (final (mode, icon, hint) in [
              (
                ThemeMode.system,
                Icons.brightness_auto_rounded,
                'Match OS look',
              ),
              (ThemeMode.dark, Icons.dark_mode_rounded, 'Charcoal palette'),
              (ThemeMode.light, Icons.light_mode_rounded, 'Daylight palette'),
            ])
              _ChoiceCard(
                icon: icon,
                title: mode.label,
                hint: hint,
                selected: s.theme == mode,
                onTap: () => set(s.copyWith(theme: mode)),
              ),
          ],
        ),
      ),
      _Pref(
        _Section.General,
        'Save automatically',
        Toggle(
          on: s.autoSave,
          onChange: (v) => set(s.copyWith(autoSave: v)),
        ),
        icon: Icons.save_rounded,
        desc: 'Saves tool parameters and prompt fields just before requests are dispatched.',
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
        icon: Icons.text_fields_rounded,
        desc: 'Scales text and controls (also ⌘+ and ⌘−).',
      ),
      _Pref(
        _Section.Appearance,
        'Workspace layout',
        const SizedBox.shrink(),
        desc: 'Show the response below the request, or beside it.',
        choices: Row(
          spacing: 10,
          children: [
            _ChoiceCard(
              icon: Icons.view_agenda_rounded,
              title: 'Stacked',
              hint: 'Response below the request',
              selected: s.verticalLayout,
              onTap: () => set(s.copyWith(verticalLayout: true)),
            ),
            _ChoiceCard(
              icon: Icons.view_column_rounded,
              title: 'Side by side',
              hint: 'Response beside the request',
              selected: !s.verticalLayout,
              onTap: () => set(s.copyWith(verticalLayout: false)),
            ),
          ],
        ),
      ),
      _Pref(
        _Section.Connections,
        'Auto-connect servers',
        Toggle(
          on: s.autoConnect,
          onChange: (v) => set(s.copyWith(autoConnect: v)),
        ),
        icon: Icons.power_rounded,
        desc: 'Automatically connects the selected server on startup and when switched.',
      ),
      _Pref(
        _Section.Connections,
        'Timeout',
        _NumberField(
          value: s.timeoutMs,
          suffix: 'ms',
          onChange: (v) => set(s.copyWith(timeoutMs: v)),
        ),
        icon: Icons.timer_rounded,
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
        icon: Icons.badge_rounded,
        desc: 'Sent when connecting over HTTP transports. Leave empty for the default.',
      ),
      _Pref(
        _Section.Network,
        'Verify SSL certificates',
        Toggle(
          on: s.sslVerify,
          onChange: (v) => set(s.copyWith(sslVerify: v)),
        ),
        icon: Icons.verified_user_rounded,
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
        icon: Icons.alt_route_rounded,
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
          icon: Icons.dns_rounded,
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
          icon: Icons.settings_ethernet_rounded,
          desc: 'Port the proxy listens on.',
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
        icon: Icons.folder_rounded,
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
        icon: Icons.restart_alt_rounded,
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
      width: 860,
      bodyPadding: EdgeInsets.zero,
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
        constraints: const BoxConstraints(maxHeight: 520),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Side pane, like the app's sidebar: full height, flush with the dialog edge, divided from the content.
            Container(
              width: 188,
              decoration: BoxDecoration(
                color: p.panel,
                border: Border(right: BorderSide(color: p.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Field(
                      value: query,
                      onChange: (v) => setState(() => query = v),
                      placeholder: 'Search…',
                      highlightVars: false,
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final cat in _Section.values)
                            ItemTile(
                              icon: cat.icon,
                              title: cat.label,
                              selected: !searching && section == cat,
                              onClick: () => setState(() {
                                query = '';
                                section = cat;
                              }),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 2. Active Category Content Area
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!searching) ...[
                              Row(
                                children: [
                                  Ico(section.icon, size: 16, tint: p.accent),
                                  const SizedBox(width: 8),
                                  T(
                                    section.label,
                                    size: 13.5,
                                    weight: FontWeight.w700,
                                  ),
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
                                  padding: const EdgeInsets.only(
                                    top: 4,
                                    bottom: 6,
                                  ),
                                  child: SectionLabel(
                                    e.key.label.toUpperCase(),
                                  ),
                                ),
                              if (e.key == _Section.Shortcuts)
                                _card(
                                  p,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < e.value.length;
                                        i++
                                      ) ...[
                                        if (i > 0)
                                          Container(height: 1, color: p.border),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 9,
                                          ),
                                          child: Row(
                                            spacing: 16,
                                            children: [
                                              Expanded(
                                                child: T(
                                                  e.value[i].title,
                                                  weight: FontWeight.w600,
                                                  size: 12.5,
                                                ),
                                              ),
                                              e.value[i].control,
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  padding: EdgeInsets.zero,
                                )
                              else
                                for (final x in e.value) ...[
                                  if (x.choices != null)
                                    _choiceBlock(p, x)
                                  else
                                    _card(p, _row(p, x, e.key)),
                                  const SizedBox(height: 10),
                                ],
                              if (e.key == _Section.General && !searching)
                                _about(p),
                              const SizedBox(height: 8),
                            ],
                          ],
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
    );
  }
}
