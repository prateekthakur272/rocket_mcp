import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/layout.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/platform/platform.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';
import 'package:rocket_mcp/utils/app_metadata.dart';
import 'package:rocket_mcp/utils/update_checker.dart';

/// Checks for a newer release on request (Help menu, command palette) and tells the user the outcome either way.
void checkForUpdates(AppState state) => unawaited(_checkForUpdates(state));

Future<void> _checkForUpdates(AppState state) async {
  // A manual check ignores an earlier "Later" so it always reports what is out there.
  await UpdateChecker.clearDismissed();
  final result = await UpdateChecker.check(AppMetadata.version);
  if (result.failed) {
    // Not "up to date": the check did not run, so the status-bar icon stays as it is.
    state.showToast("Couldn't check for updates: ${result.error}");
  } else if (result.hasUpdate) {
    state.availableUpdate = result.version;
    state.modal = ModalUpdateAvailable(version: result.version!);
  } else {
    state.availableUpdate = null;
    state.showToast('${AppConfig.NAME} is up to date (${AppMetadata.version})');
  }
}

/// The automatic check at startup. The status-bar icon always appears for a newer release; the dialog only when the
/// user has not dismissed that version and nothing else is showing.
Future<void> checkForUpdateAtStartup(AppState state) async {
  final result = await UpdateChecker.check(AppMetadata.version);
  if (!result.hasUpdate) return;
  state.availableUpdate = result.version;
  if (result.shouldShowDialog && state.modal == null) {
    state.modal = ModalUpdateAvailable(version: result.version!);
  }
}

/// Shown when a newer release is detected.
class UpdateAvailableDialog extends StatelessWidget {
  const UpdateAvailableDialog({
    super.key,
    required this.state,
    required this.version,
  });

  final AppState state;
  final String version;

  void _later() {
    state.modal = null;
    unawaited(UpdateChecker.dismissVersion(version));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ModalBox(
      title: 'Update Available',
      onClose: _later,
      width: 420,
      actions: [
        Btn(label: 'Later', onClick: _later),
        Btn(
          label: 'Download $version',
          primary: true,
          onClick: () {
            state.modal = null;
            state.availableUpdate = null;
            unawaited(Platform.openUrl(AppConfig.RELEASES_URL));
          },
        ),
      ],
      content: [
        Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Ico(Ic.logo, tint: p.accent, size: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  T(
                    'Version $version is now available',
                    weight: FontWeight.w600,
                  ),
                  T(
                    'You are running ${AppMetadata.version}. '
                    'Visit the GitHub releases page to download the latest build.',
                    color: p.muted,
                    size: 12,
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
