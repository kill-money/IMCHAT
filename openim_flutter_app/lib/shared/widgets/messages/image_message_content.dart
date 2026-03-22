import 'package:flutter/material.dart';
import '../../../core/models/message.dart';
import '../../pages/image_viewer_page.dart';
import '../../theme/colors.dart';

/// 图片消息内容组件（网络图片，自适应宽高，点击全屏查看）
class ImageMessageContent extends StatelessWidget {
  final Message message;

  /// 当前会话中所有图片 URL（用于画廊模式左右滑动）
  final List<String> allImageUrls;

  /// 当前图片在 allImageUrls 中的索引
  final int currentIndex;

  const ImageMessageContent({
    super.key,
    required this.message,
    this.allImageUrls = const [],
    this.currentIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final url = message.imageContent?.url ?? '';
    if (url.isEmpty) {
      return _placeholder();
    }

    final heroTag = 'img_${message.clientMsgID}';

    return GestureDetector(
      onTap: () {
        if (allImageUrls.length > 1) {
          ImageViewerPage.showGallery(
            context,
            urls: allImageUrls,
            initialIndex: currentIndex,
            heroTag: heroTag,
          );
        } else {
          ImageViewerPage.show(context, url: url, heroTag: heroTag);
        }
      },
      child: Hero(
        tag: heroTag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220, maxHeight: 280),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return _loading(progress);
            },
            errorBuilder: (_, __, ___) => _placeholder(),
          ),
        ),
      ),
    );
  }

  Widget _loading(ImageChunkEvent progress) {
    return SizedBox(
      width: 180,
      height: 140,
      child: Center(
        child: CircularProgressIndicator(
          value: progress.expectedTotalBytes != null
              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
              : null,
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 180,
      height: 140,
      color: AppColors.divider,
      child: const Icon(Icons.broken_image_outlined,
          size: 40, color: AppColors.textSecondary),
    );
  }
}
