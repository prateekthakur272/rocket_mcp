import 'package:rocket_mcp/core/mcp/model.dart';

/// The dialog currently shown; one `Modal<Name>` subclass per dialog. `Modals` (features/shell/modals.dart) maps every
/// case to its widget with an exhaustive `switch`, so the compiler reports a dialog that has no widget.
sealed class Modal {
  const Modal();
}

/// The command palette.
class ModalPalette extends Modal {
  const ModalPalette();
}

/// Preferences.
class ModalSettings extends Modal {
  const ModalSettings();
}

/// Application information.
class ModalAbout extends Modal {
  const ModalAbout();
}

/// Author and project links.
class ModalDeveloper extends Modal {
  const ModalDeveloper();
}

/// A newer release exists.
class ModalUpdateAvailable extends Modal {
  const ModalUpdateAvailable({required this.version});
  final String version;
}

/// Add or edit an MCP Server configuration.
class ModalServerConfig extends Modal {
  const ModalServerConfig({this.server});
  final McpServerConfig? server;
}

/// Import or export MCP servers (Claude Desktop & Rocket MCP format).
class ModalImportExport extends Modal {
  const ModalImportExport();
}

/// Server Template Gallery catalog modal.
class ModalTemplateGallery extends Modal {
  const ModalTemplateGallery();
}

/// First-time onboarding walkthrough tour.
class ModalOnboarding extends Modal {
  const ModalOnboarding();
}
