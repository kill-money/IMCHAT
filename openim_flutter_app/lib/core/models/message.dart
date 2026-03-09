/// Message data model
class Message {
  final String clientMsgID;
  final String serverMsgID;
  final String sendID;
  final String recvID;
  final int senderPlatformID;
  final String senderNickname;
  final String senderFaceURL;
  final int sessionType; // 1=single, 3=group
  final int contentType; // 101=text, 102=image, 110=custom
  final dynamic content;
  final int sendTime;
  final int createTime;
  final int status; // 1=sending, 2=success, 3=failed
  final int seq;

  Message({
    required this.clientMsgID,
    this.serverMsgID = '',
    required this.sendID,
    this.recvID = '',
    this.senderPlatformID = 1,
    this.senderNickname = '',
    this.senderFaceURL = '',
    this.sessionType = 1,
    this.contentType = 101,
    this.content,
    this.sendTime = 0,
    this.createTime = 0,
    this.status = 1,
    this.seq = 0,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      clientMsgID: json['clientMsgID'] ?? '',
      serverMsgID: json['serverMsgID'] ?? '',
      sendID: json['sendID'] ?? '',
      recvID: json['recvID'] ?? '',
      senderPlatformID: json['senderPlatformID'] ?? 1,
      senderNickname: json['senderNickname'] ?? '',
      senderFaceURL: json['senderFaceURL'] ?? '',
      sessionType: json['sessionType'] ?? 1,
      contentType: json['contentType'] ?? 101,
      content: json['content'],
      sendTime: json['sendTime'] ?? 0,
      createTime: json['createTime'] ?? 0,
      status: json['status'] ?? 1,
      seq: json['seq'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'clientMsgID': clientMsgID,
        'serverMsgID': serverMsgID,
        'sendID': sendID,
        'recvID': recvID,
        'senderPlatformID': senderPlatformID,
        'senderNickname': senderNickname,
        'senderFaceURL': senderFaceURL,
        'sessionType': sessionType,
        'contentType': contentType,
        'content': content,
        'sendTime': sendTime,
        'createTime': createTime,
        'status': status,
        'seq': seq,
      };

  /// Whether this is a text message
  bool get isText => contentType == 101;

  /// Whether this is an image message
  bool get isImage => contentType == 102;

  /// Get text content for text messages
  String get textContent {
    if (content is Map) return (content as Map)['text'] ?? '';
    if (content is String) return content as String;
    return '';
  }
}
