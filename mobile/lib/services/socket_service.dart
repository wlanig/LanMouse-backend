import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/models.dart';

class SocketService extends ChangeNotifier {
  Socket? _socket;
  PcServer? _currentServer;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String? _errorMessage;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _retryCount = 0;

  // 消息回调
  Function(MouseControlMessage)? onMessage;
  Function(String)? onError;

  PcServer? get currentServer => _currentServer;
  ConnectionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isConnected => _status == ConnectionStatus.connected;

  Future<bool> connect(PcServer server, {String? password}) async {
    if (_status == ConnectionStatus.connecting) return false;

    _currentServer = server;
    _status = ConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      _socket = await Socket.connect(
        server.ip,
        server.port,
        timeout: Duration(milliseconds: AppConfig.socketTimeout),
      );

      // 发送连接握手消息
      final handshake = {
        'type': 'connect',
        'password': password ?? '',
        'deviceName': server.name ?? 'Mobile Device',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      _socket!.write('${jsonEncode(handshake)}\n');

      _setupSocketListener();
      _startHeartbeat();

      _status = ConnectionStatus.connected;
      _retryCount = 0;
      notifyListeners();
      return true;
    } catch (e) {
      _status = ConnectionStatus.error;
      _errorMessage = '连接失败: $e';
      notifyListeners();
      return false;
    }
  }

  void _setupSocketListener() {
    _socket!.listen(
      (data) {
        try {
          final message = utf8.decode(data).trim();
          final json = jsonDecode(message);
          _handleServerMessage(json);
        } catch (e) {
          debugPrint('Socket message parse error: $e');
        }
      },
      onError: (error) {
        _errorMessage = 'Socket错误: $error';
        _handleDisconnect();
      },
      onDone: () {
        _handleDisconnect();
      },
    );
  }

  void _handleServerMessage(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'pong':
        // 心跳响应
        break;
      case 'error':
        _errorMessage = json['message'] as String?;
        onError?.call(_errorMessage ?? '未知错误');
        break;
      case 'auth_required':
        _errorMessage = '需要密码';
        break;
      case 'auth_failed':
        _errorMessage = '密码错误';
        break;
      case 'auth_success':
        _retryCount = 0;
        break;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: AppConfig.heartbeatInterval),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    if (_socket == null || !isConnected) return;
    try {
      final heartbeat = {
        'type': 'ping',
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      _socket!.write('${jsonEncode(heartbeat)}\n');
    } catch (e) {
      debugPrint('Heartbeat error: $e');
    }
  }

  void _handleDisconnect() {
    _heartbeatTimer?.cancel();
    _socket?.destroy();
    _socket = null;

    if (_status != ConnectionStatus.disconnected) {
      _status = ConnectionStatus.disconnected;
      notifyListeners();
      _tryReconnect();
    }
  }

  void _tryReconnect() {
    if (_currentServer == null) return;
    if (_retryCount >= AppConfig.maxRetryAttempts) {
      _errorMessage = '重连次数已达上限';
      notifyListeners();
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(seconds: 2 * (_retryCount + 1)),
      () {
        _retryCount++;
        if (_currentServer != null) {
          connect(_currentServer!);
        }
      },
    );
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _currentServer = null;
    _status = ConnectionStatus.disconnected;
    _errorMessage = null;
    notifyListeners();
  }

  void sendMessage(MouseControlMessage message) {
    if (_socket == null || !isConnected) return;
    try {
      _socket!.write('${message.toJsonString()}\n');
    } catch (e) {
      debugPrint('Send message error: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
