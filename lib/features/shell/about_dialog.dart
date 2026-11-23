import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/utils/app_metadata.dart';

/// Name, version, credits and where the app keeps its data.
class AboutDialog extends StatelessWidget {
  const AboutDialog({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ModalBox(
      title: 'About ${AppConfig.NAME}',
      onClose: () => state.modal = null,
      width: 440,
      actions: [
        Btn(label: 'Close', onClick: () => state.modal = null, primary: true),
      ],
      content: [
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              spacing: 6,
              children: [
                Ico(Ic.logo, tint: p.accent, size: 56),
                const T(AppConfig.NAME, size: 22, weight: FontWeight.w700),
                T('Version ${AppMetadata.version}', color: p.muted, size: 12),
                T('by ${AppConfig.VENDOR}', color: p.muted, size: 12),
                const SizedBox(height: 6),
                DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  child: T(AppConfig.TAGLINE, color: p.muted, size: 12),
                ),
                const SizedBox(height: 6),
                T(
                  'Your data stays on this computer, in ${AppStore.dir}',
                  color: p.muted,
                  size: 11,
                  mono: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
