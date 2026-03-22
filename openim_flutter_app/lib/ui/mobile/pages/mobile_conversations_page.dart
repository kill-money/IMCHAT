import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/conversation_controller.dart';
import '../../../core/controllers/status_controller.dart';
import '../../../core/models/conversation.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/widgets/conversation_item.dart';
import '../../../shared/widgets/ui/app_header.dart';
import 'add_friend_page.dart';
import 'group/create_group_page.dart';
import 'mobile_chat_page.dart';

class MobileConversationsPage extends StatefulWidget {
  const MobileConversationsPage({super.key});

  @override
  State<MobileConversationsPage> createState() =>
      _MobileConversationsPageState();
}

class _MobileConversationsPageState extends State<MobileConversationsPage> {
  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] MobileConversationsPage');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ConversationController>().loadConversations();
      if (!mounted) return;
      context.read<ConversationController>().debugPrintState();
      _fetchStatuses();
    });
  }

  void _fetchStatuses() {
    final convCtrl = context.read<ConversationController>();
    final statusCtrl = context.read<StatusController>();
    final ids = convCtrl.conversations
        .where((c) => c.conversationType == 1 && c.userID.isNotEmpty)
        .map((c) => c.userID)
        .toList();
    statusCtrl.fetchStatuses(ids);
  }

  void _showConvActions(
    BuildContext ctx,
    Conversation conv,
    ConversationController controller,
  ) {
    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading: Icon(
                  conv.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                  color: AppColors.primary,
                ),
                title: Text(conv.isPinned ? '取消置顶' : '置顶会话'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.pinConversation(conv.conversationID,
                      pinned: !conv.isPinned);
                },
              ),
              ListTile(
                leading: Icon(
                  conv.isMuted
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  color: AppColors.primary,
                ),
                title: Text(conv.isMuted ? '取消静音' : '消息免打扰'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.setMuteStatus(conv.conversationID,
                      recvMsgOpt: conv.isMuted ? 0 : 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep_outlined,
                    color: AppColors.danger),
                title: const Text('清空聊天记录',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.clearConversationMessages(conv.conversationID);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.danger),
                title: const Text('删除会话',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  controller.deleteConversation(conv.conversationID);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConversationController>();
    final statusCtrl = context.watch<StatusController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppHeader(
        title: '消息',
        showBack: false,
        right: PopupMenuButton<String>(
          icon: const Icon(Icons.add_circle_outline,
              color: Colors.white, size: 24),
          tooltip: '新建',
          onSelected: (value) {
            if (value == 'create_group') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGroupPage()),
              );
            } else if (value == 'add_friend') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddFriendPage()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('扫码功能即将上线')),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'create_group',
              child: Row(children: [
                Icon(Icons.group_add_outlined, size: 20),
                SizedBox(width: 10),
                Text('创建群聊'),
              ]),
            ),
            PopupMenuItem(
              value: 'add_friend',
              child: Row(children: [
                Icon(Icons.person_add_outlined, size: 20),
                SizedBox(width: 10),
                Text('添加好友'),
              ]),
            ),
            PopupMenuItem(
              value: 'scan',
              child: Row(children: [
                Icon(Icons.qr_code_scanner_outlined, size: 20),
                SizedBox(width: 10),
                Text('扫一扫'),
              ]),
            ),
          ],
        ),
      ),
      body: controller.loading && controller.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : controller.error.isNotEmpty && controller.conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(controller.error,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          controller.loadConversations();
                          _fetchStatuses();
                        },
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await controller.loadConversations();
                    _fetchStatuses();
                  },
                  child: controller.conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 64,
                                color:
                                    AppColors.primary.withValues(alpha: 0.22),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                '暂无会话，开始新对话吧',
                                style: AppTypography.small.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: controller.conversations.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 0.5,
                            indent: 72,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, index) {
                            final conv = controller.conversations[index];
                            return ConversationItem(
                              conversation: conv,
                              userStatus: conv.conversationType == 1
                                  ? statusCtrl.getStatus(conv.userID)
                                  : null,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MobileChatPage(
                                      conversationID: conv.conversationID,
                                      title: conv.showName,
                                      recvID: conv.userID,
                                      sessionType: conv.conversationType,
                                      appRole: conv.appRole,
                                      isOfficialUser: conv.isOfficialUser,
                                      isOfficialGroup: conv.isOfficialGroup,
                                      groupID: conv.groupID,
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () =>
                                  _showConvActions(context, conv, controller),
                            );
                          },
                        ),
                ),
    );
  }
}
