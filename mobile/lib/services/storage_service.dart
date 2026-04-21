import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  static StorageService get instance => _instance;
  StorageService._internal();

  static const String _keyUser = 'user';
  static const String _keyToken = 'token';
  static const String _keyDevices = 'devices';
  static const String _keyConnectionHistory = 'connection_history';
  static const String _keyCurrentDevice = 'current_device';

  late SharedPreferences _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // 用户信息
  Future<void> saveUser(User user) async {
    await init();
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
    if (user.token != null) {
      await _prefs.setString(_keyToken, user.token!);
    }
  }

  Future<User?> getUser() async {
    await init();
    final userJson = _prefs.getString(_keyUser);
    if (userJson == null) return null;
    try {
      return User.fromJson(jsonDecode(userJson));
    } catch (e) {
      return null;
    }
  }

  Future<String?> getToken() async {
    await init();
    return _prefs.getString(_keyToken);
  }

  Future<void> clearUser() async {
    await init();
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyToken);
  }

  // 连接历史
  Future<void> saveConnectionHistory(List<PcServer> history) async {
    await init();
    final jsonList = history.map((s) => s.toJson()).toList();
    await _prefs.setString(_keyConnectionHistory, jsonEncode(jsonList));
  }

  Future<List<PcServer>> getConnectionHistory() async {
    await init();
    final jsonStr = _prefs.getString(_keyConnectionHistory);
    if (jsonStr == null) return [];
    try {
      final jsonList = jsonDecode(jsonStr) as List;
      return jsonList.map((j) => PcServer.fromJson(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addToConnectionHistory(PcServer server) async {
    final history = await getConnectionHistory();
    // 移除相同IP的历史记录
    history.removeWhere((s) => s.ip == server.ip);
    // 添加到最前面
    history.insert(0, server);
    // 最多保留10条
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    await saveConnectionHistory(history);
  }

  // 本地设备
  Future<void> saveCurrentDevice(Device device) async {
    await init();
    await _prefs.setString(_keyCurrentDevice, jsonEncode(device.toJson()));
  }

  Future<Device?> getCurrentDevice() async {
    await init();
    final jsonStr = _prefs.getString(_keyCurrentDevice);
    if (jsonStr == null) return null;
    try {
      return Device.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await init();
    await _prefs.clear();
  }
}
