import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/message.dart';
import '../../theme/colors.dart';

/// 位置消息内容组件（地图 Pin 图标 + 描述文字，点击打开地图）
class LocationMessageContent extends StatelessWidget {
  final Message message;
  final bool isMe;

  const LocationMessageContent(
      {super.key, required this.message, required this.isMe});

  Future<void> _openMaps(BuildContext context) async {
    final loc = message.locationContent;
    if (loc == null) return;
    final lat = loc.latitude;
    final lng = loc.longitude;
    final label = Uri.encodeComponent(loc.desc.isNotEmpty ? loc.desc : '所在位置');

    // 优先尝试高德地图 / Apple Maps，如果失败则用通用 Google Maps
    final uris = [
      Uri.parse(
          'androidamap://navi?sourceApplication=openim&lat=$lat&lon=$lng&dev=0&style=2'),
      Uri.parse('maps://?q=$label&ll=$lat,$lng'), // Apple Maps
      Uri.parse('https://maps.google.com/?q=$lat,$lng'),
    ];

    for (final uri in uris) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('无法打开地图')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = message.locationContent;
    final desc = loc?.desc.isNotEmpty == true ? loc!.desc : '查看位置';
    final lat = loc?.latitude ?? 0.0;
    final lng = loc?.longitude ?? 0.0;

    final textColor = isMe ? Colors.white : AppColors.textPrimary;
    final subColor = isMe ? const Color(0xCCFFFFFF) : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => _openMaps(context),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 静态地图占位
            Container(
              width: 200,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 48, color: AppColors.disabled),
                  const Positioned(
                    child: Icon(Icons.location_on,
                        size: 32, color: AppColors.danger),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('点击查看',
                          style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(desc,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor)),
            Text(
              '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
              style: TextStyle(fontSize: 11, color: subColor),
            ),
          ],
        ),
      ),
    );
  }
}
