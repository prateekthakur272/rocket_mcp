import 'package:material_ui/material_ui.dart' show CircularProgressIndicator;
import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/theme/theme.dart';

/// A small accent-coloured progress spinner for rows and buttons.
class MiniSpinner extends StatelessWidget {
  const MiniSpinner({super.key, this.size = 11});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      color: context.pal.accent,
      strokeWidth: 1.5,
    ),
  );
}
