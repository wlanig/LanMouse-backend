import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/models.dart';

class ConnectionStatusBar extends StatelessWidget {
  final ConnectionStatus status;
  final String? serverName;
  final VoidCallback? onTap;

  const ConnectionStatusBar({
    super.key,
    required this.status,
    this.serverName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            bottom: BorderSide(
              color: AppTheme.cardColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // 状态指示灯
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getStatusColor(),
                boxShadow: [
                  BoxShadow(
                    color: _getStatusColor().withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // 状态文字
            Text(
              status.text,
              style: TextStyle(
                color: _getStatusColor(),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            // 服务器名称
            if (serverName != null && status == ConnectionStatus.connected) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  serverName!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondary,
                size: 20,
              ),
            ] else
              const Spacer(),

            // 断开按钮
            if (status == ConnectionStatus.connected)
              IconButton(
                onPressed: onTap,
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
      ),
    );
  }

  Color _getStatusColor() {
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
}
