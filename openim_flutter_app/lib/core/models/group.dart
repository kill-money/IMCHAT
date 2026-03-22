/// Group data model
class Group {
  final String groupID;
  final String groupName;
  final String faceURL;
  final String introduction;
  final String announcement;
  final String ownerUserID;
  final int memberCount;
  final int maxMemberCount; // 群人数上限
  final int createdTime;
  final int groupType; // 0=普通群, 1=超级群
  final bool isMuted; // 全员禁言
  final String pinnedMsgID; // 群置顶消息 ID

  /// 是否官方群（由服务端返回，客户端只读）
  final bool isOfficialGroup;

  const Group({
    required this.groupID,
    required this.groupName,
    this.faceURL = '',
    this.introduction = '',
    this.announcement = '',
    this.ownerUserID = '',
    this.memberCount = 0,
    this.maxMemberCount = 500,
    this.createdTime = 0,
    this.groupType = 0,
    this.isMuted = false,
    this.pinnedMsgID = '',
    this.isOfficialGroup = false,
  });

  factory Group.fromJson(Map<String, dynamic> j) => Group(
        groupID: j['groupID'] as String? ?? '',
        groupName: j['groupName'] as String? ?? '',
        faceURL: j['faceURL'] as String? ?? '',
        introduction: j['introduction'] as String? ?? '',
        announcement: j['announcement'] as String? ?? '',
        ownerUserID: j['ownerUserID'] as String? ?? '',
        memberCount: (j['memberCount'] ?? 0) as int,
        maxMemberCount: (j['maxMemberCount'] ?? 500) as int,
        createdTime: (j['createdTime'] ?? 0) as int,
        groupType: (j['groupType'] ?? 0) as int,
        isMuted: (j['groupMuted'] ?? false) as bool,
        pinnedMsgID: j['pinnedMsgID'] as String? ?? '',
        isOfficialGroup: (j['isOfficialGroup'] ?? false) as bool,
      );

  Map<String, dynamic> toJson() => {
        'groupID': groupID,
        'groupName': groupName,
        'faceURL': faceURL,
        'introduction': introduction,
        'announcement': announcement,
        'ownerUserID': ownerUserID,
        'memberCount': memberCount,
        'maxMemberCount': maxMemberCount,
        'createdTime': createdTime,
        'groupType': groupType,
        'groupMuted': isMuted,
        'pinnedMsgID': pinnedMsgID,
        'isOfficialGroup': isOfficialGroup,
      };

  bool get isFull => memberCount >= maxMemberCount;

  Group copyWith({
    String? groupName,
    String? faceURL,
    String? introduction,
    String? announcement,
    bool? isMuted,
    bool? isOfficialGroup,
    int? maxMemberCount,
    String? pinnedMsgID,
  }) =>
      Group(
        groupID: groupID,
        groupName: groupName ?? this.groupName,
        faceURL: faceURL ?? this.faceURL,
        introduction: introduction ?? this.introduction,
        announcement: announcement ?? this.announcement,
        ownerUserID: ownerUserID,
        memberCount: memberCount,
        maxMemberCount: maxMemberCount ?? this.maxMemberCount,
        createdTime: createdTime,
        groupType: groupType,
        isMuted: isMuted ?? this.isMuted,
        pinnedMsgID: pinnedMsgID ?? this.pinnedMsgID,
        isOfficialGroup: isOfficialGroup ?? this.isOfficialGroup,
      );
}
