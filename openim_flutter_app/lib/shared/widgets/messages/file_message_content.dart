import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 文件消息内容组件（图标 + 文件名 + 大小，点击下载）
class FileMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const FileMessageContent(
      {super.key, required this.message, required this.isMe});

  Future<void> _openFile(BuildContext context) async {
    final url = message.fileContent?.url ?? '';
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('无法打开文件')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = message.fileContent;
    final fileName = file?.fileName ?? '未知文件';
    final fileSize = file?.fileSize ?? 0;

    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final subColor = isMe ? const Color(0xCCFFFFFF) : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => _openFile(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForFile(fileName),
              size: 36, color: isMe ? Colors.white : AppColors.accent),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor),
                ),
                if (fileSize > 0)
                  Text(
                    _formatSize(fileSize),
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                Text(
                  '点击下载',
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isMe ? const Color(0xCCFFFFFF) : AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image_outlined;
    }
    if (['mp4', 'mov', 'avi', 'mkv'].contains(ext)) {
      return Icons.videocam_outlined;
    }
    if (['mp3', 'aac', 'wav', 'm4a'].contains(ext)) {
      return Icons.audiotrack_outlined;
    }
    if (['pdf'].contains(ext)) return Icons.picture_as_pdf_outlined;
    if (['doc', 'docx'].contains(ext)) return Icons.description_outlined;
    if (['xls', 'xlsx'].contains(ext)) return Icons.table_chart_outlined;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}
