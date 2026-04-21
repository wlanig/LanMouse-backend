import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserProvider({
    required ApiService apiService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _storageService = storageService;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser?.isLoggedIn ?? false;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _storageService.getUser();
      if (user != null && user.token != null) {
        _currentUser = user;
        _apiService.setToken(user.token);
      }
    } catch (e) {
      _error = '初始化失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String phone,
    required String password,
    required String name,
    required String idCard,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.register(
        phone: phone,
        password: password,
        name: name,
        idCard: idCard,
      );

      if (result.success && result.data != null) {
        _currentUser = result.data;
        await _storageService.saveUser(result.data!);
        _apiService.setToken(result.data!.token);
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
      _error = '注册失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.login(
        phone: phone,
        password: password,
      );

      if (result.success && result.data != null) {
        _currentUser = result.data;
        await _storageService.saveUser(result.data!);
        _apiService.setToken(result.data!.token);
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
      _error = '登录失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    _apiService.setToken(null);
    await _storageService.clearUser();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
