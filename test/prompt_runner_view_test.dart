import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Material, MaterialApp;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/core/storage/app_store.dart';
import 'package:rocket_mcp/features/workspace/prompt_runner_view.dart';
import 'package:rocket_mcp/theme/theme.dart';

Widget _host(AppState state, Widget child) => AppScope(
  state: state,
  child: MaterialApp(
    home: Material(child: RocketTheme(dark: false, child: child)),
  ),
);

void main() {
  late Directory home;

  setUp(() {
    home = Directory.systemTemp.createTempSync('rocketmcp-prompt-test');
    AppStore.homeOverride = home.path;
  });

  tearDown(() {
    AppStore.homeOverride = null;
    home.deleteSync(recursive: true);
  });

  testWidgets(
    'PromptRunnerView allows typing into prompt argument fields without reverting',
    (tester) async {
      final state = AppState();
      final session = McpSession(
        config: const McpServerConfig(id: 'test-server', name: 'Test Server'),
      );

      // Set a selected prompt with arguments
      final prompt = McpPrompt(
        name: 'write_code',
        description: 'Generates code given a language and task',
        arguments: const [
          McpPromptArgument(
            name: 'language',
            description: 'Programming language',
            required: true,
          ),
          McpPromptArgument(
            name: 'task',
            description: 'Task description',
            required: false,
          ),
        ],
      );
      session.selectedPrompt = prompt;

      await tester.pumpWidget(_host(state, PromptRunnerView(session: session)));
      await tester.pumpAndSettle();

      expect(find.text('write_code'), findsOneWidget);
      expect(find.text('language'), findsOneWidget);
      expect(find.text('task'), findsOneWidget);

      // Find the text field for "language"
      final fields = find.byType(Field);
      expect(fields, findsNWidgets(2));

      // Enter text into the first field
      await tester.enterText(fields.first, 'dart');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify text stayed and was recorded in session.promptArguments
      expect(session.promptArguments['language'], 'dart');
      expect(find.text('dart'), findsOneWidget);

      // Enter text into the second field
      await tester.enterText(fields.at(1), 'build a parser');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(session.promptArguments['task'], 'build a parser');
      expect(find.text('build a parser'), findsOneWidget);
    },
  );
}
