import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/models.dart';

class DiscoveryService extends ChangeNotifier {
  RawDatagramSocket? _socket;
  List<PcServer> _discoveredServers = [];
  bool _isDiscovering = false;
  Timer? _discoveryTimer;

  List<PcServer> get discoveredServers => _discoveredServers;
  bool get isDiscovering => _isDiscovering;

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;

    _isDiscovering = true;
    _discoveredServers.clear();
    notifyListeners();

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        AppConfig.discoveryPort,
        reuseAddress: true,
        reusePort: true,
      );

      _socket!.broadcastEnabled = true;

      _socket!.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket!.receive();
          if (datagram != null) {
            _handleDiscoveryMessage(datagram);
          }
        }
      });

      _sendBroadcast();

      // 每5秒发送一次广播
      _discoveryTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => _sendBroadcast(),
      );

      // 15秒后自动停止
      Timer(const Duration(seconds: 15), stopDiscovery);
    } catch (e) {
      debugPrint('Discovery error: $e');
      _isDiscovering = false;
      notifyListeners();
    }
  }

  void _sendBroadcast() {
    if (_socket == null) return;

    try {
      // 发送LanMouse发现请求
      const message = 'LANMOUSE_DISCOVER';
      final data = utf8.encode(message);

      // 发送到广播地址
      _socket!.send(
        data,
        InternetAddress('255.255.255.255'),
        AppConfig.discoveryPort,
      );
    } catch (e) {
      debugPrint('Broadcast error: $e');
    }
  }

  void _handleDiscoveryMessage(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data).trim();
      final ip = datagram.address.address;

      // 跳过自己的消息
      if (message.startsWith('LANMOUSE_DISCOVER')) return;

      // 解析响应消息
      // 格式: LANMOUSE|设备名称|端口|是否有密码
      if (message.startsWith('LANMOUSE|')) {
        final parts = message.split('|');
        final server = PcServer(
          ip: ip,
          name: parts.length > 1 ? parts[1] : '未知设备',
          port: parts.length > 2
              ? int.tryParse(parts[2]) ?? AppConfig.pcServicePort
              : AppConfig.pcServicePort,
          hasPassword: parts.length > 3 && parts[3] == '1',
        );

        // 检查是否已存在
        final existing = _discoveredServers.indexWhere((s) => s.ip == ip);
        if (existing >= 0) {
          _discoveredServers[existing] = server;
        } else {
          _discoveredServers.add(server);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Parse discovery message error: $e');
    }
  }

  void stopDiscovery() {
    _discoveryTimer?.cancel();
    _socket?.close();
    _socket = null;
    _isDiscovering = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopDiscovery();
    super.dispose();
  }
}
