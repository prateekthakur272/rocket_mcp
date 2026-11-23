import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/issue_report.dart';

/// The bar at the bottom of the window: view toggles and shortcuts to Preferences, updates, the developer dialog and
/// issue reporting on the left; connection status and the command-palette hint on the right.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.state});
  final AppState state;

  static const double height = 24;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final update = state.availableUpdate;
    final paletteKey = Platform.isMac ? '⌘K' : 'Ctrl K';
    return Container(
      height: height,
      color: p.panel,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      // The 1px line is painted over the bar so it takes no layout space.
      foregroundDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: Row(
        spacing: 14,
        children: [
          Row(
            spacing: 2,
            children: [
              IconBtn(
                icon: Ic.sidebar,
                onClick: () => state.sidebarVisible = !state.sidebarVisible,
                color: state.sidebarVisible ? p.accent : p.muted,
                size: 15,
              ),
              IconBtn(
                icon: Ic.settings,
                onClick: () => state.modal = const ModalSettings(),
                color: p.muted,
                size: 15,
              ),
              if (update != null)
                Tooltip(
                  message: 'Update available: $update  —  click to download',
                  child: IconBtn(
                    icon: Ic.download,
                    onClick: () =>
                        state.modal = ModalUpdateAvailable(version: update),
                    color: p.accent,
                    size: 15,
                  ),
                ),
              IconBtn(
                icon: Ic.gitHub,
                onClick: () => state.modal = const ModalDeveloper(),
                color: p.muted,
                size: 15,
              ),
              Tooltip(
                message: 'Report an issue',
                child: IconBtn(
                  key: const ValueKey('report-issue'),
                  icon: Ic.bug,
                  onClick: () => Platform.openUrl(IssueReport.url().toString()),
                  color: p.muted,
                  size: 15,
                ),
              ),
            ],
          ),
          _ConnectionStatus(session: state.activeSession),
          const Spacer(),
          Clickable(
            onClick: () => state.modal = const ModalPalette(),
            cursor: SystemMouseCursors.click,
            child: Row(
              spacing: 4,
              children: [
                T(paletteKey, size: 11, color: p.accent, mono: true),
                T('commands', size: 11, color: p.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The active server's connection state at the left of the status bar: a coloured dot, the server's name and its state.
class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({required this.session});
  final McpSession? session;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final active = session;
    if (active == null) {
      return T('no server selected', size: 11, color: p.muted);
    }
    // The session notifies on its own, so the bar follows connects and disconnects without waiting for app state.
    return ListenableBuilder(
      listenable: active,
      builder: (context, _) {
        final status = active.status;
        final color = switch (status) {
          McpServerStatus.connected => p.ok,
          McpServerStatus.connecting => p.accent,
          McpServerStatus.error => p.err,
          McpServerStatus.disconnected => p.muted,
        };
        return Row(
          spacing: 6,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            T(
              '${active.config.name} · ${status.label.toLowerCase()}',
              size: 11,
              color: status == McpServerStatus.connected ? p.text : p.muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
    );
  }
}
