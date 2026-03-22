/// 用户在线状态数据模型 — Online Status + Last Seen + 隐私策略
library;

enum LastSeenPrivacy { everyone, contacts, nobody }

extension LastSeenPrivacyX on LastSeenPrivacy {
  String get apiValue {
    switch (this) {
      case LastSeenPrivacy.everyone:
        return 'everyone';
      case LastSeenPrivacy.contacts:
        return 'contacts';
      case LastSeenPrivacy.nobody:
        return 'nobody';
    }
  }

  static LastSeenPrivacy fromApi(String? val) {
    switch (val) {
      case 'contacts':
        return LastSeenPrivacy.contacts;
      case 'nobody':
        return LastSeenPrivacy.nobody;
      default:
        return LastSeenPrivacy.everyone;
    }
  }
}

class UserStatus {
  final String userID;
  final bool isOnline;

  /// Unix 时间戳（秒）。null 表示不可见（隐私设置 nobody 或从未上线）。
  final int? lastSeen;

  const UserStatus({
    required this.userID,
    required this.isOnline,
    this.lastSeen,
  });

  factory UserStatus.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'offline';
    final rawTs = json['lastSeen'];
    int? ts;
    if (rawTs != null && rawTs != 0) {
      ts = (rawTs as num).toInt();
      // 服务端可能返回毫秒；统一转为秒
      if (ts > 1e11.toInt()) ts = (ts / 1000).round();
    }
    return UserStatus(
      userID: json['userID']?.toString() ?? '',
      isOnline: statusStr == 'online',
      lastSeen: ts,
    );
  }

  /// 将 lastSeen 时间戳直接转换为 DateTime，避免 UI 层重复转换。
  DateTime? get lastSeenTime => lastSeen == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(lastSeen! * 1000);

  /// 格式化最后上线时间（Telegram 风格，中文）
  String get lastSeenText {
    if (isOnline) return '在线';
    final dt = lastSeenTime;
    if (dt == null) return '很久以前';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return '刚刚在线';
    if (diff.inHours < 1) return '最近在线';
    if (diff.inHours < 24) return '今天在线';
    if (diff.inDays < 7) return '本周在线';
    return '很久未上线';
  }

  UserStatus copyWith({bool? isOnline, int? lastSeen}) {
    return UserStatus(
      userID: userID,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
