/// Message data model + OpenIM content type definitions
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';

// ─── ContentType 枚举常量 ──────────────────────────────────────────────────────
class MessageContentType {
  static const int text = 101; // 文本
  static const int image = 102; // 图片
  static const int voice = 103; // 语音
  static const int video = 104; // 视频
  static const int file = 105; // 文件
  static const int atText = 106; // @消息
  static const int location = 109; // 位置
  static const int custom = 110; // 自定义
  static const int merge = 111; // 合并转发
  static const int sticker = 112; // 表情包 / Sticker
  static const int gif = 113; // GIF 动图
  static const int quote = 114; // 引用回复
  static const int reaction = 116; // 消息 Reaction（表情回应）
  static const int revoke = 2101; // 撤回通知
  static const int notification = 1501; // 系统通知
}

// ─── Typed content models ────────────────────────────────────────────────────

/// 图片消息内容（OpenIM 结构支持 sourcePicture / bigPicture）
class ImageContent {
  final String url;
  final int width;
  final int height;

  const ImageContent({required this.url, this.width = 0, this.height = 0});

  factory ImageContent.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> pick(String key) =>
        (j[key] as Map<String, dynamic>?) ?? {};
    final big = pick('bigPicture');
    final snap = pick('snapshotPicture');
    final src = pick('sourcePicture');
    final url =
        (big['url'] ?? snap['url'] ?? src['url'] ?? j['url'] ?? '') as String;
    return ImageContent(
      url: url,
      width: (big['width'] ?? snap['width'] ?? j['width'] ?? 0) as int,
      height: (big['height'] ?? snap['height'] ?? j['height'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() {
    final pic = {
      'url': url,
      'width': width,
      'height': height,
      'type': 'jpg',
      'size': 0
    };
    return {'bigPicture': pic, 'snapshotPicture': pic, 'sourcePicture': pic};
  }
}

/// 语音消息内容
class VoiceContent {
  final String url;
  final int duration; // seconds
  final int dataSize; // bytes

  const VoiceContent({required this.url, this.duration = 0, this.dataSize = 0});

  factory VoiceContent.fromJson(Map<String, dynamic> j) => VoiceContent(
        url: j['sourceUrl'] as String? ?? '',
        duration: (j['duration'] ?? 0) as int,
        dataSize: (j['dataSize'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'sourceUrl': url,
        'duration': duration,
        'dataSize': dataSize,
        'soundPath': '',
      };
}

/// 视频消息内容
class VideoContent {
  final String videoUrl;
  final String snapshotUrl;
  final int duration; // seconds
  final int videoSize; // bytes

  const VideoContent({
    required this.videoUrl,
    this.snapshotUrl = '',
    this.duration = 0,
    this.videoSize = 0,
  });

  factory VideoContent.fromJson(Map<String, dynamic> j) => VideoContent(
        videoUrl: j['videoUrl'] as String? ?? '',
        snapshotUrl: j['snapshotUrl'] as String? ?? '',
        duration: (j['duration'] ?? 0) as int,
        videoSize: (j['videoSize'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'videoUrl': videoUrl,
        'snapshotUrl': snapshotUrl,
        'duration': duration,
        'videoSize': videoSize,
        'videoType': 'mp4',
        'videoPath': '',
      };
}

/// 文件消息内容
class FileContent {
  final String url;
  final String fileName;
  final int fileSize; // bytes

  const FileContent(
      {required this.url, required this.fileName, this.fileSize = 0});

  factory FileContent.fromJson(Map<String, dynamic> j) => FileContent(
        url: j['url'] as String? ?? '',
        fileName: j['fileName'] as String? ?? j['filePath'] as String? ?? '',
        fileSize: (j['fileSize'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() =>
      {'url': url, 'fileName': fileName, 'fileSize': fileSize, 'filePath': ''};
}

/// 位置消息内容
class LocationContent {
  final double latitude;
  final double longitude;
  final String desc;

  const LocationContent({
    required this.latitude,
    required this.longitude,
    this.desc = '',
  });

  factory LocationContent.fromJson(Map<String, dynamic> j) => LocationContent(
        latitude: (j['latitude'] ?? 0.0).toDouble(),
        longitude: (j['longitude'] ?? 0.0).toDouble(),
        desc: j['desc'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'latitude': latitude, 'longitude': longitude, 'desc': desc};
}

/// 引用/回复消息内容
class QuoteContent {
  final String text;
  final Message? quoteMessage;

  const QuoteContent({required this.text, this.quoteMessage});

  factory QuoteContent.fromJson(Map<String, dynamic> j) => QuoteContent(
        text: j['text'] as String? ?? '',
        quoteMessage: j['quoteMessage'] != null
            ? Message.fromJson(j['quoteMessage'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'quoteMessage': quoteMessage?.toJson(),
      };
}

/// 表情包 / Sticker 内容
class StickerContent {
  final String url;
  final String name;

  const StickerContent({required this.url, this.name = ''});

  factory StickerContent.fromJson(Map<String, dynamic> j) => StickerContent(
        url: j['url'] as String? ?? '',
        name: j['name'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'url': url, 'name': name};
}

/// GIF 动图内容
class GifContent {
  final String url;
  final int width;
  final int height;

  const GifContent({required this.url, this.width = 180, this.height = 120});

  factory GifContent.fromJson(Map<String, dynamic> j) => GifContent(
        url: j['url'] as String? ?? '',
        width: (j['width'] ?? 180) as int,
        height: (j['height'] ?? 120) as int,
      );

  Map<String, dynamic> toJson() =>
      {'url': url, 'width': width, 'height': height};
}

/// Reaction（表情回应）内容 — 附加在某条已有消息上
class ReactionContent {
  /// 被回应的原消息 clientMsgID
  final String reactToMsgID;

  /// 表情符号，如 "👍" "❤️" "😂"
  final String emoji;

  const ReactionContent({required this.reactToMsgID, required this.emoji});

  factory ReactionContent.fromJson(Map<String, dynamic> j) => ReactionContent(
        reactToMsgID: j['reactToMsgID'] as String? ?? '',
        emoji: j['emoji'] as String? ?? '',
      );

  Map<String, dynamic> toJson() =>
      {'reactToMsgID': reactToMsgID, 'emoji': emoji};
}

/// 合并转发消息内容 — 将多条消息打包为一条转发
class MergeContent {
  final String title;
  final List<String> abstractList; // 摘要行列表（如 "张三: 你好"）
  final List<Message> multiMessage; // 被合并的完整消息

  const MergeContent({
    required this.title,
    this.abstractList = const [],
    this.multiMessage = const [],
  });

  factory MergeContent.fromJson(Map<String, dynamic> j) => MergeContent(
        title: j['title'] as String? ?? '聊天记录',
        abstractList:
            (j['abstractList'] as List?)?.map((e) => e.toString()).toList() ??
                [],
        multiMessage: (j['multiMessage'] as List?)
                ?.map((e) => Message.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'abstractList': abstractList,
        'multiMessage': multiMessage.map((m) => m.toJson()).toList(),
      };
}

// ─── Message ─────────────────────────────────────────────────────────────────

class Message {
  final String clientMsgID;
  final String serverMsgID;
  final String sendID;
  final String recvID;
  final String groupID;
  final int senderPlatformID;
  final String senderNickname;
  final String senderFaceURL;
  final int sessionType; // 1=单聊, 3=群聊
  final int contentType;
  final dynamic content;
  final int sendTime;
  final int createTime;
  final int status; // 1=发送中, 2=成功, 3=失败
  final int seq;
  final bool isRead;
  final bool isEdited; // 消息是否被编辑过

  const Message({
    required this.clientMsgID,
    this.serverMsgID = '',
    required this.sendID,
    this.recvID = '',
    this.groupID = '',
    this.senderPlatformID = 1,
    this.senderNickname = '',
    this.senderFaceURL = '',
    this.sessionType = 1,
    this.contentType = MessageContentType.text,
    this.content,
    this.sendTime = 0,
    this.createTime = 0,
    this.status = 1,
    this.seq = 0,
    this.isRead = false,
    this.isEdited = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        clientMsgID: json['clientMsgID'] as String? ?? '',
        serverMsgID: json['serverMsgID'] as String? ?? '',
        sendID: json['sendID'] as String? ?? '',
        recvID: json['recvID'] as String? ?? '',
        groupID: json['groupID'] as String? ?? '',
        senderPlatformID: (json['senderPlatformID'] ?? 1) as int,
        senderNickname: json['senderNickname'] as String? ?? '',
        senderFaceURL: json['senderFaceURL'] as String? ?? '',
        sessionType: (json['sessionType'] ?? 1) as int,
        contentType: (json['contentType'] ?? MessageContentType.text) as int,
        content: json['content'],
        sendTime: (json['sendTime'] ?? 0) as int,
        createTime: (json['createTime'] ?? 0) as int,
        status: (json['status'] ?? 1) as int,
        seq: (json['seq'] ?? 0) as int,
        isRead: json['isRead'] as bool? ?? false,
        isEdited: json['isEdited'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'clientMsgID': clientMsgID,
        'serverMsgID': serverMsgID,
        'sendID': sendID,
        'recvID': recvID,
        'groupID': groupID,
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
        'isRead': isRead,
        'isEdited': isEdited,
      };

  // ─── Type helpers ─────────────────────────────────────────────────────────

  bool get isText => contentType == MessageContentType.text;
  bool get isImage => contentType == MessageContentType.image;
  bool get isVoice => contentType == MessageContentType.voice;
  bool get isVideo => contentType == MessageContentType.video;
  bool get isFile => contentType == MessageContentType.file;
  bool get isLocation => contentType == MessageContentType.location;
  bool get isMerge => contentType == MessageContentType.merge;
  bool get isQuote => contentType == MessageContentType.quote;
  bool get isSticker => contentType == MessageContentType.sticker;
  bool get isGif => contentType == MessageContentType.gif;
  bool get isReaction => contentType == MessageContentType.reaction;
  bool get isRevoke => contentType == MessageContentType.revoke;

  // ─── Typed content accessors ──────────────────────────────────────────────

  Map<String, dynamic> get _contentMap {
    if (content is Map) return (content as Map).cast<String, dynamic>();
    if (content is String && (content as String).isNotEmpty) {
      try {
        final decoded = json.decode(content as String);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (e) {
        debugPrint('消息 content JSON 解析失败: $e');
      }
    }
    return <String, dynamic>{};
  }

  String get textContent {
    if (isText) {
      if (content is Map) return (_contentMap['content'] ?? '') as String;
      if (content is String) {
        final s = content as String;
        // 服务端返回的 content 可能是 JSON 字符串 {"content":"hello"}
        try {
          final decoded = Map<String, dynamic>.from(json.decode(s) as Map);
          return (decoded['content'] ?? s) as String;
        } catch (_) {
          return s;
        }
      }
    }
    return '';
  }

  ImageContent? get imageContent =>
      isImage ? ImageContent.fromJson(_contentMap) : null;
  VoiceContent? get voiceContent =>
      isVoice ? VoiceContent.fromJson(_contentMap) : null;
  VideoContent? get videoContent =>
      isVideo ? VideoContent.fromJson(_contentMap) : null;
  FileContent? get fileContent =>
      isFile ? FileContent.fromJson(_contentMap) : null;
  LocationContent? get locationContent =>
      isLocation ? LocationContent.fromJson(_contentMap) : null;
  QuoteContent? get quoteContent =>
      isQuote ? QuoteContent.fromJson(_contentMap) : null;
  StickerContent? get stickerContent =>
      isSticker ? StickerContent.fromJson(_contentMap) : null;
  GifContent? get gifContent => isGif ? GifContent.fromJson(_contentMap) : null;
  ReactionContent? get reactionContent =>
      isReaction ? ReactionContent.fromJson(_contentMap) : null;

  MergeContent? get mergeContent =>
      isMerge ? MergeContent.fromJson(_contentMap) : null;

  /// 会话列表副标题预览
  String get previewText {
    if (isText) return textContent;
    if (isImage) return '[图片]';
    if (isVoice) return '[语音]';
    if (isVideo) return '[视频]';
    if (isFile) return '[文件] ${fileContent?.fileName ?? ''}';
    if (isLocation) return '[位置]';
    if (isMerge) return '[合并转发] ${mergeContent?.title ?? '聊天记录'}';
    if (isQuote) return '[回复] ${quoteContent?.text ?? ''}';
    if (isSticker) return '[表情包]';
    if (isGif) return '[GIF]';
    if (isReaction) return '';
    if (isRevoke) return '消息已被撤回';
    return '[消息]';
  }

  /// copyWith — 更新部分字段生成新的 Message 实例
  Message copyWith({
    String? clientMsgID,
    String? serverMsgID,
    String? sendID,
    String? recvID,
    String? groupID,
    int? senderPlatformID,
    String? senderNickname,
    String? senderFaceURL,
    int? sessionType,
    int? contentType,
    dynamic content,
    int? sendTime,
    int? createTime,
    int? status,
    int? seq,
    bool? isRead,
    bool? isEdited,
  }) {
    return Message(
      clientMsgID: clientMsgID ?? this.clientMsgID,
      serverMsgID: serverMsgID ?? this.serverMsgID,
      sendID: sendID ?? this.sendID,
      recvID: recvID ?? this.recvID,
      groupID: groupID ?? this.groupID,
      senderPlatformID: senderPlatformID ?? this.senderPlatformID,
      senderNickname: senderNickname ?? this.senderNickname,
      senderFaceURL: senderFaceURL ?? this.senderFaceURL,
      sessionType: sessionType ?? this.sessionType,
      contentType: contentType ?? this.contentType,
      content: content ?? this.content,
      sendTime: sendTime ?? this.sendTime,
      createTime: createTime ?? this.createTime,
      status: status ?? this.status,
      seq: seq ?? this.seq,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}
