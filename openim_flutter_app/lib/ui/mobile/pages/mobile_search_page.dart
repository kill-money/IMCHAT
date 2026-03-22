import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/controllers/conversation_controller.dart';
import '../../../core/models/message.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/widgets/user_avatar.dart';

/// 消息类型过滤选项
enum _SearchFilter {
  all('全部', null),
  text('文字', MessageContentType.text),
  image('图片', MessageContentType.image),
  video('视频', MessageContentType.video),
  file('文件', MessageContentType.file),
  voice('语音', MessageContentType.voice);

  const _SearchFilter(this.label, this.contentType);
  final String label;
  final int? contentType;
}

class MobileSearchPage extends StatefulWidget {
  const MobileSearchPage({super.key});

  @override
  State<MobileSearchPage> createState() => _MobileSearchPageState();
}

class _MobileSearchPageState extends State<MobileSearchPage> {
  final _ctrl = TextEditingController();
  String _query = '';
  _SearchFilter _filter = _SearchFilter.all;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ConversationController>().conversations;
    // 聊天消息搜索（跨会话）
    final allMsgs = context
        .watch<ChatController>()
        .allMessages
        .where((m) => m.contentType != MessageContentType.reaction)
        .toList();

    final filtered =
        _query.isEmpty ? <dynamic>[] : _buildResults(conversations, allMsgs);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: '搜索联系人、对话或消息...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            border: InputBorder.none,
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消',
                style: TextStyle(color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息类型过滤条
          if (_query.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 8),
              child: Row(
                children: _SearchFilter.values.map((f) {
                  final active = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                active ? AppColors.primary : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                active ? Colors.white : AppColors.textPrimary,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: _query.isEmpty
                ? _empty()
                : filtered.isEmpty
                    ? _noResult()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 0.5, indent: 72, color: AppColors.divider),
                        itemBuilder: (_, i) => _buildItem(context, filtered[i]),
                      ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _buildResults(List<dynamic> conversations, List<Message> msgs) {
    final q = _query.toLowerCase();
    if (_filter == _SearchFilter.all) {
      // 会话结果（按名称/最新消息）
      final convResults = conversations.where((c) {
        return c.showName.toLowerCase().contains(q) ||
            c.latestMsg.toLowerCase().contains(q);
      }).toList();
      // 消息结果（按内容）
      final msgResults = msgs
          .where((m) => m.previewText.toLowerCase().contains(q))
          .cast<dynamic>()
          .toList();
      return [...convResults, ...msgResults];
    } else {
      // 仅搜索特定类型的消息
      return msgs
          .where((m) {
            if (m.contentType != _filter.contentType) return false;
            return m.previewText.toLowerCase().contains(q) ||
                (m.senderNickname.toLowerCase().contains(q));
          })
          .cast<dynamic>()
          .toList();
    }
  }

  Widget _buildItem(BuildContext context, dynamic item) {
    if (item is Message) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
        leading: UserAvatar(
            faceURL: item.senderFaceURL,
            nickname: item.senderNickname,
            size: 44),
        title: Text(item.senderNickname),
        subtitle: Text(
          item.previewText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        trailing: Text(
          _formatTime(item.sendTime),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/chat', arguments: item.recvID);
        },
      );
    }
    // 会话结果
    final c = item;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      leading: UserAvatar(faceURL: c.faceURL, nickname: c.showName, size: 44),
      title: Text(c.showName),
      subtitle: Text(
        c.latestMsg,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/chat', arguments: c.conversationID);
      },
    );
  }

  String _formatTime(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}/${dt.day}';
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '输入关键词搜索',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );

  Widget _noResult() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.find_in_page_outlined,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.20),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '暂无相关结果',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
}
