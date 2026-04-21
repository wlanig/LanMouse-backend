/// 身份证号验证工具类
class IdCardValidator {
  // 地区码映射表（部分）
  static const Map<String, String> _areaCodes = {
    '11': '北京市',
    '12': '天津市',
    '13': '河北省',
    '14': '山西省',
    '15': '内蒙古自治区',
    '21': '辽宁省',
    '22': '吉林省',
    '23': '黑龙江省',
    '31': '上海市',
    '32': '江苏省',
    '33': '浙江省',
    '34': '安徽省',
    '35': '福建省',
    '36': '江西省',
    '37': '山东省',
    '41': '河南省',
    '42': '湖北省',
    '43': '湖南省',
    '44': '广东省',
    '45': '广西壮族自治区',
    '46': '海南省',
    '50': '重庆市',
    '51': '四川省',
    '52': '贵州省',
    '53': '云南省',
    '54': '西藏自治区',
    '61': '陕西省',
    '62': '甘肃省',
    '63': '青海省',
    '64': '宁夏回族自治区',
    '65': '新疆维吾尔自治区',
    '71': '台湾省',
    '81': '香港特别行政区',
    '82': '澳门特别行政区',
  };

  // 权重因子
  static const List<int> _weightFactors = [
    7, 9, 10, 5, 8, 4, 2, 1, 6, 3, 7, 9, 10, 5, 8, 4, 2
  ];

  // 校验码映射
  static const List<String> _checkCodes = [
    '1', '0', 'X', '9', '8', '7', '6', '5', '4', '3', '2'
  ];

  /// 验证身份证号是否合法
  static ValidationResult validate(String idCard) {
    if (idCard.isEmpty) {
      return ValidationResult(
        isValid: false,
        error: '身份证号不能为空',
      );
    }

    // 去除空格
    idCard = idCard.trim();

    // 长度检查
    if (idCard.length != 18) {
      return ValidationResult(
        isValid: false,
        error: '身份证号必须为18位',
      );
    }

    // 格式检查：前17位为数字，第18位为数字或X
    final regex = RegExp(r'^\d{17}[\dXx]$');
    if (!regex.hasMatch(idCard)) {
      return ValidationResult(
        isValid: false,
        error: '身份证号格式不正确',
      );
    }

    // 地区码检查
    final areaCode = idCard.substring(0, 2);
    if (!_areaCodes.containsKey(areaCode)) {
      return ValidationResult(
        isValid: false,
        error: '身份证号地区码无效',
      );
    }

    // 出生日期检查
    final birthDateStr = idCard.substring(6, 14);
    if (!_isValidDate(birthDateStr)) {
      return ValidationResult(
        isValid: false,
        error: '身份证号出生日期无效',
      );
    }

    // 校验码检查
    final checkCode = _calculateCheckCode(idCard);
    final lastChar = idCard[17].toUpperCase();
    if (lastChar != checkCode) {
      return ValidationResult(
        isValid: false,
        error: '身份证号校验码错误',
      );
    }

    return ValidationResult(
      isValid: true,
      area: _areaCodes[areaCode],
      birthDate: _formatBirthDate(birthDateStr),
    );
  }

  /// 计算校验码
  static String _calculateCheckCode(String idCard) {
    int sum = 0;
    for (int i = 0; i < 17; i++) {
      sum += int.parse(idCard[i]) * _weightFactors[i];
    }
    return _checkCodes[sum % 11];
  }

  /// 验证日期是否有效
  static bool _isValidDate(String dateStr) {
    try {
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));

      if (year < 1900 || year > DateTime.now().year) return false;
      if (month < 1 || month > 12) return false;

      final daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
      // 闰年判断
      if ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0) {
        daysInMonth[1] = 29;
      }

      if (day < 1 || day > daysInMonth[month - 1]) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 格式化出生日期
  static String _formatBirthDate(String dateStr) {
    return '${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}';
  }

  /// 脱敏身份证号（只显示前3位和后4位）
  static String mask(String idCard) {
    if (idCard.length != 18) return idCard;
    return '${idCard.substring(0, 3)}***********${idCard.substring(14)}';
  }

  /// 获取年龄
  static int? getAge(String idCard) {
    final result = validate(idCard);
    if (!result.isValid || result.birthDate == null) return null;

    final birthDate = DateTime.tryParse(result.birthDate!);
    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// 获取性别（0=女，1=男）
  static int? getGender(String idCard) {
    if (idCard.length != 18) return null;
    final genderDigit = int.tryParse(idCard[16]);
    if (genderDigit == null) return null;
    return genderDigit % 2; // 奇数为男，偶数为女
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;
  final String? area;
  final String? birthDate;

  ValidationResult({
    required this.isValid,
    this.error,
    this.area,
    this.birthDate,
  });
}
