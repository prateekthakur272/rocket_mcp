import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/app/title_menu_state.dart';
import 'package:rocket_mcp/core/model/app_settings.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';

/// The single owner of application state: settings, the dialog that is showing, layout and update status. Widgets reach
/// it through [AppScope]; behaviour that grows beyond state goes into extensions in `app_state_*.dart` files.
class AppState extends ChangeNotifier {
  AppState() {
    titleMenu.addListener(notifyListeners);
    settings = AppStore.loadSettings();
    final layout = AppStore.loadLayout();
    _sidebarWidth = layout.sidebarWidth.clamp(minSidebarWidth, maxSidebarWidth);
    _sidebarVisible = layout.sidebarVisible;
  }

  static const double minSidebarWidth = 0.12;
  static const double maxSidebarWidth = 0.45;
  static const Duration toastDuration = Duration(milliseconds: 3500);

  final TitleMenuState titleMenu = TitleMenuState();

  late AppSettings settings;

  Modal? _modal;
  Modal? get modal => _modal;
  set modal(Modal? value) {
    _modal = value;
    notifyListeners();
  }

  /// Toggles the palette: opens it, or closes it when it is already showing.
  void togglePalette() =>
      modal = modal is ModalPalette ? null : const ModalPalette();

  String? _toast;
  String? get toast => _toast;
  Timer? _toastTimer;

  /// Shows a short message at the bottom of the window.
  void showToast(String message) {
    _toast = message;
    notifyListeners();
    _toastTimer?.cancel();
    _toastTimer = Timer(toastDuration, () {
      _toast = null;
      notifyListeners();
    });
  }

  String? _availableUpdate;

  /// The newer version found by the update check, or null. Drives the status-bar download icon.
  String? get availableUpdate => _availableUpdate;
  set availableUpdate(String? version) {
    _availableUpdate = version;
    notifyListeners();
  }

  late double _sidebarWidth;

  /// The sidebar's share of the window width.
  double get sidebarWidth => _sidebarWidth;
  set sidebarWidth(double value) {
    _sidebarWidth = value.clamp(minSidebarWidth, maxSidebarWidth);
    notifyListeners();
  }

  late bool _sidebarVisible;
  bool get sidebarVisible => _sidebarVisible;
  set sidebarVisible(bool value) {
    _sidebarVisible = value;
    notifyListeners();
  }

  String? _prefsSection;

  /// The Preferences section to open next time the dialog shows.
  String? get prefsSection => _prefsSection;
  set prefsSection(String? value) {
    _prefsSection = value;
    notifyListeners();
  }

  void updateSettings(AppSettings next) {
    if (next == settings) return;
    settings = next;
    AppStore.saveSettings(next);
    notifyListeners();
  }

  void toggleLayout() => updateSettings(
    settings.copyWith(verticalLayout: !settings.verticalLayout),
  );

  /// Changes the interface size by one step; 0 restores the default.
  void zoom(int delta) {
    final size = delta == 0
        ? AppSettings.defaultFontSize
        : (settings.fontSize + delta).clamp(
            AppSettings.minFontSize,
            AppSettings.maxFontSize,
          );
    updateSettings(settings.copyWith(fontSize: size));
  }

  /// The values whose change should be saved right away (see the shell's layout listener).
  List<Object?> layoutSnapshot() => [sidebarWidth, sidebarVisible];

  /// Writes the layout to disk. Settings are saved as they change.
  void persist() => AppStore.saveLayout(
    SavedLayout(sidebarWidth: sidebarWidth, sidebarVisible: sidebarVisible),
  );

  @override
  void dispose() {
    _toastTimer?.cancel();
    titleMenu.removeListener(notifyListeners);
    titleMenu.dispose();
    super.dispose();
  }
}

/// Hands [AppState] to widgets: `AppScope.of(context)` rebuilds on every change, `AppScope.read(context)` does not.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  static AppState read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
