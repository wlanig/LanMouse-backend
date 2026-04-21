import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String _selectedPayment = 'alipay';
  Device? _selectedDevice;
  bool _isCreatingOrder = false;
  bool _isPolling = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final deviceProvider = context.read<DeviceProvider>();
    await deviceProvider.loadDevices();
    if (deviceProvider.devices.isNotEmpty) {
      setState(() {
        _selectedDevice = deviceProvider.devices.first;
      });
    }
  }

  Future<void> _createOrder() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先添加设备'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isCreatingOrder = true);

    try {
      final paymentProvider = context.read<PaymentProvider>();
      final success = await paymentProvider.createOrder(_selectedDevice!.id!);

      if (!mounted) return;

      if (success) {
        _startPolling();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentProvider.errorMessage ?? '创建订单失败'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingOrder = false);
      }
    }
  }

  void _startPolling() {
    setState(() => _isPolling = true);
    _pollPaymentStatus();
  }

  Future<void> _pollPaymentStatus() async {
    final paymentProvider = context.read<PaymentProvider>();

    while (_isPolling && paymentProvider.currentOrder != null) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      final status = await paymentProvider.checkOrderStatus();
      if (status == 'paid') {
        setState(() => _isPolling = false);
        if (mounted) {
          _showPaymentSuccessDialog();
        }
        return;
      } else if (status == 'expired' || status == 'cancelled') {
        setState(() => _isPolling = false);
        return;
      }
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppTheme.successColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '支付成功',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '您的设备已激活，订阅有效期1年',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text('完成'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '续费订阅',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          final order = paymentProvider.currentOrder;

          if (order != null) {
            return _buildPaymentView(order);
          }

          return _buildOrderForm();
        },
      ),
    );
  }

  Widget _buildOrderForm() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 设备选择
          const Text(
            '选择设备',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<DeviceProvider>(
            builder: (context, deviceProvider, _) {
              if (deviceProvider.devices.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '暂无设备，请先添加设备',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Device>(
                    value: _selectedDevice,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceColor,
                    style: const TextStyle(color: Colors.white),
                    items: deviceProvider.devices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(device.deviceName ?? '未知设备'),
                      );
                    }).toList(),
                    onChanged: (device) {
                      setState(() => _selectedDevice = device);
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // 支付方式
          const Text(
            '选择支付方式',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentOption('alipay', '支付宝', Icons.payment),
          const SizedBox(height: 12),
          _buildPaymentOption('wechat', '微信支付', Icons.payment),
          const Spacer(),
          // 金额信息
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildPriceRow('服务类型', '年度订阅'),
                const SizedBox(height: 8),
                _buildPriceRow('服务期限', '1年'),
                const SizedBox(height: 8),
                _buildPriceRow('原价', '¥99.00'),
                const SizedBox(height: 8),
                _buildPriceRow('应付金额', '¥99.00', isTotal: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 提交按钮
          ElevatedButton(
            onPressed: _isCreatingOrder ? null : _createOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isCreatingOrder
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '生成支付二维码',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String value, String label, IconData icon) {
    final isSelected = _selectedPayment == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : AppTheme.textSecondary,
            fontSize: isTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppTheme.primaryColor : Colors.white,
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentView(Order order) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '请使用支付宝扫码支付',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          // 二维码
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: QrImage(
              data: order.qrCodeData ?? order.qrCodeUrl ?? '',
              version: QrVersions.auto,
              size: 250,
            ),
          ),
          const SizedBox(height: 24),
          // 订单金额
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '支付金额: ¥${order.amount?.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 订单号
          Text(
            '订单号: ${order.orderNo}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          // 支付状态
          if (_isPolling)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '等待支付...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          const Spacer(),
          // 取消按钮
          TextButton(
            onPressed: () {
              context.read<PaymentProvider>().clearOrder();
              setState(() => _isPolling = false);
            },
            child: const Text(
              '取消订单',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
