import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import 'login_page.dart';
import 'payment_page.dart';

class UserCenterPage extends StatefulWidget {
  const UserCenterPage({super.key});

  @override
  State<UserCenterPage> createState() => _UserCenterPageState();
}

class _UserCenterPageState extends State<UserCenterPage> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final deviceProvider = context.read<DeviceProvider>();
    await deviceProvider.loadDevices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        actions: [
          IconButton(
            onPressed: _showSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          if (!userProvider.isLoggedIn) {
            return _buildNotLoggedIn();
          }
          return _buildUserInfo(userProvider);
        },
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '登录后享受完整服务',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _navigateToLogin,
            child: const Text('登录 / 注册'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(UserProvider userProvider) {
    final user = userProvider.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 用户信息卡片
          _buildUserCard(user),
          const SizedBox(height: 24),

          // 设备管理
          _buildDeviceSection(),
          const SizedBox(height: 24),

          // 订阅状态
          _buildSubscriptionSection(),
          const SizedBox(height: 24),

          // 功能菜单
          _buildMenuSection(),
          const SizedBox(height: 24),

          // 退出登录
          OutlinedButton(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
              side: const BorderSide(color: AppTheme.errorColor),
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user?.name?.substring(0, 1) ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? '用户',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.maskedIdCard ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                if (user?.userGroup != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      user!.userGroup!.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _navigateToLogin,
            icon: const Icon(
              Icons.edit,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        return _buildSection(
          title: '我的设备',
          icon: Icons.phone_android,
          onTap: () => _showDeviceManagement(deviceProvider),
          child: deviceProvider.devices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '暂无设备，点击添加',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deviceProvider.devices.length > 2
                      ? 2
                      : deviceProvider.devices.length,
                  itemBuilder: (context, index) {
                    final device = deviceProvider.devices[index];
                    return ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text(device.deviceName ?? '未知设备'),
                      subtitle: Text(device.deviceModel ?? ''),
                      trailing: _buildStatusBadge(device.status),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSubscriptionSection() {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, _) {
        final currentDevice = deviceProvider.currentDevice;
        final hasSubscription = currentDevice?.subscription != null;

        return _buildSection(
          title: '订阅状态',
          icon: Icons.card_membership,
          onTap: () => _showSubscriptionDetails(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasSubscription
                        ? AppTheme.successColor.withOpacity(0.1)
                        : AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasSubscription
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    color: hasSubscription
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSubscription ? '订阅中' : '未订阅',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (hasSubscription && currentDevice!.subscription!.endDate != null)
                        Text(
                          '有效期至: ${_formatDate(currentDevice.subscription!.endDate!)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!hasSubscription)
                  ElevatedButton(
                    onPressed: () => _navigateToPayment(deviceProvider),
                    child: const Text('立即订阅'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuSection() {
    return _buildSection(
      title: '功能',
      icon: Icons.apps,
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.help_outline,
            title: '使用帮助',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.info_outline,
            title: '关于我们',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.description_outlined,
            title: '用户协议',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon, color: AppTheme.primaryColor),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: onTap != null
                ? const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
                : null,
            onTap: onTap,
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildStatusBadge(int status) {
    Color color;
    String text;

    switch (status) {
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
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _navigateToPayment(DeviceProvider deviceProvider) {
    if (deviceProvider.currentDevice?.deviceId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            deviceId: deviceProvider.currentDevice!.deviceId!,
          ),
        ),
      );
    }
  }

  void _showDeviceManagement(DeviceProvider deviceProvider) {
    // TODO: 导航到设备管理页面
  }

  void _showSubscriptionDetails() {
    // TODO: 显示订阅详情
  }

  void _showSettings() {
    // TODO: 显示设置页面
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<UserProvider>().logout();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}
