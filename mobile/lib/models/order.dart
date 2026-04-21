class Order {
  final String orderNo;
  final double amount;
  final double discountAmount;
  final String? qrCodeUrl;
  final int expireMinutes;
  final String? status;
  final DateTime? createdAt;

  Order({
    required this.orderNo,
    required this.amount,
    this.discountAmount = 0,
    this.qrCodeUrl,
    this.expireMinutes = 30,
    this.status,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderNo: json['orderNo'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      qrCodeUrl: json['qrCodeUrl'],
      expireMinutes: json['expireMinutes'] ?? 30,
      status: json['status'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderNo': orderNo,
      'amount': amount,
      'discountAmount': discountAmount,
      'qrCodeUrl': qrCodeUrl,
      'expireMinutes': expireMinutes,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  DateTime get expireTime {
    return (createdAt ?? DateTime.now())
        .add(Duration(minutes: expireMinutes));
  }

  bool get isExpired {
    return DateTime.now().isAfter(expireTime);
  }
}

class SubscriptionStatus {
  final bool subscribed;
  final DateTime? endDate;
  final int daysRemaining;
  final bool autoRenew;

  SubscriptionStatus({
    required this.subscribed,
    this.endDate,
    this.daysRemaining = 0,
    this.autoRenew = false,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscribed: json['subscribed'] ?? false,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      daysRemaining: json['daysRemaining'] ?? 0,
      autoRenew: json['autoRenew'] ?? false,
    );
  }

  String get statusText {
    if (!subscribed) return '未订阅';
    if (daysRemaining <= 0) return '已过期';
    if (daysRemaining <= 7) return '即将过期';
    return '订阅中';
  }
}
