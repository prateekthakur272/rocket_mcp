import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/components/toggle.dart';
import 'package:rocket_mcp/core/model/app_settings.dart' show ThemeMode;
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';

class OnboardingDialog extends StatefulWidget {
  const OnboardingDialog({super.key, required this.state});
  final AppState state;

  @override
  State<OnboardingDialog> createState() => _OnboardingDialogState();
}

class _OnboardingDialogState extends State<OnboardingDialog> {
  int _currentStep = 0;
  static const int _totalSteps = 3;

  void _finish() {
    AppStore.setFlag('onboarding_completed', true);
    widget.state.modal = null;
  }

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;

    return ModalScaffold(
      title: switch (_currentStep) {
        0 => 'Welcome to ${AppConfig.NAME}',
        1 => 'Customize Workspace',
        _ => 'Get Started with MCP Servers',
      },
      width: 620,
      onClose: _finish,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step contents with animated transition
          Flexible(
            child: SingleChildScrollView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: KeyedSubtree(
                  key: ValueKey(_currentStep),
                  child: switch (_currentStep) {
                    0 => _buildWelcomeStep(p),
                    1 => _buildCustomizeStep(p),
                    _ => _buildGetStartedStep(p),
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stepper Navigation Footer
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: p.border.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Btn(label: 'Skip', onClick: _finish, height: 32, fontSize: 12),
                const Spacer(),
                // Step Indicator Dots
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _totalSteps; i++) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _currentStep == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentStep == i ? p.accent : p.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      if (i < _totalSteps - 1) const SizedBox(width: 5),
                    ],
                  ],
                ),
                const Spacer(),
                if (_currentStep > 0) ...[
                  Btn(label: 'Back', onClick: _prev, height: 32, fontSize: 12),
                  const SizedBox(width: 8),
                ],
                Btn(
                  label: _currentStep == _totalSteps - 1
                      ? 'Get Started'
                      : 'Continue',
                  primary: true,
                  icon: _currentStep == _totalSteps - 1
                      ? Icons.rocket_launch_rounded
                      : Icons.arrow_forward_rounded,
                  onClick: _next,
                  height: 32,
                  fontSize: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Welcome & Mission
  // ---------------------------------------------------------------------------
  Widget _buildWelcomeStep(Pal p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Hero branding card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [p.accent.withValues(alpha: 0.14), p.panel],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: p.accent.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/app_icon_nobg.png',
                width: 44,
                height: 44,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Ic.logo, size: 28, color: p.accent),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const T(
                      'Welcome to ${AppConfig.NAME}',
                      size: 16,
                      weight: FontWeight.w700,
                    ),
                    const SizedBox(height: 3),
                    T(
                      'The high-performance desktop workbench & testing lab for Model Context Protocol (MCP) servers.',
                      size: 12,
                      color: p.muted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // 3 Key pillars
        _buildFeatureItem(
          p: p,
          icon: Icons.hub_rounded,
          iconColor: p.accent,
          title: 'Connect & Manage MCP Servers',
          description: 'Seamlessly launch stdio CLI server processes or connect to remote SSE and HTTP endpoints with auto-reconnect and health checks.',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          p: p,
          icon: Icons.tune_rounded,
          iconColor: p.warn,
          title: 'Explore Tools, Prompts & Resources',
          description: 'Inspect dynamic capabilities, run parameterized tool calls with live JSON validation, evaluate prompt templates, and fetch URI resources.',
        ),
        const SizedBox(height: 8),
        _buildFeatureItem(
          p: p,
          icon: Icons.query_stats_rounded,
          iconColor: p.ok,
          title: 'Real-Time Traffic & Log Inspector',
          description: 'Full JSON-RPC telemetry stream with millisecond latency breakdowns, filtering, search, error highlighting, and structured diffing.',
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required Pal p,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                T(title, size: 12.5, weight: FontWeight.w600),
                const SizedBox(height: 2),
                T(description, size: 11, color: p.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Customize Workspace
  // ---------------------------------------------------------------------------
  Widget _buildCustomizeStep(Pal p) {
    final settings = widget.state.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const T('Appearance & Theme', size: 13, weight: FontWeight.w600),
        const SizedBox(height: 4),
        T(
          'Select your preferred interface theme. You can change this anytime from preferences.',
          size: 11,
          color: p.muted,
        ),
        const SizedBox(height: 10),

        // Theme selector cards
        Row(
          children: [
            _buildThemeOption(
              p: p,
              title: 'System',
              subtitle: 'Follows OS look',
              icon: Icons.brightness_auto_rounded,
              mode: ThemeMode.system,
              selected: settings.theme == ThemeMode.system,
            ),
            const SizedBox(width: 8),
            _buildThemeOption(
              p: p,
              title: 'Dark',
              subtitle: 'Charcoal palette',
              icon: Icons.dark_mode_rounded,
              mode: ThemeMode.dark,
              selected: settings.theme == ThemeMode.dark,
            ),
            const SizedBox(width: 8),
            _buildThemeOption(
              p: p,
              title: 'Light',
              subtitle: 'Crisp bright palette',
              icon: Icons.light_mode_rounded,
              mode: ThemeMode.light,
              selected: settings.theme == ThemeMode.light,
            ),
          ],
        ),

        const SizedBox(height: 16),

        const T('Workspace Layout & Sizing', size: 13, weight: FontWeight.w600),
        const SizedBox(height: 4),
        T(
          'Configure how request forms and live responses are positioned.',
          size: 11,
          color: p.muted,
        ),
        const SizedBox(height: 10),

        // Layout preference cards
        Row(
          children: [
            _buildLayoutOption(
              p: p,
              title: 'Stacked Layout',
              subtitle: 'Response below request',
              icon: Icons.vertical_split_rounded,
              isVertical: true,
              selected: settings.verticalLayout,
            ),
            const SizedBox(width: 8),
            _buildLayoutOption(
              p: p,
              title: 'Side by Side',
              subtitle: 'Response beside request',
              icon: Icons.horizontal_split_rounded,
              isVertical: false,
              selected: !settings.verticalLayout,
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Auto-save toggle card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: p.field,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: p.border.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.save_rounded, size: 16, color: p.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const T(
                      'Auto-Save Requests',
                      size: 12.5,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    T(
                      'Automatically preserves tool parameters and prompt inputs before dispatching.',
                      size: 11,
                      color: p.muted,
                    ),
                  ],
                ),
              ),
              Toggle(
                on: settings.autoSave,
                onChange: (val) {
                  widget.state.updateSettings(settings.copyWith(autoSave: val));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required Pal p,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required bool selected,
  }) {
    return Expanded(
      child: HoverBuilder(
        cursor: SystemMouseCursors.click,
        onTap: () {
          widget.state.updateSettings(
            widget.state.settings.copyWith(theme: mode),
          );
        },
        builder: (context, hovered) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    ? p.border
                    : p.border.withValues(alpha: 0.6),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: selected ? p.accent : p.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      T(
                        title,
                        size: 12,
                        weight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? p.accent : p.text,
                      ),
                      T(subtitle, size: 10, color: p.muted),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLayoutOption({
    required Pal p,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isVertical,
    required bool selected,
  }) {
    return Expanded(
      child: HoverBuilder(
        cursor: SystemMouseCursors.click,
        onTap: () {
          widget.state.updateSettings(
            widget.state.settings.copyWith(verticalLayout: isVertical),
          );
        },
        builder: (context, hovered) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    ? p.border
                    : p.border.withValues(alpha: 0.6),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: selected ? p.accent : p.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      T(
                        title,
                        size: 12,
                        weight: selected ? FontWeight.w700 : FontWeight.w600,
                        color: selected ? p.accent : p.text,
                      ),
                      T(subtitle, size: 10, color: p.muted),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Get Started
  // ---------------------------------------------------------------------------
  Widget _buildGetStartedStep(Pal p) {
    final mod = Platform.isMac ? '⌘' : 'Ctrl+';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const T('Connect Your First Server', size: 13, weight: FontWeight.w600),
        const SizedBox(height: 4),
        T(
          'Add an MCP server via stdio command, Server-Sent Events (SSE), or import existing profiles.',
          size: 11,
          color: p.muted,
        ),
        const SizedBox(height: 12),

        // Action card: Add Server
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: p.accent.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 22,
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const T(
                      'New MCP Server Connection',
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    T(
                      'Configure a local CLI binary (node, python, uvx, npx) or remote streaming HTTP/SSE URL.',
                      size: 11,
                      color: p.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Btn(
                label: 'Add Server…',
                primary: true,
                icon: Icons.add_rounded,
                height: 32,
                fontSize: 12,
                onClick: () {
                  _finish();
                  widget.state.modal = const ModalServerConfig();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Action card: Import Configuration
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: p.border.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.warn.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.input_rounded, size: 22, color: p.warn),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const T(
                      'Import Claude Desktop & MCP Configs',
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                    const SizedBox(height: 2),
                    T(
                      'Instantly migrate your servers from claude_desktop_config.json or Rocket MCP backups.',
                      size: 11,
                      color: p.muted,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Btn(
                label: 'Import Config…',
                outlined: true,
                height: 32,
                fontSize: 12,
                onClick: () {
                  _finish();
                  widget.state.modal = const ModalImportExport();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Shortcuts summary badge bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.panel,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: p.border.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.keyboard_outlined, size: 14, color: p.muted),
              const SizedBox(width: 8),
              Expanded(
                child: T(
                  'Quick Keys:  $mod'
                  'K Palette  •  $mod'
                  'N New Server  •  $mod'
                  'R Connect  •  $mod'
                  '1 Tools  •  $mod'
                  '4 Inspector  •  $mod, Preferences',
                  size: 10.5,
                  color: p.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
