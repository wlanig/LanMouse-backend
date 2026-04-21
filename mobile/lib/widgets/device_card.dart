import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/models.dart';

class DeviceCard extends StatelessWidget {
  final Device device;
  final bool isSelected;
  final VoidCallback? onTap;

  const DeviceCard({
    super.key,
    required this.device,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 设备图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getDeviceIcon(),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // 设备信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.deviceName ?? '未知设备',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.deviceModel ?? '',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // 状态
              _buildStatusBadge(),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    switch (device.osType?.toLowerCase()) {
      case 'ios':
        return Icons.apple;
      case 'android':
        return Icons.phone_android;
      default:
        return Icons.phone_android;
    }
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;

    switch (device.status) {
      case 1:
        color = AppTheme.successColor;
        text = '正常';
        break;
      case 2:
        color = AppTheme.errorColor;
        text = '冻结';
        break;
      default:
        color = AppTheme.textSecondary;
        text = '未激活';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
