/// User info data model
class UserInfo {
  final String userID;
  final String nickname;
  final String faceURL;
  final int gender; // 0=unknown, 1=male, 2=female
  final String phoneNumber;
  final String email;
  final int createTime;
  /// 二开：0=普通用户 1=用户端管理员，用于 IP 查看权限
  final int appRole;
  /// 二开：是否为推荐系统管理员（在 user_admins 集合中）
  final bool isUserAdmin;

  UserInfo({
    required this.userID,
    this.nickname = '',
    this.faceURL = '',
    this.gender = 0,
    this.phoneNumber = '',
    this.email = '',
    this.createTime = 0,
    this.appRole = 0,
    this.isUserAdmin = false,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userID: json['userID'] ?? '',
      nickname: json['nickname'] ?? '',
      faceURL: json['faceURL'] ?? '',
      gender: json['gender'] ?? 0,
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'] ?? '',
      createTime: json['createTime'] ?? 0,
      appRole: json['appRole'] ?? 0,
      isUserAdmin: json['isUserAdmin'] == true,
    );
  }

  /// 是否为用户端管理员（可查看他人 IP）
  bool get isAppAdmin => appRole >= 1;

  /// 是否为推荐系统管理员（可查看被推荐用户 IP）
  bool get canViewIP => appRole >= 1 || isUserAdmin;

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
      };
}
