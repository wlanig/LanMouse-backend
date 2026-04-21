class PcServer {
  final String ip;
  final String? name;
  final int port;
  final String? password;
  final DateTime discoveredAt;
  final bool hasPassword;

  PcServer({
    required this.ip,
    this.name,
    required this.port,
    this.password,
    DateTime? discoveredAt,
    this.hasPassword = false,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  factory PcServer.fromDiscovery(String data, String ip) {
    // 解析UDP广播消息
    // 格式: LANMOUSE|设备名称|端口|是否有密码
    final parts = data.split('|');
    return PcServer(
      ip: ip,
      name: parts.length > 1 ? parts[1] : '未知设备',
      port: parts.length > 2 ? int.tryParse(parts[2]) ?? 19876 : 19876,
      hasPassword: parts.length > 3 && parts[3] == '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'name': name,
      'port': port,
      'hasPassword': hasPassword,
      'discoveredAt': discoveredAt.toIso8601String(),
    };
  }

  factory PcServer.fromJson(Map<String, dynamic> json) {
    return PcServer(
      ip: json['ip'],
      name: json['name'],
      port: json['port'] ?? 19876,
      hasPassword: json['hasPassword'] ?? false,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.parse(json['discoveredAt'])
          : DateTime.now(),
    );
  }
}

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

extension ConnectionStatusExtension on ConnectionStatus {
  String get text {
    switch (this) {
      case ConnectionStatus.disconnected:
        return '未连接';
      case ConnectionStatus.connecting:
        return '连接中...';
      case ConnectionStatus.connected:
        return '已连接';
      case ConnectionStatus.error:
        return '连接失败';
    }
  }
}
