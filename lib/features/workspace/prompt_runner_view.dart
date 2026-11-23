import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show SelectableText;
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/app/mcp_session.dart';
import 'package:rocket_mcp/components/resizable_pane.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/components/field.dart';
import 'package:rocket_mcp/features/workspace/list_empty_state.dart';
import 'package:rocket_mcp/components/item_tile.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/core/mcp/model.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// Interactive viewer and tester for MCP prompts.
class PromptRunnerView extends StatelessWidget {
  const PromptRunnerView({super.key, required this.session});
  final McpSession session;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final prompts = session.prompts;
    final selectedPrompt = session.selectedPrompt;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Prompts list
        ResizablePane(
          width: AppScope.of(context).listPaneWidth,
          onWidth: (w) => AppScope.read(context).listPaneWidth = w,
          child: Container(
            decoration: BoxDecoration(
              color: p.panel,
              border: Border(right: BorderSide(color: p.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: T(
                          'PROMPTS (${prompts.length})',
                          size: 10,
                          weight: FontWeight.w600,
                          color: p.muted,
                        ),
                      ),
                      IconBtn(
                        icon: Ic.refresh,
                        size: 14,
                        onClick: session.refreshPrompts,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: prompts.isEmpty
                      ? ListEmptyState(
                          noun: 'prompts',
                          icon: Ic.prompt,
                          onRefresh: session.refreshPrompts,
                        )
                      : ListView.builder(
                          itemCount: prompts.length,
                          itemBuilder: (context, i) {
                            final pr = prompts[i];
                            return ItemTile(
                              icon: Ic.prompt,
                              title: pr.name,
                              subtitle: pr.description,
                              selected: pr.name == selectedPrompt?.name,
                              onClick: () => session.selectedPrompt = pr,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),

        // Prompt configuration and execution
        Expanded(
          child: selectedPrompt == null
              ? EmptyState(
                  icon: Ic.prompt,
                  title: 'Select a prompt',
                  message: prompts.isEmpty
                      ? 'Prompts the server exposes appear in the list.'
                      : 'Pick a prompt from the list to fill in its arguments and fetch it.',
                  suggestions: [
                    for (final pr in prompts.take(4))
                      EmptySuggestion(
                        pr.name,
                        () => session.selectedPrompt = pr,
                        icon: Ic.prompt,
                      ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header with description and Get Prompt button
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: p.panel,
                        border: Border(bottom: BorderSide(color: p.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 3,
                              children: [
                                Row(
                                  spacing: 8,
                                  children: [
                                    Ico(Ic.prompt, tint: p.accent, size: 16),
                                    T(
                                      selectedPrompt.name,
                                      size: 14,
                                      weight: FontWeight.w600,
                                    ),
                                  ],
                                ),
                                if (selectedPrompt.description != null)
                                  T(
                                    selectedPrompt.description!,
                                    size: 11,
                                    color: p.muted,
                                  ),
                              ],
                            ),
                          ),
                          Btn(
                            label: session.isLoadingPrompt
                                ? 'Getting…'
                                : 'Get Prompt',
                            icon: Ic.play,
                            primary: true,
                            enabled:
                                !session.isLoadingPrompt &&
                                session.status == McpServerStatus.connected,
                            onClick: session.fetchPrompt,
                          ),
                        ],
                      ),
                    ),

                    // Arguments and returned messages
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 12,
                          children: [
                            if (selectedPrompt.arguments.isNotEmpty) ...[
                              const SectionLabel('ARGUMENTS'),
                              for (final arg in selectedPrompt.arguments)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 4,
                                  children: [
                                    Row(
                                      spacing: 4,
                                      children: [
                                        T(
                                          arg.name,
                                          size: 12,
                                          weight: FontWeight.w600,
                                        ),
                                        if (arg.required)
                                          T(
                                            '*',
                                            color: p.err,
                                            size: 12,
                                            weight: FontWeight.w700,
                                          ),
                                      ],
                                    ),
                                    if (arg.description != null)
                                      T(
                                        arg.description!,
                                        size: 11,
                                        color: p.muted,
                                      ),
                                    Field(
                                      value:
                                          session.promptArguments[arg.name] ??
                                          '',
                                      onChange: (v) =>
                                          session.promptArguments[arg.name] = v,
                                      placeholder: 'Enter ${arg.name}…',
                                    ),
                                  ],
                                ),
                            ],

                            if (session.promptResult != null) ...[
                              const SizedBox(height: 8),
                              const SectionLabel('GENERATED PROMPT MESSAGES'),
                              if (session.promptResult!.description != null)
                                T(
                                  session.promptResult!.description!,
                                  size: 12,
                                  color: p.muted,
                                ),
                              for (final msg in session.promptResult!.messages)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: p.field,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: p.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    spacing: 6,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: msg.role == 'assistant'
                                              ? p.accent.withValues(alpha: 0.15)
                                              : p.muted.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: T(
                                          msg.role.toUpperCase(),
                                          size: 10,
                                          mono: true,
                                          weight: FontWeight.w700,
                                          color: msg.role == 'assistant'
                                              ? p.accent
                                              : p.text,
                                        ),
                                      ),
                                      SelectableText(
                                        msg.content.text ??
                                            msg.content.data ??
                                            '<empty>',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: p.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
