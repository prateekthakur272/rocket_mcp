import 'package:flutter/services.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';

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
  if (key == LogicalKeyboardKey.escape && closeTitleMenu(state)) return true;
  final keyboard = HardwareKeyboard.instance;
  final primary = keyboard.isMetaPressed || keyboard.isControlPressed;
  if (!primary) return false;
  final shift = keyboard.isShiftPressed;

  if (key == LogicalKeyboardKey.keyK || key == LogicalKeyboardKey.keyP) {
    state.togglePalette();
    return true;
  }
  if (key == LogicalKeyboardKey.keyN) {
    state.modal = const ModalServerConfig();
    return true;
  }
  if (key == LogicalKeyboardKey.keyR && !shift) {
    state.activeSession?.connect();
    return true;
  }
  if (key == LogicalKeyboardKey.keyB) {
    state.sidebarVisible = !state.sidebarVisible;
    return true;
  }
  if (key == LogicalKeyboardKey.keyL && shift) {
    state.toggleLayout();
    return true;
  }
  if (key == LogicalKeyboardKey.comma) {
    state.modal = const ModalSettings();
    return true;
  }
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
  return false;
}
