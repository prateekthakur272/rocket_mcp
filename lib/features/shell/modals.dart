import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/features/developer/developer_dialog.dart';
import 'package:rocket_mcp/features/preferences/preferences.dart';
import 'package:rocket_mcp/features/shell/about_dialog.dart';
import 'package:rocket_mcp/features/shell/palette.dart';
import 'package:rocket_mcp/features/shell/update_dialog.dart';

/// Shows whichever modal dialog is currently open.
class Modals extends StatelessWidget {
  const Modals({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final modal = state.modal;
    if (modal == null) return const SizedBox.shrink();
    return Positioned.fill(child: _dialog(modal));
  }

  Widget _dialog(Modal modal) => switch (modal) {
    ModalPalette() => Palette(state: state),
    ModalSettings() => PreferencesDialog(state: state),
    ModalAbout() => AboutDialog(state: state),
    ModalDeveloper() => DeveloperDialog(state: state),
    ModalUpdateAvailable() => UpdateAvailableDialog(
      state: state,
      version: modal.version,
    ),
  };
}
