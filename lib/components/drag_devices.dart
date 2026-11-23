import 'package:flutter/gestures.dart' show PointerDeviceKind;

/// The pointers whose drags may move or resize things (sidebar tiles, dividers, the window).
///
/// Not [PointerDeviceKind.trackpad]: a two-finger swipe reaches Flutter as a pan, so a handle that accepted it
/// would be dragged by plain scrolling. Mouse, touch and pen still drag; the trackpad scrolls.
const Set<PointerDeviceKind> kDragDevices = {
  PointerDeviceKind.mouse,
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.unknown,
};
