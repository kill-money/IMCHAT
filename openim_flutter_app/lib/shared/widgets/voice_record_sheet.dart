import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// 按住录音底部弹窗
/// 调用方式：
/// ```dart
/// final result = await VoiceRecordSheet.show(context);
/// if (result != null) { /* result.path, result.durationMs */ }
/// ```
class VoiceRecordSheet extends StatefulWidget {
  const VoiceRecordSheet({super.key});

  static Future<VoiceRecordResult?> show(BuildContext context) {
    return showModalBottomSheet<VoiceRecordResult>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceRecordSheet(),
    );
  }

  @override
  State<VoiceRecordSheet> createState() => _VoiceRecordSheetState();
}

class _VoiceRecordSheetState extends State<VoiceRecordSheet>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isCancelling = false;
  int _elapsedMs = 0;
  Timer? _timer;
  String? _filePath;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final dir =
        await getTemporaryDirectory().catchError((_) => Directory.systemTemp);
    final path =
        '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    setState(() {
      _isRecording = true;
      _filePath = path;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() => _elapsedMs += 100);
      // 最长录制 60 秒
      if (_elapsedMs >= 60000) _send();
    });
  }

  Future<void> _send() async {
    if (!_isRecording) return;
    _timer?.cancel();
    await _recorder.stop();
    setState(() => _isRecording = false);
    if (mounted && _filePath != null && _elapsedMs >= 1000) {
      Navigator.of(context).pop(
        VoiceRecordResult(path: _filePath!, durationMs: _elapsedMs),
      );
    } else {
      // 录音太短，取消
      if (_filePath != null) {
        try {
          File(_filePath!).deleteSync();
        } catch (e) {
          debugPrint('删除临时录音文件失败: $e');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('录音时间太短')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    setState(() => _isCancelling = true);
    await _recorder.stop();
    if (_filePath != null) {
      try {
        File(_filePath!).deleteSync();
      } catch (e) {
        debugPrint('取消录音-删除临时文件失败: $e');
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  String get _timeLabel {
    final s = (_elapsedMs / 1000).floor();
    final ms = ((_elapsedMs % 1000) / 100).floor();
    return '${s.toString().padLeft(2, '0')}:$ms';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl, AppSpacing.xl, AppSpacing.xxl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 状态提示
          Text(
            _isCancelling
                ? '已取消'
                : _isRecording
                    ? '松开发送，向左滑取消'
                    : '准备中...',
            style: TextStyle(
              fontSize: 14,
              color: _isCancelling ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 波纹动画 + 麦克风图标
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              final scale = 1.0 + _pulseController.value * 0.2;
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _isCancelling
                    ? AppColors.danger.withAlpha(25)
                    : AppColors.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isCancelling ? Icons.mic_off : Icons.mic,
                color: _isCancelling ? AppColors.danger : AppColors.primary,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 计时
          Text(
            _timeLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 取消
              GestureDetector(
                onTap: _cancel,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 28),
                ),
              ),

              // 发送
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            '按 × 取消，按发送 ↑ 完成',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class VoiceRecordResult {
  final String path;
  final int durationMs;
  const VoiceRecordResult({required this.path, required this.durationMs});
}
