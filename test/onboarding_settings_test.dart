import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/modal.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/dialogs/onboarding_dialog.dart';
import 'package:rocket_mcp/features/preferences/preferences.dart';
import 'package:rocket_mcp/theme/theme.dart';

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-onboarding-test');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  Widget wrapWithTheme(Widget child, [AppState? state]) {
    final s = state ?? AppState();
    return AppScope(
      state: s,
      child: PalScope(
        pal: DarkPal,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MaterialApp(home: child),
        ),
      ),
    );
  }

  group('Onboarding Tour', () {
    test('AppStore.needsOnboarding detects fresh install and respects completion flag', () {
      expect(AppStore.needsOnboarding, isTrue);
      AppStore.setFlag('onboarding_completed', true);
      expect(AppStore.needsOnboarding, isFalse);
    });

    testWidgets('walks through 3 steps and completes onboarding', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      state.modal = const ModalOnboarding();

      await tester.pumpWidget(
        wrapWithTheme(OnboardingDialog(state: state), state),
      );
      await tester.pumpAndSettle();

      // Step 1: Welcome & Mission
      expect(find.text('Connect & Manage MCP Servers'), findsOneWidget);
      expect(find.text('Explore Tools, Prompts & Resources'), findsOneWidget);
      expect(find.text('Real-Time Traffic & Log Inspector'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Advance to Step 2
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Customize Workspace'), findsOneWidget);
      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Workspace Layout & Sizing'), findsOneWidget);
      expect(find.text('Auto-Save Requests'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);

      // Advance to Step 3
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started with MCP Servers'), findsOneWidget);
      expect(find.text('New MCP Server Connection'), findsOneWidget);
      expect(find.text('Import Claude Desktop & MCP Configs'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Go back to Step 2
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Customize Workspace'), findsOneWidget);

      // Return to Step 3 and Finish
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(state.modal, isNull);
      expect(AppStore.needsOnboarding, isFalse);
    });

    testWidgets('skip button finishes onboarding immediately', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final state = AppState();
      state.modal = const ModalOnboarding();

      await tester.pumpWidget(
        wrapWithTheme(OnboardingDialog(state: state), state),
      );
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(state.modal, isNull);
      expect(AppStore.needsOnboarding, isFalse);
    });
  });

  group('Preferences Dialog', () {
    testWidgets(
      'switches categories using top segmented pill bar and filters via search',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final state = AppState();
        state.modal = const ModalSettings();

        await tester.pumpWidget(
          wrapWithTheme(PreferencesDialog(state: state), state),
        );
        await tester.pumpAndSettle();

        // Top pill categories are present
        expect(find.text('General'), findsAtLeastNWidgets(1));
        expect(find.text('Appearance'), findsAtLeastNWidgets(1));
        expect(find.text('Connections'), findsAtLeastNWidgets(1));
        expect(find.text('Network'), findsAtLeastNWidgets(1));
        expect(find.text('Shortcuts'), findsAtLeastNWidgets(1));
        expect(find.text('Data'), findsAtLeastNWidgets(1));

        // Switch to Appearance
        await tester.tap(find.text('Appearance').first);
        await tester.pumpAndSettle();
        expect(find.text('Workspace layout'), findsOneWidget);
        expect(find.text('Interface size'), findsOneWidget);

        // Switch to Connections
        await tester.tap(find.text('Connections').first);
        await tester.pumpAndSettle();
        expect(find.text('Auto-connect servers'), findsOneWidget);
        expect(find.text('Timeout'), findsOneWidget);
        expect(find.text('User-Agent'), findsOneWidget);

        // Switch to Shortcuts
        await tester.ensureVisible(find.text('Shortcuts').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Shortcuts').first);
        await tester.pumpAndSettle();
        expect(find.text('Command palette'), findsOneWidget);

        // Search filtering
        await tester.enterText(find.byType(EditableText).first, 'proxy');
        await tester.pumpAndSettle();
        expect(find.text('Use an HTTP proxy'), findsOneWidget);

        // Done closes preferences
        expect(find.text('Done'), findsOneWidget);
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(state.modal, isNull);
      },
    );
  });
}
