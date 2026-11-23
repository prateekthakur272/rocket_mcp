import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A keyboard shortcut. [primary] is ⌘ on a Mac and Ctrl elsewhere; [control] is the literal Control key (used for tab switching).
class Shortcut {
  const Shortcut(
    this.key, {
    this.primary = true,
    this.shift = false,
    this.control = false,
    this.alt = false,
  });

  final LogicalKeyboardKey key;
  final bool primary;
  final bool shift;
  final bool control;
  final bool alt;

  SingleActivator toActivator(bool isMac) => SingleActivator(
    key,
    control: control || (primary && !isMac),
    meta: primary && isMac,
    shift: shift,
    alt: alt,
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
    } else if (key == LogicalKeyboardKey.tab) {
      k = isMac ? '⇥' : 'Tab';
    } else if (key == LogicalKeyboardKey.bracketLeft) {
      k = '[';
    } else if (key == LogicalKeyboardKey.bracketRight) {
      k = ']';
    } else if (key == LogicalKeyboardKey.slash) {
      k = '/';
    } else {
      final l = key.keyLabel;
      if (l.isNotEmpty && RegExp(r'^[A-Za-z0-9]$').hasMatch(l)) {
        k = l.toUpperCase();
      } else if (l.startsWith('F') && RegExp(r'^F\d{1,2}$').hasMatch(l)) {
        k = l;
      } else {
        k = l.isNotEmpty ? l : '?';
      }
    }
    if (isMac) {
      return (control ? '⌃' : '') +
          (alt ? '⌥' : '') +
          (shift ? '⇧' : '') +
          (primary ? '⌘' : '') +
          k;
    }
    return [
      if (primary || control) 'Ctrl',
      if (alt) 'Alt',
      if (shift) 'Shift',
      k,
    ].join('+');
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
