import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class TouchpadWidget extends StatefulWidget {
  final bool isConnected;
  final Function(double x, double y, int pointerCount)? onTouchStart;
  final Function(double x, double y, int pointerCount)? onTouchMove;
  final Function(double x, double y, int pointerCount)? onTouchEnd;
  final VoidCallback? onRightClick;

  const TouchpadWidget({
    super.key,
    required this.isConnected,
    this.onTouchStart,
    this.onTouchMove,
    this.onTouchEnd,
    this.onRightClick,
  });

  @override
  State<TouchpadWidget> createState() => _TouchpadWidgetState();
}

class _TouchpadWidgetState extends State<TouchpadWidget> {
  Offset? _touchStart;
  Offset? _lastPosition;
  int _currentPointerCount = 0;
  bool _isMultiTouch = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 触控区域
        Listener(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerUp,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: AppTheme.backgroundColor,
            child: CustomPaint(
              painter: _TouchpadPainter(
                isConnected: widget.isConnected,
                isMultiTouch: _isMultiTouch,
              ),
            ),
          ),
        ),

        // 右键按钮
        Positioned(
          right: 16,
          bottom: 100,
          child: _buildRightClickButton(),
        ),

        // 未连接提示
        if (!widget.isConnected)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Text(
                '请先连接设备',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRightClickButton() {
    return GestureDetector(
      onTap: widget.onRightClick,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.menu,
          color: AppTheme.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _touchStart = event.localPosition;
    _lastPosition = event.localPosition;
    _currentPointerCount = 1;
    _isMultiTouch = false;

    final size = context.size;
    if (size != null) {
      final x = (event.localPosition.dx / size.width) * 100;
      final y = (event.localPosition.dy / size.height) * 100;
      widget.onTouchStart?.call(x, y, _currentPointerCount);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_lastPosition == null) return;

    final size = context.size;
    if (size != null) {
      final x = (event.localPosition.dx / size.width) * 100;
      final y = (event.localPosition.dy / size.height) * 100;

      // 检测双指
      if (_currentPointerCount == 2) {
        _isMultiTouch = true;
      }

      widget.onTouchMove?.call(x, y, _currentPointerCount);
    }

    _lastPosition = event.localPosition;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final size = context.size;
    if (size != null && _lastPosition != null) {
      final x = (_lastPosition!.dx / size.width) * 100;
      final y = (_lastPosition!.dy / size.height) * 100;
      widget.onTouchEnd?.call(x, y, 0);
    }

    _touchStart = null;
    _lastPosition = null;
    _currentPointerCount = 0;
    _isMultiTouch = false;
  }
}

class _TouchpadPainter extends CustomPainter {
  final bool isConnected;
  final bool isMultiTouch;

  _TouchpadPainter({
    required this.isConnected,
    required this.isMultiTouch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制背景网格
    final gridPaint = Paint()
      ..color = AppTheme.cardColor.withOpacity(0.2)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;

    // 垂直线
    for (double x = gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    // 水平线
    for (double y = gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // 绘制触控模式指示
    if (isMultiTouch) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '滚动模式',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          (size.width - textPainter.width) / 2,
          size.height - 60,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TouchpadPainter oldDelegate) {
    return oldDelegate.isConnected != isConnected ||
        oldDelegate.isMultiTouch != isMultiTouch;
  }
}
