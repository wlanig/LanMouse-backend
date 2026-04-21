import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../utils/validators.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '19876');
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startDiscovery();
  }

  void _startDiscovery() {
    context.read<ConnectionProvider>().startDiscovery();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('连接设备'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '自动发现'),
            Tab(text: '手动输入'),
          ],
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoveryTab(),
          _buildManualTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoveryTab() {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // 自动发现状态
            Container(
              padding: const EdgeInsets.all(16),
              color: AppTheme.surfaceColor,
              child: Row(
                children: [
                  if (provider.discoveredServers.isEmpty && !provider.isConnected)
                    const Icon(
                      Icons.search,
                      color: AppTheme.textSecondary,
                      size: 20,
                    )
                  else
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.successColor,
                      size: 20,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.discoveredServers.isEmpty
                          ? '正在搜索局域网内的PC服务端...'
                          : '发现 ${provider.discoveredServers.length} 台设备',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _startDiscovery,
                    child: const Text('刷新'),
                  ),
                ],
              ),
            ),

            // 设备列表
            Expanded(
              child: _buildDeviceList(provider),
            ),

            // 连接历史
            if (provider.connectionHistory.isNotEmpty)
              _buildHistorySection(provider),
          ],
        );
      },
    );
  }

  Widget _buildDeviceList(ConnectionProvider provider) {
    if (provider.discoveredServers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '正在搜索...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: provider.discoveredServers.length,
      itemBuilder: (context, index) {
        final server = provider.discoveredServers[index];
        return _buildServerTile(server, provider);
      },
    );
  }

  Widget _buildServerTile(PcServer server, ConnectionProvider provider) {
    final isSelected = provider.selectedServer?.ip == server.ip &&
        provider.selectedServer?.port == server.port;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.computer,
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(
          server.name ?? '未知设备',
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '${server.ip}:${server.port}',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: server.hasPassword
            ? const Icon(
                Icons.lock,
                color: AppTheme.warningColor,
                size: 18,
              )
            : null,
        onTap: () => _onServerSelected(server, provider),
      ),
    );
  }

  void _onServerSelected(PcServer server, ConnectionProvider provider) {
    provider.selectServer(server);

    if (server.hasPassword) {
      _showPasswordDialog(server, provider);
    } else {
      _connectToServer(server, provider);
    }
  }

  void _showPasswordDialog(PcServer server, ConnectionProvider provider) {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入连接密码'),
        content: TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: '请输入密码',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.setPassword(_passwordController.text);
              _connectToServer(server, provider);
            },
            child: const Text('连接'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToServer(PcServer server, ConnectionProvider provider) async {
    final success = await provider.connect();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('连接成功'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? '连接失败'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildHistorySection(ConnectionProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '连接历史',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.connectionHistory.length,
            itemBuilder: (context, index) {
              final server = provider.connectionHistory[index];
              return _buildHistoryItem(server, provider);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryItem(PcServer server, ConnectionProvider provider) {
    return GestureDetector(
      onTap: () => _onServerSelected(server, provider),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.history,
              color: AppTheme.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              server.name ?? server.ip,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualTab() {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IP地址输入
              TextField(
                controller: _ipController,
                decoration: const InputDecoration(
                  labelText: 'IP地址',
                  hintText: '例如: 192.168.1.100',
                  prefixIcon: Icon(Icons.router),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 端口输入
              TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口',
                  hintText: '默认: 19876',
                  prefixIcon: Icon(Icons.settings_ethernet),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // 连接按钮
              ElevatedButton(
                onPressed: () => _onManualConnect(provider),
                child: provider.status == ConnectionStatus.connecting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('连接'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onManualConnect(ConnectionProvider provider) {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 19876;

    if (!IpValidator.isValid(ip)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入有效的IP地址'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    provider.setManualIp(ip, port: port);
    _connectToServer(provider.selectedServer!, provider);
  }
}
