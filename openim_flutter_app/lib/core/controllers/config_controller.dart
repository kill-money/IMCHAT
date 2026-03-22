import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../services/feature_registry.dart';
import '../services/im_sdk_service.dart';

/// 集中管理远端客户端配置（/client_config/get）。
///
/// 启动时调用 [load]，后续通过 Provider 读取 [config] Map。
/// 支持 feature-flag 风格的布尔值判断（"0"/"1"）。
class ConfigController extends ChangeNotifier {
  Map<String, String> _config = {};
  bool _loaded = false;
  bool _loading = false;
  bool _isDisposed = false;

  /// 全量配置 Map
  Map<String, String> get config => _config;

  /// 是否已完成初次加载
  bool get loaded => _loaded;

  /// 是否正在加载
  bool get loading => _loading;

  void debugPrintState() {
    debugPrint(
        '[ConfigController] loaded=$_loaded loading=$_loading keys=${_config.keys}');
  }

  /// 从后端拉取配置（启动时调用一次即可）
  Future<void> load() async {
    if (_isDisposed || _loading) return;
    _loading = true;
    _safeNotify();
    try {
      final resp = await ChatApi.post('/client_config/get', {});
      if (_isDisposed) return;
      final data = resp['data'] as Map<String, dynamic>?;
      if (data != null && data['config'] != null) {
        final raw = data['config'] as Map<String, dynamic>;
        _config = raw.map((k, v) => MapEntry(k, v.toString()));
      }
      _loaded = true;
    } catch (e) {
      debugPrint('[ConfigController] load failed: $e');
    } finally {
      if (!_isDisposed) {
        _loading = false;
        _safeNotify();
      }
    }
  }

  /// 安全的 notifyListeners，避免在 dispose 后调用
  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// 读取字符串配置，返回 null 表示 key 不存在
  String? getString(String key) => _config[key];

  /// 读取布尔配置（"0"/"false"/"" → false，其余 → true）
  bool getBool(String key, {bool defaultValue = false}) {
    final v = _config[key];
    if (v == null) return defaultValue;
    return v != '0' && v.toLowerCase() != 'false' && v.isNotEmpty;
  }

  /// 便捷方法：功能开关
  bool get useSDK => false; // 统一 HTTP 模式，确保 Web 与 Android 数据同步
  bool get whitelistLoginEnabled => getBool('whitelistLoginEnabled');
  bool get editMessageEnabled =>
      getBool('edit_message_enabled', defaultValue: true);
  bool get walletEnabled => getBool('wallet_enabled', defaultValue: true);
  bool get groupEnabled => getBool('group_enabled', defaultValue: true);
  bool get addFriendEnabled =>
      getBool('add_friend_enabled', defaultValue: true);
  bool get starredMessagesEnabled =>
      getBool('starred_messages_enabled', defaultValue: true);
  bool get deviceManageEnabled =>
      getBool('device_manage_enabled', defaultValue: true);

  /// 检查某个 [FeatureEntry] 是否可用（结合 configKey + adminOnly）
  bool isFeatureEnabled(FeatureEntry feature, {bool isAdmin = false}) {
    if (feature.adminOnly && !isAdmin) return false;
    if (feature.configKey != null) {
      return getBool(feature.configKey!, defaultValue: true);
    }
    return true;
  }

  /// 首页相关配置
  String? get discoverPageURL => getString('discoverPageURL');
  String? get homeBanners => getString('home_banners');
  String? get homeAnnouncement => getString('home_announcement');

  @override
  void dispose() {
    _isDisposed = true;
    _config.clear();
    super.dispose();
  }
}
