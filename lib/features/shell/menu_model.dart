import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A keyboard shortcut. [primary] is ⌘ on a Mac and Ctrl elsewhere; [control] is the literal Control key (used for tab switching).
class Shortcut {
  const Shortcut(
    this.key, {
    this.primary = true,
    this.shift = false,
    this.control = false,
  });

  final LogicalKeyboardKey key;
  final bool primary;
  final bool shift;
  final bool control;

  SingleActivator toActivator(bool isMac) => SingleActivator(
    key,
    control: control || (primary && !isMac),
    meta: primary && isMac,
    shift: shift,
  );

  /// As shown in a menu: ⌘⇧S on a Mac, Ctrl+Shift+S elsewhere.
  String label(bool isMac) {
    String k;
    if (key == LogicalKeyboardKey.enter) {
      k = isMac ? '↵' : 'Enter';
    } else if (key == LogicalKeyboardKey.comma) {
      k = ',';
    } else if (key == LogicalKeyboardKey.equal) {
      k = isMac ? '+' : '=';
    } else if (key == LogicalKeyboardKey.minus) {
      k = '−';
    } else if (key == LogicalKeyboardKey.digit0) {
      k = '0';
    } else if (key == LogicalKeyboardKey.tab) {
      k = isMac ? '⇥' : 'Tab';
    } else {
      final l = key.keyLabel;
      k = (l.length == 1 && RegExp(r'[A-Za-z]').hasMatch(l))
          ? l.toUpperCase()
          : '?';
    }
    if (isMac) {
      return (control ? '⌃' : '') +
          (shift ? '⇧' : '') +
          (primary ? '⌘' : '') +
          k;
    }
    return [if (primary || control) 'Ctrl', if (shift) 'Shift', k].join('+');
  }
}

/// Entry of a title-bar menu.
sealed class MenuEntry {
  const MenuEntry();
}

/// Horizontal divider between menu entries.
class MenuSeparator extends MenuEntry {
  const MenuSeparator();
}

/// [checked] != null makes it a check item.
class MenuItemSpec extends MenuEntry {
  const MenuItemSpec(
    this.label, {
    this.shortcut,
    this.enabled = true,
    this.checked,
    required this.action,
  });

  final String label;
  final Shortcut? shortcut;
  final bool enabled;
  final bool? checked;
  final VoidCallback action;
}

/// Menu entry that opens a nested menu.
class SubMenuSpec extends MenuEntry {
  const SubMenuSpec(this.label, this.items, {this.enabled = true});

  final String label;
  final List<MenuEntry> items;
  final bool enabled;
}

/// Title and entries of one top-level menu.
class MenuSpec {
  const MenuSpec(this.label, this.items);

  final String label;
  final List<MenuEntry> items;
}
