/// Conversation data model
class Conversation {
  final String conversationID;
  final int conversationType; // 1=single, 3=group
  final String userID;
  final String groupID;
  final String showName;
  final String faceURL;
  final int recvMsgOpt;
  final int unreadCount;
  final String latestMsg;
  final int latestMsgSendTime;
  final bool isPinned;

  /// 官方认证角色：0=普通用户，1=官方/管理员
  final int appRole;

  /// 是否官方账号（单聊对方的 is_official 字段）
  final int isOfficialUser;

  /// 是否官方群（群会话时由服务端返回）
  final bool isOfficialGroup;

  Conversation({
    required this.conversationID,
    required this.conversationType,
    this.userID = '',
    this.groupID = '',
    this.showName = '',
    this.faceURL = '',
    this.recvMsgOpt = 0,
    this.unreadCount = 0,
    this.latestMsg = '',
    this.latestMsgSendTime = 0,
    this.isPinned = false,
    this.appRole = 0,
    this.isOfficialUser = 0,
    this.isOfficialGroup = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationID: json['conversationID'] ?? '',
      conversationType: json['conversationType'] ?? 1,
      userID: json['userID'] ?? '',
      groupID: json['groupID'] ?? '',
      showName: json['showName'] ?? '',
      faceURL: json['faceURL'] ?? '',
      recvMsgOpt: json['recvMsgOpt'] ?? 0,
      unreadCount: json['unreadCount'] ?? 0,
      latestMsg: json['latestMsg'] ?? '',
      latestMsgSendTime: json['latestMsgSendTime'] ?? 0,
      isPinned: json['isPinned'] ?? false,
      appRole: (json['appRole'] ?? 0) as int,
      isOfficialUser: (json['isOfficialUser'] ?? 0) as int,
      isOfficialGroup: (json['isOfficialGroup'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'conversationID': conversationID,
        'conversationType': conversationType,
        'userID': userID,
        'groupID': groupID,
        'showName': showName,
        'faceURL': faceURL,
        'recvMsgOpt': recvMsgOpt,
        'unreadCount': unreadCount,
        'latestMsg': latestMsg,
        'latestMsgSendTime': latestMsgSendTime,
        'isPinned': isPinned,
        'appRole': appRole,
        'isOfficialUser': isOfficialUser,
        'isOfficialGroup': isOfficialGroup,
      };

  /// recvMsgOpt: 0=正常, 1=不接收, 2=接收但不通知
  bool get isMuted => recvMsgOpt != 0;

  /// 会话对方是官方账号、管理员或群是官方群时为 true
  bool get isOfficialEntity =>
      appRole >= 1 || isOfficialUser >= 1 || isOfficialGroup;

  Conversation copyWith({
    bool? isPinned,
    int? recvMsgOpt,
    int? unreadCount,
    int? appRole,
    int? isOfficialUser,
    bool? isOfficialGroup,
    String? showName,
    String? faceURL,
  }) =>
      Conversation(
        conversationID: conversationID,
        conversationType: conversationType,
        userID: userID,
        groupID: groupID,
        showName: showName ?? this.showName,
        faceURL: faceURL ?? this.faceURL,
        recvMsgOpt: recvMsgOpt ?? this.recvMsgOpt,
        unreadCount: unreadCount ?? this.unreadCount,
        latestMsg: latestMsg,
        latestMsgSendTime: latestMsgSendTime,
        isPinned: isPinned ?? this.isPinned,
        appRole: appRole ?? this.appRole,
        isOfficialUser: isOfficialUser ?? this.isOfficialUser,
        isOfficialGroup: isOfficialGroup ?? this.isOfficialGroup,
      );
}
