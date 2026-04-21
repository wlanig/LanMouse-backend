class Device {
  final int? deviceId;
  final String? imei1;
  final String? imei2;
  final String? deviceName;
  final String? deviceModel;
  final String? osType;
  final String? osVersion;
  final String? bindToken;
  final int? pcServicePort;
  final int status;
  final DateTime? lastActiveAt;
  final Subscription? subscription;

  Device({
    this.deviceId,
    this.imei1,
    this.imei2,
    this.deviceName,
    this.deviceModel,
    this.osType,
    this.osVersion,
    this.bindToken,
    this.pcServicePort,
    this.status = 0,
    this.lastActiveAt,
    this.subscription,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      deviceId: json['deviceId'],
      imei1: json['imei1'],
      imei2: json['imei2'],
      deviceName: json['deviceName'],
      deviceModel: json['deviceModel'],
      osType: json['osType'],
      osVersion: json['osVersion'],
      bindToken: json['bindToken'],
      pcServicePort: json['pcServicePort'],
      status: json['status'] ?? 0,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'])
          : null,
      subscription: json['subscription'] != null
          ? Subscription.fromJson(json['subscription'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'imei1': imei1,
      'imei2': imei2,
      'deviceName': deviceName,
      'deviceModel': deviceModel,
      'osType': osType,
      'osVersion': osVersion,
      'bindToken': bindToken,
      'pcServicePort': pcServicePort,
      'status': status,
      'lastActiveAt': lastActiveAt?.toIso8601String(),
      'subscription': subscription?.toJson(),
    };
  }

  String get statusText {
    switch (status) {
      case 0:
        return '未激活';
      case 1:
        return '正常';
      case 2:
        return '冻结';
      default:
        return '未知';
    }
  }
}

class Subscription {
  final DateTime? endDate;
  final String? status;

  Subscription({
    this.endDate,
    this.status,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'endDate': endDate?.toIso8601String(),
      'status': status,
    };
  }
}
