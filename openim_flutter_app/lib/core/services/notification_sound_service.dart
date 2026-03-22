import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 新消息提示音服务（单例）
class NotificationSoundService {
  NotificationSoundService._();
  static final NotificationSoundService instance = NotificationSoundService._();

  static const _kMsgSound = 'settings_msg_sound';
  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_kMsgSound) ?? true;
  }

  /// 由 settings 页调用同步更新
  set enabled(bool value) => _enabled = value;

  /// 播放提示音
  Future<void> play() async {
    if (!_enabled) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/newMsg.mp3'));
    } catch (e) {
      debugPrint('[NotifSound] 播放提示音失败: $e');
    }
  }
}
