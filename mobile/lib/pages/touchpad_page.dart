import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class TouchpadPage extends StatefulWidget {
  const TouchpadPage({super.key});

  @override
  State<TouchpadPage> createState() => _TouchpadPageState();
}

class _TouchpadPageState extends State<TouchpadPage> {
  Offset? _touchStart;
  Offset? _lastPosition;
  int _pointerCount = 0;
  bool _showGestureHint = true;

  @override
  void initState() {
    super.initState();
    // 3秒后隐藏手势提示
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showGestureHint = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 触控区域
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onDoubleTap: _onDoubleTap,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: AppTheme.backgroundColor,
                child: CustomPaint(
                  painter: _TouchpadGridPainter(),
                ),
              ),
            ),

            // 顶部状态栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildStatusBar(),
            ),

            // 手势提示
            if (_showGestureHint) _buildGestureHint(),

            // 右键菜单按钮
            Positioned(
              right: 16,
              bottom: 100,
              child: _buildRightClickButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    return Consumer<ConnectionProvider>(
      builder: (context, connectionProvider, _) {
        final status = connectionProvider.status;
        final server = connectionProvider.selectedServer;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.cardColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // 连接状态指示器
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getStatusColor(status),
                ),
              ),
              const SizedBox(width: 8),
              // 连接状态文字
              Text(
                status.text,
                style: TextStyle(
                  color: _getStatusColor(status),
                  fontSize: 14,
                ),
              ),
              if (server != null && status == ConnectionStatus.connected) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    server.name ?? server.ip,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              // 断开按钮
              if (status == ConnectionStatus.connected)
                IconButton(
                  onPressed: () => connectionProvider.disconnect(),
                  icon: const Icon(
                    Icons.link_off,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppTheme.connectedColor;
      case ConnectionStatus.connecting:
        return AppTheme.connectingColor;
      case ConnectionStatus.error:
        return AppTheme.errorColor;
      default:
        return AppTheme.disconnectedColor;
    }
  }

  Widget _buildGestureHint() {
    return Positioned(
      bottom: 120,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            '单指移动光标 | 双指滚动 | 双击执行点击',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightClickButton() {
    return Consumer<TouchpadProvider>(
      builder: (context, touchpadProvider, _) {
        return GestureDetector(
          onTap: () {
            // 发送右键点击（使用中心位置）
            touchpadProvider.sendRightClick(50, 50);
            _showRightClickFeedback();
          },
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
      },
    );
  }

  void _showRightClickFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('右键点击'),
        duration: Duration(milliseconds: 500),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _touchStart = details.localPosition;
    _lastPosition = details.localPosition;

    final touchpadProvider = context.read<TouchpadProvider>();
    final size = context.size;
    if (size != null) {
      final x = (details.localPosition.dx / size.width) * 100;
      final y = (details.localPosition.dy / size.height) * 100;
      touchpadProvider.onTouchStart(x, y, 1);
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_lastPosition == null) return;

    final touchpadProvider = context.read<TouchpadProvider>();
    final size = context.size;
    if (size != null) {
      final x = (details.localPosition.dx / size.width) * 100;
      final y = (details.localPosition.dy / size.height) * 100;
      touchpadProvider.onTouchMove(x, y, 1);
    }

    _lastPosition = details.localPosition;
  }

  void _onPanEnd(DragEndDetails details) {
    final touchpadProvider = context.read<TouchpadProvider>();
    final size = context.size;
    if (size != null && _lastPosition != null) {
      final x = (_lastPosition!.dx / size.width) * 100;
      final y = (_lastPosition!.dy / size.height) * 100;
      touchpadProvider.onTouchEnd(x, y, 0);
    }

    _touchStart = null;
    _lastPosition = null;
  }

  void _onTapDown(TapDownDetails details) {
    // 记录点击位置用于判断是否双击
  }

  void _onTapUp(TapUpDetails details) {
    // 单击处理
  }

  void _onDoubleTap() {
    // 双击处理
  }
}

class _TouchpadGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.cardColor.withOpacity(0.3)
      ..strokeWidth = 0.5;

    // 绘制网格
    const gridSize = 50.0;

    // 垂直线
    for (double x = gridSize; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 水平线
    for (double y = gridSize; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
