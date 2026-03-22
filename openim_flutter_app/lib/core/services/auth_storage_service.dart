// 登录 Token 持久化服务
// 使用 flutter_secure_storage 将敏感 Token 加密存储到平台安全容器：
//   - Android: EncryptedSharedPreferences (AES-256 via Android Keystore)
//   - iOS/macOS: Keychain
//   - Windows: DPAPI (Data Protection API)
//   - Linux: libsecret
// 避免每次 App 重启都触发重新登录（产生重复登录记录）。
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kSessionKey = 'auth_session';
// Token 最长有效期（30 天），超期后强制重新登录
const _kMaxAgeMs = 30 * 24 * 3600 * 1000;

// Android: 使用 EncryptedSharedPreferences (AES-256-SIV + AES-256-GCM)
const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);

class AuthStorageService {
  AuthStorageService._();

  /// 保存登录 Session 到平台安全存储
  static Future<void> save({
    required String imToken,
    required String chatToken,
    required String userID,
    required String nickname,
    required String faceURL,
    required int appRole,
    required bool isUserAdmin,
  }) async {
    try {
      final payload = json.encode({
        'imToken': imToken,
        'chatToken': chatToken,
        'userID': userID,
        'nickname': nickname,
        'faceURL': faceURL,
        'appRole': appRole,
        'isUserAdmin': isUserAdmin,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      });
      await _storage.write(key: _kSessionKey, value: payload);
    } catch (_) {
      // 持久化失败不阻塞登录流程
    }
  }

  /// 读取本地会话（若不存在或已过期则返回 null）
  static Future<Map<String, dynamic>?> load() async {
    try {
      final raw = await _storage.read(key: _kSessionKey);
      if (raw == null) return null;
      final data = json.decode(raw) as Map<String, dynamic>;
      final savedAt = (data['savedAt'] as int?) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - savedAt;
      if (age > _kMaxAgeMs) {
        await _storage.delete(key: _kSessionKey);
        return null;
      }
      final imToken = data['imToken'] as String? ?? '';
      final userID = data['userID'] as String? ?? '';
      if (imToken.isEmpty || userID.isEmpty) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// 清除本地会话（登出时调用）
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _kSessionKey);
    } catch (e) {
      debugPrint('清除本地会话存储失败: $e');
    }
  }
}
