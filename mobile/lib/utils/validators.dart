class Validators {
  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(phone);
  }

  static bool isValidIdCard(String idCard) {
    if (idCard.length != 18 && idCard.length != 15) return false;
    final regex = RegExp(r'^\d{17}[\dXx]$');
    return regex.hasMatch(idCard);
  }

  static bool isValidPassword(String password) {
    return password.length >= 6;
  }

  static bool isValidIp(String ip) {
    final regex = RegExp(
      r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$',
    );
    return regex.hasMatch(ip);
  }
}

class IpValidator {
  static bool isValid(String ip) {
    return Validators.isValidIp(ip);
  }
}
