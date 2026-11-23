import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/components/empty_state.dart';
import 'package:rocket_mcp/theme/icons.dart';

/// The empty state of a Tools / Resources / Prompts list of a connected server: either a filter hides every item, or
/// the server has none. The lists are fetched when the server connects, so there is nothing to refresh.
class ListEmptyState extends StatelessWidget {
  const ListEmptyState({
    super.key,
    required this.noun,
    required this.icon,
    this.filtered = false,
    this.loading = false,
  });

  /// The plural name of what the list holds: `tools`, `resources`, `prompts`.
  final String noun;
  final IconData icon;

  /// True when a filter is hiding items that do exist.
  final bool filtered;

  /// True while the first fetch after connecting is still running, so an empty list is not yet "none".
  final bool loading;

  @override
  Widget build(BuildContext context) => loading
      ? EmptyState(compact: true, icon: Ic.connecting, title: 'Loading $noun…')
      : filtered
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
        );
}
