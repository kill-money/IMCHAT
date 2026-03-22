import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../../core/services/audio_cache_service.dart';
import '../../../core/services/audio_playback_service.dart';
import '../../theme/colors.dart';

/// 语音消息气泡内容。
///
/// 依赖 [AudioPlaybackService] 全局单例实现：
/// - 同一时刻只有一条消息在播放
/// - 跨气泡播放状态同步
/// - 本地磁盘缓存（通过 [AudioCacheService]）
/// - 动态 9-bar 波形动画
class VoiceMessageContent extends StatefulWidget {
  final Message message;
  final bool isMe;

  /// 波形颜色（可在主题层统一覆盖）
  final Color? activeBarColor;
  final Color? inactiveBarColorMe;
  final Color? inactiveBarColorOther;

  const VoiceMessageContent({
    super.key,
    required this.message,
    required this.isMe,
    this.activeBarColor,
    this.inactiveBarColorMe,
    this.inactiveBarColorOther,
  });

  @override
  State<VoiceMessageContent> createState() => _VoiceMessageContentState();
}

class _VoiceMessageContentState extends State<VoiceMessageContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveCtrl;

  // 9 根波形条的基础高度 + 最大增量（制造"中间高、两侧低"的麦克风形状）
  static const _baseH = [8.0, 12.0, 17.0, 22.0, 26.0, 22.0, 17.0, 12.0, 8.0];
  static const _deltaH = [3.0, 5.0, 7.0, 9.0, 10.0, 9.0, 7.0, 5.0, 3.0];

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // 监听全局播放服务，同步波形动画
    AudioPlaybackService.instance.addListener(_onPlaybackChanged);
  }

  @override
  void dispose() {
    AudioPlaybackService.instance.removeListener(_onPlaybackChanged);
    _waveCtrl.dispose();
    super.dispose();
  }

  void _onPlaybackChanged() {
    final isMe = AudioPlaybackService.instance.currentMsgID ==
        widget.message.clientMsgID;
    if (isMe) {
      _waveCtrl.repeat(reverse: true);
    } else {
      _waveCtrl.stop();
      _waveCtrl.reset();
    }
    // setState 仅刷新图标颜色，波形由 AnimatedBuilder 自动刷新
    if (mounted) setState(() {});
  }

  Future<void> _togglePlay() async {
    final url = widget.message.voiceContent?.url ?? '';
    if (url.isEmpty) return;

    final svc = AudioPlaybackService.instance;
    final msgID = widget.message.clientMsgID;

    // 尝试读取本地缓存，回退到远端 URL
    final localPath = await AudioCacheService.instance.resolve(url);
    final source = (localPath != null)
        ? DeviceFileSource(localPath) as Source
        : UrlSource(url);

    await svc.toggle(msgID, source);
  }

  bool get _playing =>
      AudioPlaybackService.instance.currentMsgID == widget.message.clientMsgID;

  @override
  Widget build(BuildContext context) {
    final voice = widget.message.voiceContent;
    final duration = voice?.duration ?? 0;
    final isMe = widget.isMe;

    // 气泡宽度随时长增长（50~200 px）
    final barsArea = (50.0 + duration * 5.0).clamp(50.0, 200.0);

    final activeColor = widget.activeBarColor ?? AppColors.accent;
    final inactiveColor = isMe
        ? (widget.inactiveBarColorMe ?? const Color(0xCCFFFFFF))
        : (widget.inactiveBarColorOther ?? AppColors.textSecondary);

    return GestureDetector(
      onTap: _togglePlay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isMe) ...[
            Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 28,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
          ],
          // ── 9-bar 动态波形 ──────────────────────────────────────
          SizedBox(
            width: barsArea,
            height: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(
                9,
                (i) => _animatedBar(i, isMe, activeColor, inactiveColor),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$duration"',
            style: TextStyle(
              fontSize: 13,
              color: isMe ? Colors.white : AppColors.textSecondary,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 6),
            Icon(
              _playing ? Icons.pause_circle_filled : Icons.play_circle_fill,
              size: 28,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }

  Widget _animatedBar(
      int i, bool isMe, Color activeColor, Color inactiveColor) {
    // 相邻条偏移相位，产生"流动"感
    final phaseOffset = i / 9;
    final anim = CurvedAnimation(
      parent: _waveCtrl,
      curve: Interval(
        (phaseOffset * 0.6).clamp(0.0, 0.9),
        1.0,
        curve: Curves.easeInOut,
      ),
    );

    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final h = _playing ? _baseH[i] + _deltaH[i] * anim.value : _baseH[i];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 4,
          height: h,
          decoration: BoxDecoration(
            color: _playing ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }
}
