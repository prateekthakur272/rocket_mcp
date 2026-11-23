import 'package:flutter/widgets.dart';
import 'package:rocket_mcp/app/app_state.dart';
import 'package:rocket_mcp/components/modifiers.dart';
import 'package:rocket_mcp/components/text.dart';
import 'package:rocket_mcp/features/shell/menus.dart';
import 'package:rocket_mcp/features/shell/title_menus.dart';
import 'package:rocket_mcp/features/shell/window_chrome.dart';
import 'package:rocket_mcp/theme/icons.dart';
import 'package:rocket_mcp/theme/theme.dart';
import 'package:rocket_mcp/utils/app_config.dart';

/// The window's own title bar, which replaces the operating system's. macOS keeps its native traffic-light buttons
/// floating over the left end ([WindowChrome.leftInset]); Windows and Linux get the menus on the left and window
/// buttons on the right. The bar drags the window and a double click maximizes it.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.state, required this.chrome});
  final AppState state;
  final WindowChrome chrome;

  static const double height = 30;

  /// Below this width the centred title is hidden so the menus keep the space.
  static const double titleMinWidth = 1000;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return chrome.dragArea(
      Container(
        height: height,
        color: p.panel,
        child: DrawBottomBorder(
          color: p.border,
          child: TitleBarDoubleClick(
            chrome: chrome,
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Row(
                        spacing: 6,
                        children: [
                          if (chrome.leftInset > 0)
                            SizedBox(width: chrome.leftInset),
                          if (chrome.inlineMenus) ...[
                            Ico(Ic.logo, tint: p.accent, size: 16),
                            TitleMenus(
                              menus: AppMenus.build(
                                state,
                                isMac: false,
                                quit: chrome.onQuit,
                                minimize: chrome.onMinimize,
                              ),
                              tm: state.titleMenu,
                            ),
                          ],
                          const Spacer(),
                          ?chrome.controls,
                        ],
                      ),
                    ),
                  ),
                  if (!chrome.inlineMenus ||
                      constraints.maxWidth >= titleMinWidth)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: T(
                            AppConfig.NAME,
                            color: p.muted,
                            size: 12,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
