import 'package:flutter/services.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/platform/platform.dart';

/// Esc closes an open title-bar menu; returns false (leaving Esc to others) when none is open.
bool closeTitleMenu(AppState state) {
  if (state.titleMenu.open == null) return false;
  state.titleMenu.close();
  return true;
}

/// The window-wide keyboard shortcuts. Call it for key events before the focused widget sees them.
/// Keep it in step with the shortcuts listed in `AppMenus` and in the Preferences "Shortcuts" page.
bool handleKey(AppState state, KeyEvent event) {
  if (event is KeyUpEvent) return false;
  final key = event.logicalKey;

  // Esc closes open menus or active modal
  if (key == LogicalKeyboardKey.escape) {
    if (closeTitleMenu(state)) return true;
    if (state.modal != null) {
      state.modal = null;
      return true;
    }
    return false;
  }

  // F1 opens Keyboard Shortcuts / Help on Windows and Linux
  if (key == LogicalKeyboardKey.f1) {
    state.prefsSection = 'Shortcuts';
    state.modal = const ModalSettings();
    return true;
  }

  final keyboard = HardwareKeyboard.instance;
  final primary = keyboard.isMetaPressed || keyboard.isControlPressed;
  final shift = keyboard.isShiftPressed;
  final ctrl = keyboard.isControlPressed;

  // Next / Previous tab: Ctrl+Tab and Ctrl+Shift+Tab
  if (ctrl && key == LogicalKeyboardKey.tab) {
    final s = state.activeSession;
    if (s != null) {
      final tabs = WorkspaceTab.values;
      final offset = shift ? -1 : 1;
      final nextIdx =
          (tabs.indexOf(s.activeTab) + offset + tabs.length) % tabs.length;
      s.activeTab = tabs[nextIdx];
      return true;
    }
  }

  // Next / Previous tab: Cmd+[ and Cmd+] / Ctrl+[ and Ctrl+]
  if (primary &&
      (key == LogicalKeyboardKey.bracketLeft ||
          key == LogicalKeyboardKey.bracketRight)) {
    final s = state.activeSession;
    if (s != null) {
      final tabs = WorkspaceTab.values;
      final offset = key == LogicalKeyboardKey.bracketLeft ? -1 : 1;
      final nextIdx =
          (tabs.indexOf(s.activeTab) + offset + tabs.length) % tabs.length;
      s.activeTab = tabs[nextIdx];
      return true;
    }
  }

  if (!primary) return false;

  // Keyboard Shortcuts: Cmd+/ on Mac
  if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.question) {
    state.prefsSection = 'Shortcuts';
    state.modal = const ModalSettings();
    return true;
  }

  // Close active modal: Cmd/Ctrl + W
  if (key == LogicalKeyboardKey.keyW && state.modal != null) {
    state.modal = null;
    return true;
  }

  // Command palette: Cmd/Ctrl + K or P
  if ((key == LogicalKeyboardKey.keyK || key == LogicalKeyboardKey.keyP) &&
      !shift) {
    state.togglePalette();
    return true;
  }

  // New server: Cmd/Ctrl + N
  if (key == LogicalKeyboardKey.keyN && !shift) {
    state.modal = const ModalServerConfig();
    return true;
  }

  // Import / Export: Cmd/Ctrl + Shift + I
  if (key == LogicalKeyboardKey.keyI && shift) {
    state.modal = const ModalImportExport();
    return true;
  }

  // Open data folder: Cmd/Ctrl + Shift + O
  if (key == LogicalKeyboardKey.keyO && shift) {
    Platform.reveal(AppStore.dir);
    return true;
  }

  // Connect / Reconnect: Cmd/Ctrl + R
  if (key == LogicalKeyboardKey.keyR && !shift) {
    state.activeSession?.connect();
    return true;
  }

  // Refresh capabilities: Cmd/Ctrl + Shift + R
  if (key == LogicalKeyboardKey.keyR && shift) {
    state.activeSession?.discover();
    return true;
  }

  // Disconnect: Cmd/Ctrl + Shift + D
  if (key == LogicalKeyboardKey.keyD && shift) {
    state.activeSession?.disconnect();
    return true;
  }

  // Ping: Cmd/Ctrl + Shift + P
  if (key == LogicalKeyboardKey.keyP && shift) {
    state.activeSession?.ping(feedback: true);
    return true;
  }

  // Sidebar toggle: Cmd/Ctrl + B
  if (key == LogicalKeyboardKey.keyB && !shift) {
    state.sidebarVisible = !state.sidebarVisible;
    return true;
  }

  // Layout switch: Cmd/Ctrl + Shift + L
  if (key == LogicalKeyboardKey.keyL && shift) {
    state.toggleLayout();
    return true;
  }

  // Settings: Cmd/Ctrl + ,
  if (key == LogicalKeyboardKey.comma) {
    state.modal = const ModalSettings();
    return true;
  }

  // Zoom controls
  if (key == LogicalKeyboardKey.equal ||
      key == LogicalKeyboardKey.add ||
      key == LogicalKeyboardKey.numpadAdd) {
    state.zoom(1);
    return true;
  }
  if (key == LogicalKeyboardKey.minus ||
      key == LogicalKeyboardKey.numpadSubtract) {
    state.zoom(-1);
    return true;
  }
  if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
    state.zoom(0);
    return true;
  }

  // Direct tab switching: Cmd/Ctrl + 1..6
  if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
    state.activeSession?.activeTab = WorkspaceTab.tools;
    return true;
  }
  if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
    state.activeSession?.activeTab = WorkspaceTab.resources;
    return true;
  }
  if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
    state.activeSession?.activeTab = WorkspaceTab.prompts;
    return true;
  }
  if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
    state.activeSession?.activeTab = WorkspaceTab.inspector;
    return true;
  }
  if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
    state.activeSession?.activeTab = WorkspaceTab.logs;
    return true;
  }
  if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
    state.activeSession?.activeTab = WorkspaceTab.raw;
    return true;
  }

  return false;
}
