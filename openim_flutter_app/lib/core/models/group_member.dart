/// Group member role levels (OpenIM standard)
class GroupMemberRole {
  static const int member = 20; // 普通成员
  static const int admin = 60; // 管理员
  static const int owner = 100; // 群主
}

/// Group member data model
class GroupMember {
  final String groupID;
  final String userID;
  final String nickname;
  final String faceURL;
  final int roleLevel;
  final int joinTime; // milliseconds
  final int muteEndTime; // seconds timestamp; 0 = not muted
  /// 二开字段：0=普通用户 1=官方账号；服务端扩展字段，无时默认 0
  final int appRole;

  /// 二开字段：0=普通 1=官方账号（金V标识）
  final int isOfficial;

  const GroupMember({
    required this.groupID,
    required this.userID,
    this.nickname = '',
    this.faceURL = '',
    this.roleLevel = GroupMemberRole.member,
    this.joinTime = 0,
    this.muteEndTime = 0,
    this.appRole = 0,
    this.isOfficial = 0,
  });

  factory GroupMember.fromJson(Map<String, dynamic> j) => GroupMember(
        groupID: j['groupID'] as String? ?? '',
        userID: j['userID'] as String? ?? '',
        nickname: j['nickname'] as String? ?? '',
        faceURL: j['faceURL'] as String? ?? '',
        roleLevel: (j['roleLevel'] ?? GroupMemberRole.member) as int,
        joinTime: (j['joinTime'] ?? 0) as int,
        muteEndTime: (j['muteEndTime'] ?? 0) as int,
        appRole: (j['appRole'] ?? 0) as int,
        isOfficial: (j['isOfficial'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'groupID': groupID,
        'userID': userID,
        'nickname': nickname,
        'faceURL': faceURL,
        'roleLevel': roleLevel,
        'joinTime': joinTime,
        'muteEndTime': muteEndTime,
      };

  bool get isMuted =>
      muteEndTime > DateTime.now().millisecondsSinceEpoch ~/ 1000;
  bool get isOwner => roleLevel == GroupMemberRole.owner;
  bool get isAdmin => roleLevel >= GroupMemberRole.admin;

  String get roleLabel {
    if (isOwner) return '群主';
    if (isAdmin) return '管理员';
    return '';
  }

  GroupMember copyWith({int? roleLevel, String? nickname, int? muteEndTime}) =>
      GroupMember(
        groupID: groupID,
        userID: userID,
        nickname: nickname ?? this.nickname,
        faceURL: faceURL,
        roleLevel: roleLevel ?? this.roleLevel,
        joinTime: joinTime,
        muteEndTime: muteEndTime ?? this.muteEndTime,
        appRole: appRole,
      );
}
