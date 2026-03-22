import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 视频消息内容组件（封面缩略图 + 播放图标，点击打开视频）
class VideoMessageContent extends StatelessWidget {
  final Message message;

  const VideoMessageContent({super.key, required this.message});

  Future<void> _openVideo(BuildContext context) async {
    final url = message.videoContent?.videoUrl ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法打开视频')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final video = message.videoContent;
    final snapshotUrl = video?.snapshotUrl ?? '';
    final duration = video?.duration ?? 0;

    return GestureDetector(
      onTap: () => _openVideo(context),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 封面图
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220, maxHeight: 220),
            child: snapshotUrl.isNotEmpty
                ? Image.network(
                    snapshotUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          // 播放按鈕遇罩
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          const Icon(Icons.play_circle_fill, size: 52, color: Colors.white),
          // 时长标签
          if (duration > 0)
            Positioned(
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 180,
        height: 180,
        color: AppColors.divider,
        child: const Icon(Icons.videocam_off_outlined,
            size: 40, color: AppColors.textSecondary),
      );

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
