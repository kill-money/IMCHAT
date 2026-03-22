import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 渲染 sticker（contentType=112）和 GIF（contentType=113）消息。
/// 两者均以网络图片展示，不套入气泡容器，直接显示图片内容。
class StickerMessageContent extends StatelessWidget {
  final Message message;

  const StickerMessageContent({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final String url;
    if (message.isSticker) {
      url = message.stickerContent?.url ?? '';
    } else {
      url = message.gifContent?.url ?? '';
    }

    if (url.isEmpty) {
      return const Icon(Icons.error_outline, color: AppColors.textSecondary);
    }

    // 如果 url 是网络地址则显示图片，否则当作 emoji 字符渲染
    final isNetworkUrl =
        url.startsWith('http://') || url.startsWith('https://');
    if (!isNetworkUrl) {
      return Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        child: Text(url, style: const TextStyle(fontSize: 52)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 140,
        height: 140,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 140,
            height: 140,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
        errorBuilder: (_, __, ___) => const Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
