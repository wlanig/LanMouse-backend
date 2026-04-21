import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class DeviceProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  List<Device> _devices = [];
  Device? _currentDevice;
  bool _isLoading = false;
  String? _error;

  DeviceProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  List<Device> get devices => _devices;
  Device? get currentDevice => _currentDevice;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init() async {
    _currentDevice = await _storageService.getCurrentDevice();
    notifyListeners();
  }

  Future<bool> registerDevice({
    required String imei1,
    String? imei2,
    required String deviceName,
    required String deviceModel,
    required String osType,
    required String osVersion,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.registerDevice(
        imei1: imei1,
        imei2: imei2,
        deviceName: deviceName,
        deviceModel: deviceModel,
        osType: osType,
        osVersion: osVersion,
      );

      if (result.success && result.data != null) {
        _currentDevice = result.data;
        await _storageService.saveCurrentDevice(result.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = result.msg;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '设备注册失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> loadDevices() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.getDeviceList();
      if (result.success && result.data != null) {
        _devices = result.data!;
      } else {
        _error = result.msg;
      }
    } catch (e) {
      _error = '获取设备列表失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<SubscriptionStatus?> getSubscriptionStatus(int deviceId) async {
    try {
      final result = await _apiService.getSubscriptionStatus(deviceId);
      if (result.success && result.data != null) {
        return result.data;
      }
    } catch (e) {
      debugPrint('Get subscription status error: $e');
    }
    return null;
  }
}
