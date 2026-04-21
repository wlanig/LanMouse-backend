class User {
  final int? userId;
  final String? phone;
  final String? name;
  final String? maskedIdCard;
  final String? token;
  final UserGroup? userGroup;

  User({
    this.userId,
    this.phone,
    this.name,
    this.maskedIdCard,
    this.token,
    this.userGroup,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      phone: json['phone'],
      name: json['name'],
      maskedIdCard: json['idCard'],
      token: json['token'],
      userGroup: json['userGroup'] != null
          ? UserGroup.fromJson(json['userGroup'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phone': phone,
      'name': name,
      'idCard': maskedIdCard,
      'token': token,
      'userGroup': userGroup?.toJson(),
    };
  }

  bool get isLoggedIn => token != null && token!.isNotEmpty;
}

class UserGroup {
  final int id;
  final String name;
  final double annualFee;

  UserGroup({
    required this.id,
    required this.name,
    required this.annualFee,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) {
    return UserGroup(
      id: json['id'],
      name: json['name'],
      annualFee: (json['annualFee'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'annualFee': annualFee,
    };
  }
}
