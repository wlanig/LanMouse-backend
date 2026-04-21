enum MouseControlType {
  move,
  click,
  scroll,
  touchStart,
  touchEnd,
}

enum MouseButton {
  left,
  right,
  middle,
}

class MouseControlMessage {
  final MouseControlType type;
  final double x;
  final double y;
  final double dx;
  final double dy;
  final MouseButton button;
  final double scrollY;
  final int timestamp;

  MouseControlMessage({
    required this.type,
    this.x = 0,
    this.y = 0,
    this.dx = 0,
    this.dy = 0,
    this.button = MouseButton.left,
    this.scrollY = 0,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

  factory MouseControlMessage.move(double dx, double dy) {
    return MouseControlMessage(
      type: MouseControlType.move,
      dx: dx,
      dy: dy,
    );
  }

  factory MouseControlMessage.click({
    required double x,
    required double y,
    MouseButton button = MouseButton.left,
  }) {
    return MouseControlMessage(
      type: MouseControlType.click,
      x: x,
      y: y,
      button: button,
    );
  }

  factory MouseControlMessage.scroll(double scrollY) {
    return MouseControlMessage(
      type: MouseControlType.scroll,
      scrollY: scrollY,
    );
  }

  factory MouseControlMessage.touchStart({
    required double x,
    required double y,
  }) {
    return MouseControlMessage(
      type: MouseControlType.touchStart,
      x: x,
      y: y,
    );
  }

  factory MouseControlMessage.touchEnd({
    required double x,
    required double y,
  }) {
    return MouseControlMessage(
      type: MouseControlType.touchEnd,
      x: x,
      y: y,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': _typeToString(type),
      'x': x,
      'y': y,
      'dx': dx,
      'dy': dy,
      'button': _buttonToString(button),
      'scrollY': scrollY,
      'timestamp': timestamp,
    };
  }

  String toJsonString() {
    return _jsonEncode(toJson());
  }

  static String _typeToString(MouseControlType type) {
    switch (type) {
      case MouseControlType.move:
        return 'mouse_move';
      case MouseControlType.click:
        return 'mouse_click';
      case MouseControlType.scroll:
        return 'mouse_scroll';
      case MouseControlType.touchStart:
        return 'touch_start';
      case MouseControlType.touchEnd:
        return 'touch_end';
    }
  }

  static MouseButton _stringToButton(String button) {
    switch (button) {
      case 'right':
        return MouseButton.right;
      case 'middle':
        return MouseButton.middle;
      default:
        return MouseButton.left;
    }
  }

  static String _buttonToString(MouseButton button) {
    switch (button) {
      case MouseButton.right:
        return 'right';
      case MouseButton.middle:
        return 'middle';
      case MouseButton.left:
        return 'left';
    }
  }

  static String _jsonEncode(Map<String, dynamic> map) {
    final buffer = StringBuffer('{');
    var first = true;
    map.forEach((key, value) {
      if (!first) buffer.write(',');
      first = false;
      buffer.write('"$key":');
      if (value is String) {
        buffer.write('"$value"');
      } else if (value is num) {
        buffer.write(value);
      } else {
        buffer.write(value);
      }
    });
    buffer.write('}');
    return buffer.toString();
  }
}
