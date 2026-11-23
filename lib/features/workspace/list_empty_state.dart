import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/buttons.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/theme/icons.dart';

/// The empty state of a Tools / Resources / Prompts list of a connected server: either a filter hides every item, or
/// the server has none and the user can refresh the list.
class ListEmptyState extends StatelessWidget {
  const ListEmptyState({
    super.key,
    required this.noun,
    required this.icon,
    required this.onRefresh,
    this.filtered = false,
  });

  /// The plural name of what the list holds: `tools`, `resources`, `prompts`.
  final String noun;
  final IconData icon;
  final VoidCallback onRefresh;

  /// True when a filter is hiding items that do exist.
  final bool filtered;

  @override
  Widget build(BuildContext context) => filtered
      ? EmptyState(
          compact: true,
          icon: Ic.search,
          title: 'No matching $noun',
          message: 'Try a different search.',
        )
      : EmptyState(
          compact: true,
          icon: icon,
          title: 'No $noun',
          message: 'This server does not expose any $noun.',
          actions: [
            Btn(
              label: 'Refresh',
              icon: Ic.refresh,
              outlined: true,
              onClick: onRefresh,
            ),
          ],
        );
}
