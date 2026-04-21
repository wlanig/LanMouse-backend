import 'dart:ui';

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class TouchpadProvider extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  // 触控状态
  bool _isTracking = false;
  double _lastX = 0;
  double _lastY = 0;
  int _pointerCount = 0;

  // 手势状态
  bool _isScrollMode = false;
  bool _isDragMode = false;
  DateTime? _lastTapTime;
  Offset? _lastTapPosition;

  TouchpadProvider();

  bool get isTracking => _isTracking;
  bool get isScrollMode => _isScrollMode;
  bool get isConnected => _socketService.isConnected;

  void onTouchStart(double x, double y, int pointerCount) {
    _isTracking = true;
    _lastX = x;
    _lastY = y;
    _pointerCount = pointerCount;

    // 发送触摸开始消息
    if (_socketService.isConnected) {
      final message = MouseControlMessage.touchStart(x: x, y: y);
      _socketService.sendMessage(message);
    }

    notifyListeners();
  }

  void onTouchMove(double x, double y, int pointerCount) {
    if (!_isTracking) return;

    final dx = x - _lastX;
    final dy = y - _lastY;
    _lastX = x;
    _lastY = y;
    _pointerCount = pointerCount;

    // 根据指针数量判断手势模式
    if (pointerCount == 1) {
      // 单指移动
      _isScrollMode = false;
      if (_socketService.isConnected) {
        final message = MouseControlMessage.move(dx, dy);
        _socketService.sendMessage(message);
      }
    } else if (pointerCount == 2) {
      // 双指滚动
      _isScrollMode = true;
      if (_socketService.isConnected) {
        final message = MouseControlMessage.scroll(dy);
        _socketService.sendMessage(message);
      }
    }

    notifyListeners();
  }

  void onTouchEnd(double x, double y, int pointerCount) {
    final wasTracking = _isTracking;
    _isTracking = false;
    _pointerCount = pointerCount;

    // 判断点击或双击
    if (wasTracking && pointerCount == 0) {
      final now = DateTime.now();
      final tapPosition = Offset(x, y);

      if (_lastTapTime != null && _lastTapPosition != null) {
        final timeDiff = now.difference(_lastTapTime!).inMilliseconds;
        final distance = (tapPosition - _lastTapPosition!).distance;

        // 双击判断：300ms内，位置接近
        if (timeDiff < 300 && distance < 30) {
          _sendDoubleClick(x, y);
          _lastTapTime = null;
          _lastTapPosition = null;
        } else {
          _sendSingleClick(x, y);
          _lastTapTime = now;
          _lastTapPosition = tapPosition;
        }
      } else {
        _sendSingleClick(x, y);
        _lastTapTime = now;
        _lastTapPosition = tapPosition;
      }
    }

    // 发送触摸结束消息
    if (_socketService.isConnected) {
      final message = MouseControlMessage.touchEnd(x: x, y: y);
      _socketService.sendMessage(message);
    }

    notifyListeners();
  }

  void _sendSingleClick(double x, double y) {
    if (_socketService.isConnected) {
      final message = MouseControlMessage.click(
        x: x,
        y: y,
        button: MouseButton.left,
      );
      _socketService.sendMessage(message);
    }
  }

  void _sendDoubleClick(double x, double y) {
    if (_socketService.isConnected) {
      // 发送两次单击模拟双击
      final message1 = MouseControlMessage.click(
        x: x,
        y: y,
        button: MouseButton.left,
      );
      final message2 = MouseControlMessage.click(
        x: x,
        y: y,
        button: MouseButton.left,
      );
      _socketService.sendMessage(message1);
      _socketService.sendMessage(message2);
    }
  }

  void sendRightClick(double x, double y) {
    if (_socketService.isConnected) {
      final message = MouseControlMessage.click(
        x: x,
        y: y,
        button: MouseButton.right,
      );
      _socketService.sendMessage(message);
    }
  }
}
