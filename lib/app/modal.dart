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
