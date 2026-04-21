import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class PaymentProvider extends ChangeNotifier {
  final ApiService _apiService;

  Order? _currentOrder;
  SubscriptionStatus? _subscriptionStatus;
  bool _isLoading = false;
  bool _isPolling = false;
  String? _error;
  Timer? _pollTimer;

  PaymentProvider({
    required ApiService apiService,
  }) : _apiService = apiService;

  Order? get currentOrder => _currentOrder;
  SubscriptionStatus? get subscriptionStatus => _subscriptionStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<Order?> createOrder(int deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.createOrder(deviceId);
      if (result.success && result.data != null) {
        _currentOrder = result.data;
        _isLoading = false;
        notifyListeners();
        return _currentOrder;
      } else {
        _error = result.msg;
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = '创建订单失败: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<SubscriptionStatus?> checkSubscriptionStatus(int deviceId) async {
    try {
      final result = await _apiService.getSubscriptionStatus(deviceId);
      if (result.success && result.data != null) {
        _subscriptionStatus = result.data;
        notifyListeners();
        return _subscriptionStatus;
      }
    } catch (e) {
      debugPrint('Check subscription status error: $e');
    }
    return null;
  }

  void startPolling(int deviceId, {Duration interval = const Duration(seconds: 3)}) {
    if (_isPolling) return;
    _isPolling = true;
    
    _pollTimer = Timer.periodic(interval, (timer) async {
      final status = await checkSubscriptionStatus(deviceId);
      if (status != null && status.subscribed) {
        stopPolling();
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  void clearOrder() {
    _currentOrder = null;
    _subscriptionStatus = null;
    stopPolling();
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
