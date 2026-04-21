import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/models.dart';

class ApiResponse<T> {
  final int code;
  final String msg;
  final T? data;

  ApiResponse({
    required this.code,
    required this.msg,
    this.data,
  });

  bool get success => code == 0;
}

class ApiService {
  static const String _baseUrl = AppConfig.apiBaseUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<ApiResponse<Map<String, dynamic>>> _handleResponse(
      http.Response response) async {
    try {
      final body = jsonDecode(response.body);
      return ApiResponse(
        code: body['code'] ?? -1,
        msg: body['msg'] ?? '未知错误',
        data: body['data'],
      );
    } catch (e) {
      return ApiResponse(
        code: -1,
        msg: '解析响应失败: $e',
      );
    }
  }

  // 注册
  Future<ApiResponse<User>> register({
    required String phone,
    required String password,
    required String name,
    required String idCard,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'password': password,
          'name': name,
          'idCard': idCard,
        }),
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        final user = User.fromJson(result.data!);
        return ApiResponse(code: 0, msg: result.msg, data: user);
      }
      return ApiResponse(code: result.code, msg: result.msg);
    } catch (e) {
      return ApiResponse(code: -1, msg: '注册失败: $e');
    }
  }

  // 登录
  Future<ApiResponse<User>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'password': password,
        }),
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        final user = User.fromJson(result.data!);
        return ApiResponse(code: 0, msg: result.msg, data: user);
      }
      return ApiResponse(code: result.code, msg: result.msg);
    } catch (e) {
      return ApiResponse(code: -1, msg: '登录失败: $e');
    }
  }

  // 设备注册
  Future<ApiResponse<Device>> registerDevice({
    required String imei1,
    String? imei2,
    required String deviceName,
    required String deviceModel,
    required String osType,
    required String osVersion,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/device/register'),
        headers: _headers,
        body: jsonEncode({
          'imei1': imei1,
          'imei2': imei2,
          'deviceName': deviceName,
          'deviceModel': deviceModel,
          'osType': osType,
          'osVersion': osVersion,
        }),
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        final device = Device.fromJson(result.data!);
        return ApiResponse(code: 0, msg: result.msg, data: device);
      }
      return ApiResponse(code: result.code, msg: result.msg);
    } catch (e) {
      return ApiResponse(code: -1, msg: '设备注册失败: $e');
    }
  }

  // 获取设备列表
  Future<ApiResponse<List<Device>>> getDeviceList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/device/list'),
        headers: _headers,
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        final list = (result.data!['devices'] as List?)
                ?.map((e) => Device.fromJson(e))
                .toList() ??
            [];
        return ApiResponse(code: 0, msg: result.msg, data: list);
      }
      return ApiResponse(code: result.code, msg: result.msg);
    } catch (e) {
      return ApiResponse(code: -1, msg: '获取设备列表失败: $e');
    }
  }

  // 创建设备订单
  Future<ApiResponse<Order>> createOrder(int deviceId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/subscription/create-order'),
        headers: _headers,
        body: jsonEncode({'deviceId': deviceId}),
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        final order = Order.fromJson(result.data!);
        return ApiResponse(code: 0, msg: result.msg, data: order);
      }
      return ApiResponse(code: result.code, msg: result.msg);
    } catch (e) {
      return ApiResponse(code: -1, msg: '创建订单失败: $e');
    }
  }

  // 获取订阅状态
  Future<ApiResponse<SubscriptionStatus>> getSubscriptionStatus(
      int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/subscription/status/$deviceId'),
        headers: _headers,
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        final status = SubscriptionStatus.fromJson(result.data!);
        return ApiResponse(code: 0, msg: result.msg, data: status);
      }
      return ApiResponse(code: result.code, msg: result.msg);
    } catch (e) {
      return ApiResponse(code: -1, msg: '获取订阅状态失败: $e');
    }
  }
}
