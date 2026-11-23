import 'package:flutter/widgets.dart';

/// Which menu of the in-window menu bar is open, and where things are on screen (so a click elsewhere can close it).
class TitleMenuState extends ChangeNotifier {
  String? _open;
  String? get open => _open;
  set open(String? value) {
    if (_open == value) return;
    _open = value;
    notifyListeners();
  }

  /// Bounds of each menu title, by label.
  final Map<String, Rect> anchors = {};

  /// Bounds of the open menu's panel.
  Rect? panel;

  void close() => open = null;
}
