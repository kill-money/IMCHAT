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
      };
}
