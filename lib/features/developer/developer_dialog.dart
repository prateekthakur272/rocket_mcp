import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/utils/app_metadata.dart';
import 'package:rocket_mcp/utils/issue_report.dart';

const _gold = Color(0xFFE3B341);
const _pink = Color(0xFFF778BA);
const _sky = Color(0xFF54C5F8);

/// Developer and GitHub dialog: author identity, quick actions, and the project's GitHub links.
class DeveloperDialog extends StatelessWidget {
  const DeveloperDialog({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ModalBox(
      title: 'Developer',
      onClose: () => state.modal = null,
      width: 620,
      actions: [
        Btn(label: 'Close', onClick: () => state.modal = null, primary: true),
      ],
      content: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            _Hero(),
            Row(
              spacing: 6,
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Ic.code,
                    color: p.accent,
                    title: 'Source Code',
                    subtitle: 'Browse repository & code',
                    onClick: () => Platform.openUrl(AppConfig.HOMEPAGE),
                  ),
                ),
                Expanded(
                  child: _ActionTile(
                    icon: Ic.star,
                    color: _gold,
                    title: 'Star on GitHub',
                    subtitle: 'Bookmark & show support',
                    onClick: () => Platform.openUrl(AppConfig.HOMEPAGE),
                  ),
                ),
              ],
            ),
            Row(
              spacing: 6,
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Ic.download,
                    color: p.ok,
                    title: 'Releases & Notes',
                    subtitle: 'Latest binaries & changelog',
                    onClick: () => Platform.openUrl(AppConfig.RELEASES_URL),
                  ),
                ),
                Expanded(
                  child: _ActionTile(
                    icon: Ic.bug,
                    color: p.warn,
                    title: 'Report an Issue',
                    subtitle: 'Bugs, ideas & suggestions',
                    onClick: () =>
                        Platform.openUrl(IssueReport.url().toString()),
                  ),
                ),
              ],
            ),
            if (AppConfig.MORE_APPS_URL.trim().isNotEmpty)
              _LinkCard(
                label: 'Explore more apps',
                icon: Ic.apps,
                url: AppConfig.MORE_APPS_URL,
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: p.panel,
                borderRadius: BorderRadius.circular(6),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.border, width: 1),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Ico(Ic.favorite, tint: _pink, size: 14),
                  Expanded(
                    child: T(
                      '${AppConfig.NAME} is built in the open. Bug reports, ideas and pull requests are welcome on GitHub.',
                      color: p.muted,
                      size: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Author avatar, name, profile chip and metadata badges.
class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.field,
        borderRadius: BorderRadius.circular(8),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border, width: 1),
      ),
      child: Row(
        spacing: 14,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.panel,
                  border: Border.all(color: p.border, width: 1.5),
                ),
                child: Ico(Ic.gitHub, tint: p.text, size: 34),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: p.ok,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.panel, width: 2),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    T(AppConfig.VENDOR, size: 18, weight: FontWeight.w700),
                    HoverBuilder(
                      cursor: SystemMouseCursors.click,
                      onTap: () => Platform.openUrl(AppConfig.DEVELOPER_URL),
                      builder: (context, hovered) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.accent.withValues(
                            alpha: hovered ? 0.2 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        foregroundDecoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: hovered
                                ? p.accent
                                : p.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 4,
                          children: [
                            Ico(Ic.gitHub, tint: p.accent, size: 11),
                            _Tiny(
                              '@prateekthakur272',
                              size: 10.5,
                              color: p.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                T('Developer of ${AppConfig.NAME}', size: 12, color: p.muted),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Badge(label: 'Public Repo', color: p.ok, dot: true),
                    _Badge(label: 'v${AppMetadata.version}', color: p.accent),
                    const _Badge(label: 'Flutter Desktop', color: _sky),
                    _Badge(label: 'Open Source', color: p.muted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.dot = false});
  final String label;
  final Color color;
  final bool dot;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        if (dot)
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        _Tiny(label, size: 10, color: color),
      ],
    ),
  );
}

/// Quick action tile with icon, title, subtitle and hover effect.
class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onClick,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onClick;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      cursor: SystemMouseCursors.click,
      onTap: onClick,
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hovered ? p.hover : p.field,
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hovered ? color.withValues(alpha: 0.6) : p.border,
            width: 1,
          ),
        ),
        child: Row(
          spacing: 10,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: hovered ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Ico(icon, tint: color, size: 16),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Row(
                    spacing: 4,
                    children: [
                      _Tiny(title, size: 12.5, color: p.text),
                      Ico(
                        Ic.arrowOut,
                        tint: hovered ? color : p.muted,
                        size: 11,
                      ),
                    ],
                  ),
                  _Tiny(
                    subtitle,
                    size: 10.5,
                    color: p.muted,
                    weight: FontWeight.w400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labelled URL with Copy and Open buttons.
class _LinkCard extends StatefulWidget {
  const _LinkCard({required this.label, required this.icon, required this.url});
  final String label;
  final IconData icon;
  final String url;

  @override
  State<_LinkCard> createState() => _LinkCardState();
}

class _LinkCardState extends State<_LinkCard> {
  bool _copied = false;
  Timer? _reset;

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  void _copy() {
    Platform.copy(widget.url);
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return HoverBuilder(
      builder: (context, hovered) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: p.field,
          borderRadius: BorderRadius.circular(8),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hovered ? p.accent.withValues(alpha: 0.4) : p.border,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Row(
              spacing: 5,
              children: [
                Ico(widget.icon, tint: p.muted, size: 12),
                T(
                  widget.label.toUpperCase(),
                  color: p.muted,
                  size: 10.5,
                  weight: FontWeight.w600,
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.only(
                left: 10,
                top: 4,
                bottom: 4,
                right: 4,
              ),
              decoration: BoxDecoration(
                color: p.panel,
                borderRadius: BorderRadius.circular(6),
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.border, width: 1),
              ),
              child: Row(
                spacing: 6,
                children: [
                  Expanded(child: T(widget.url, mono: true, size: 10.5)),
                  Tooltip(
                    message: _copied ? 'Copied' : 'Copy link',
                    child: IconBtn(
                      icon: _copied ? Ic.check : Ic.copy,
                      color: _copied ? p.ok : p.muted,
                      size: 15,
                      onClick: _copy,
                    ),
                  ),
                  Tooltip(
                    message: 'Open in browser',
                    child: IconBtn(
                      icon: Ic.open,
                      color: p.accent,
                      size: 15,
                      onClick: () => Platform.openUrl(widget.url),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact single-line label for chips: unlike [T] it has no fixed 24sp line box, so chips stay short.
class _Tiny extends StatelessWidget {
  const _Tiny(
    this.text, {
    required this.size,
    required this.color,
    this.weight = FontWeight.w600,
  });
  final String text;
  final double size;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: color,
      fontSize: size,
      height: 1.2,
      letterSpacing: 0.3,
      fontWeight: weight,
      decoration: TextDecoration.none,
    ),
  );
}
