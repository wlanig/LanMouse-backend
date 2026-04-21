/// 手机号验证工具类
class PhoneValidator {
  // 中国大陆手机号正则（简单版）
  static final RegExp _phoneRegex = RegExp(r'^1[3-9]\d{9}$');

  static bool isValid(String phone) {
    if (phone.isEmpty) return false;
    return _phoneRegex.hasMatch(phone.trim());
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    if (!isValid(value)) {
      return '请输入正确的手机号';
    }
    return null;
  }
}

/// 密码验证工具类
class PasswordValidator {
  // 最少6位
  static bool isValid(String password) {
    return password.length >= 6;
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码至少6位';
    }
    return null;
  }
}

/// IP地址验证工具类
class IpValidator {
  static final RegExp _ipRegex = RegExp(
    r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
  );

  static bool isValid(String ip) {
    if (ip.isEmpty) return false;
    return _ipRegex.hasMatch(ip.trim());
  }

  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入IP地址';
    }
    if (!isValid(value)) {
      return '请输入正确的IP地址';
    }
    return null;
  }
}
