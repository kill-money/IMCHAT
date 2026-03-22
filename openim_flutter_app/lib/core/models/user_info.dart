import 'dart:convert';

/// User info data model
class UserInfo {
  final String userID;
  final String nickname;
  final String faceURL;
  final int gender; // 0=unknown, 1=male, 2=female
  final String phoneNumber;
  final String email;
  final int createTime;

  /// 个性签名
  final String signature;

  /// 出生日期（秒级时间戳，0=未设置）
  final int birth;

  /// 0=普通用户 1=用户端管理员，用于 IP 查看权限
  final int appRole;

  /// 是否为推荐系统管理员（在 user_admins 集合中）
  final bool isUserAdmin;

  /// 0=普通账号 1=官方账号（显示金V标识）
  final int isOfficial;

  UserInfo({
    required this.userID,
    this.nickname = '',
    this.faceURL = '',
    this.gender = 0,
    this.phoneNumber = '',
    this.email = '',
    this.createTime = 0,
    this.signature = '',
    this.birth = 0,
    this.appRole = 0,
    this.isUserAdmin = false,
    this.isOfficial = 0,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    // 解析 ex 字段中的扩展信息（签名、出生日期）
    String signature = '';
    // birth 统一为秒级时间戳；若服务器返回毫秒级（>10位）则自动修正
    int birth = json['birth'] ?? 0;
    if (birth > 9999999999) birth = birth ~/ 1000;
    final ex = json['ex'];
    if (ex is String && ex.isNotEmpty) {
      try {
        final exMap = jsonDecode(ex) as Map<String, dynamic>;
        if (exMap['signature'] is String) signature = exMap['signature'];
        if (birth == 0 && exMap['birth'] is int) birth = exMap['birth'];
      } catch (_) {
        // ex 不是有效 JSON，忽略
      }
    }

    return UserInfo(
      userID: json['userID'] ?? '',
      nickname: json['nickname'] ?? '',
      faceURL: json['faceURL'] ?? '',
      gender: json['gender'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      createTime: json['createTime'] ?? 0,
      signature: signature,
      birth: birth,
      appRole: json['appRole'] ?? 0,
      isUserAdmin: json['isUserAdmin'] == true,
      isOfficial: json['isOfficial'] ?? 0,
    );
  }

  /// 是否为用户端管理员（可查看他人 IP）
  bool get isAppAdmin => appRole >= 1;

  /// 是否为推荐系统管理员（可查看被推荐用户 IP）
  bool get canViewIP => appRole >= 1 || isUserAdmin;

  /// 是否为官方账号（显示金V标识）
  bool get isOfficialAccount => isOfficial >= 1;

  /// 根据 birth 计算年龄，未设置返回 null
  int? get age {
    if (birth == 0) return null;
    final birthDate = DateTime.fromMillisecondsSinceEpoch(birth * 1000);
    final now = DateTime.now();
    int a = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      a--;
    }
    return a >= 0 ? a : null;
  }

  /// 性别文本
  String get genderText {
    switch (gender) {
      case 1:
        return '男';
      case 2:
        return '女';
      default:
        return '未设置';
    }
  }

  /// 将 signature 和 birth 编码到 ex 字段
  String get exJson {
    final map = <String, dynamic>{};
    if (signature.isNotEmpty) map['signature'] = signature;
    if (birth != 0) map['birth'] = birth;
    return map.isEmpty ? '' : jsonEncode(map);
  }

  Map<String, dynamic> toJson() => {
        'userID': userID,
        'nickname': nickname,
        'faceURL': faceURL,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'email': email,
        'createTime': createTime,
        'appRole': appRole,
        'isUserAdmin': isUserAdmin,
        'isOfficial': isOfficial,
      };
}
