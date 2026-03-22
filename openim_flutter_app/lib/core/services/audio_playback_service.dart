import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 全局语音播放管理器（单例）。
///
/// 职责：
/// - 同一时刻只允许一条消息在播放
/// - 向外广播"当前播放中的 clientMsgID"，为空表示全部暂停
/// - 提供本地缓存路径支持（由 AudioCacheService 填充后调用 play）
class AudioPlaybackService extends ChangeNotifier {
  AudioPlaybackService._();
  static final instance = AudioPlaybackService._();

  final AudioPlayer _player = AudioPlayer();

  /// 当前正在播放的消息 ID，为空表示无播放
  String? _currentMsgID;
  String? get currentMsgID => _currentMsgID;

  bool get isPlaying => _currentMsgID != null;

  StreamSubscription<PlayerState>? _stateSub;

  /// 初始化监听，在 main.dart 调用一次即可
  void init() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        _currentMsgID = null;
        notifyListeners();
      }
    });

    // 配置为后台/锁屏下继续播放（Web 平台无需 native audio context）
    if (!kIsWeb) {
      _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  /// 播放指定消息。若该消息已在播放则暂停（切换逻辑）。
  /// [source] 可以是 UrlSource 或 DeviceFileSource（本地缓存路径）
  Future<void> toggle(String msgID, Source source) async {
    if (_currentMsgID == msgID) {
      // 同一条：切换暂停/恢复
      final state = _player.state;
      if (state == PlayerState.playing) {
        await _player.pause();
        _currentMsgID = null;
      } else {
        await _player.resume();
        _currentMsgID = msgID;
      }
    } else {
      // 不同条：先停掉已有的
      await _player.stop();
      _currentMsgID = msgID;
      notifyListeners(); // 立即更新 UI，让旧气泡回到静止态
      await _player.play(source);
    }
    notifyListeners();
  }

  /// 强制停止所有播放（退出页面时调用）
  Future<void> stopAll() async {
    await _player.stop();
    _currentMsgID = null;
    notifyListeners();
  }
}
