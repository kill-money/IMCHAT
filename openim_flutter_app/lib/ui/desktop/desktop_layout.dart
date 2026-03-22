import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/conversation_controller.dart';
import '../../core/controllers/chat_controller.dart';
import '../../core/controllers/status_controller.dart'; // 在线状态
import '../../core/controllers/config_controller.dart'; // 全局配置
import '../../core/controllers/group_controller.dart'; // 群组
import '../../core/api/api_client.dart';
import '../../shared/widgets/conversation_item.dart';
import '../../shared/widgets/conversation_ip_badge.dart'; // IP溯源
import 'package:flutter/services.dart';
import '../../core/models/message.dart';
import '../../shared/widgets/messages/message_bubble.dart';
import '../../shared/widgets/message_input.dart';
import '../../shared/theme/colors.dart';
import '../../shared/widgets/user_avatar.dart';
import 'pages/desktop_contacts_page.dart';
import 'pages/desktop_settings_page.dart';
import '../mobile/pages/mobile_home_page.dart';
import '../mobile/pages/mobile_profile_page.dart';
import '../mobile/pages/group/create_group_page.dart';
import '../mobile/pages/group/group_detail_page.dart';
import '../mobile/pages/mobile_search_page.dart';
import '../mobile/pages/mobile_wallet_page.dart';
import '../mobile/pages/add_friend_page.dart';
import '../../shared/pages/starred_messages_page.dart';
import '../../shared/pages/device_manage_page.dart';
import '../../shared/pages/user_detail_page.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> with WindowListener {
  // 0=home, 1=chat, 2=contacts, 3=profile, 4=settings, 7=wallet, 8=groups
  int _sidebarIndex = 0;
  String? _selectedConversationID;
  String? _selectedGroupID; // 群管理选中的群
  double _listWidth = 280;
  static const double _minListWidth = 200;
  static const double _maxListWidth = 400;

  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] DesktopLayout');
    windowManager.addListener(this);
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

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Minimize to system tray instead of closing
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    final isFullWidth = _sidebarIndex == 0 ||
        _sidebarIndex == 3 ||
        _sidebarIndex == 4 ||
        _sidebarIndex == 7;
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar (narrow icon strip, ~60px)
          _buildSidebar(),
          // Middle panel (conversation list or contacts)
          _buildMiddlePanel(),
          // Drag handle for resizing
          if (!isFullWidth) _buildDragHandle(),
          // Right panel (chat or settings)
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final auth = context.watch<AuthController>();
    final cfg = context.watch<ConfigController>();
    return Container(
      width: 60,
      color: const Color(0xFF2E2E2E),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    UserAvatar(
                      faceURL: auth.currentUser?.faceURL ?? '',
                      nickname: auth.currentUser?.nickname ?? '',
                      size: 36,
                    ),
                    const SizedBox(height: 24),
                    _sidebarIcon(Icons.home_outlined, 0, tooltip: '首页'),
                    _sidebarIcon(Icons.chat, 1, tooltip: '消息'),
                    _sidebarIcon(Icons.contacts, 2, tooltip: '通讯录'),
                    if (cfg.groupEnabled)
                      _sidebarIcon(Icons.groups, 8, tooltip: '群管理'),
                    _sidebarIcon(Icons.person_outline, 3, tooltip: '个人中心'),
                    if (cfg.walletEnabled)
                      _sidebarIcon(Icons.account_balance_wallet_outlined, 7,
                          tooltip: '钱包'),
                    const Divider(
                        color: Colors.white24,
                        height: 16,
                        indent: 12,
                        endIndent: 12),
                    if (cfg.addFriendEnabled)
                      _sidebarIcon(Icons.person_add_outlined, 9,
                          tooltip: '添加好友'),
                    _sidebarIcon(Icons.group_add, 5, tooltip: '创建群聊'),
                    _sidebarIcon(Icons.search, 6, tooltip: '搜索消息'),
                    if (cfg.starredMessagesEnabled)
                      _sidebarIcon(Icons.star_outline, 10, tooltip: '收藏'),
                    if (cfg.deviceManageEnabled)
                      _sidebarIcon(Icons.devices_outlined, 11, tooltip: '设备管理'),
                    const Spacer(),
                    _sidebarIcon(Icons.settings, 4),
                    const SizedBox(height: 16),
                    IconButton(
                      icon: const Icon(Icons.logout,
                          color: AppColors.textSecondary, size: 20),
                      onPressed: () {
                        auth.logout();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      tooltip: '退出登录',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, int index, {String? tooltip}) {
    final selected = _sidebarIndex == index;
    final isAction = index >= 5 && index != 8; // 8=groups is a tab, not action
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () {
            if (isAction) {
              _handleAction(index);
            } else {
              setState(() => _sidebarIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected && !isAction
                  ? Colors.white.withAlpha(25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: selected && !isAction
                    ? Colors.white
                    : AppColors.textSecondary,
                size: 22),
          ),
        ),
      ),
    );
  }

  void _handleAction(int index) {
    switch (index) {
      case 5: // 创建群聊
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupPage()),
        );
        break;
      case 6: // 搜索消息
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MobileSearchPage()),
        );
        break;
      case 9: // 添加好友
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddFriendPage()),
        );
        break;
      case 10: // 收藏消息
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StarredMessagesPage()),
        );
        break;
      case 11: // 设备管理
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DeviceManagePage()),
        );
        break;
    }
  }

  Widget _buildMiddlePanel() {
    // Home, Profile, Settings, Wallet use full-width right panel — hide middle
    if (_sidebarIndex == 0 ||
        _sidebarIndex == 3 ||
        _sidebarIndex == 4 ||
        _sidebarIndex == 7) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _listWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border(right: BorderSide(color: AppColors.divider, width: 0)),
        ),
        child: _sidebarIndex == 2
            ? const DesktopContactsPage()
            : _sidebarIndex == 8
                ? _buildGroupList()
                : _buildConversationList(),
      ),
    );
  }

  Widget _buildDragHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _listWidth = (_listWidth + details.delta.dx)
                .clamp(_minListWidth, _maxListWidth);
          });
        },
        child: Container(
          width: 4,
          color: AppColors.divider,
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    switch (_sidebarIndex) {
      case 0:
        return const MobileHomePage();
      case 3:
        return const MobileProfilePage();
      case 4:
        return const DesktopSettingsPage();
      case 7:
        return const MobileWalletPage();
      case 8:
        return _selectedGroupID != null
            ? GroupDetailPage(groupID: _selectedGroupID!)
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_outlined,
                        size: 64, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text('选择一个群查看详情',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              );
      default:
        return _buildChatPanel();
    }
  }

  Widget _buildConversationList() {
    final controller = context.watch<ConversationController>();
    final statusCtrl = context.watch<StatusController>();
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        // List
        Expanded(
          child: controller.loading && controller.conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : controller.error.isNotEmpty && controller.conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          Text(controller.error,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => controller.loadConversations(),
                            child: const Text('重试'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: controller.conversations.length,
                      itemBuilder: (context, index) {
                        final conv = controller.conversations[index];
                        return ConversationItem(
                          conversation: conv,
                          userStatus: conv.conversationType == 1
                              ? statusCtrl.getStatus(conv.userID)
                              : null,
                          selected:
                              conv.conversationID == _selectedConversationID,
                          onTap: () {
                            setState(() {
                              _selectedConversationID = conv.conversationID;
                            });
                            final chat = context.read<ChatController>();
                            chat.setConversation(conv.conversationID);
                            chat.loadHistory(
                                conversationID: conv.conversationID);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildGroupList() {
    final groupCtrl = context.watch<GroupController>();
    if (groupCtrl.groups.isEmpty && !groupCtrl.loading) {
      // 首次进入时加载
      Future.microtask(() => groupCtrl.loadJoinedGroups());
    }
    return Column(
      children: [
        // Header + refresh
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Text('我的群组',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                onPressed: () => groupCtrl.loadJoinedGroups(),
                tooltip: '刷新',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: groupCtrl.loading && groupCtrl.groups.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : groupCtrl.groups.isEmpty
                  ? const Center(
                      child: Text('暂未加入任何群',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)))
                  : ListView.builder(
                      itemCount: groupCtrl.groups.length,
                      itemBuilder: (context, index) {
                        final g = groupCtrl.groups[index];
                        final selected = g.groupID == _selectedGroupID;
                        return ListTile(
                          dense: true,
                          selected: selected,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(20),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundImage: g.faceURL.isNotEmpty
                                ? NetworkImage(g.faceURL)
                                : null,
                            child: g.faceURL.isEmpty
                                ? Text(
                                    g.groupName.isNotEmpty
                                        ? g.groupName[0]
                                        : '群',
                                    style: const TextStyle(fontSize: 14))
                                : null,
                          ),
                          title: Text(g.groupName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: Text('${g.memberCount} 人',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          onTap: () {
                            setState(() => _selectedGroupID = g.groupID);
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildChatPanel() {
    if (_selectedConversationID == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('选择一个会话开始聊天',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    final convCtrl = context.read<ConversationController>();
    final conv = convCtrl.getById(_selectedConversationID!);
    final chat = context.watch<ChatController>();
    final messages = chat.displayMessages;
    final reactionsMap = chat.reactionsMap;
    final isMulti = chat.multiSelectMode;
    final sessionType = conv?.conversationType ?? 1;
    final recvID = conv != null
        ? (conv.conversationType == 1 ? conv.userID : conv.groupID)
        : '';

    // 所有图片URL（画廊浏览）
    final allImageUrls = messages
        .where((m) => m.isImage)
        .map((m) => m.imageContent?.url ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return Column(
      children: [
        // Chat header
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isMulti) ...[
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: chat.clearMultiSelect,
                ),
                Text('已选 ${chat.selectedMsgIDs.length} 条',
                    style: const TextStyle(fontSize: 14)),
                const Spacer(),
                TextButton.icon(
                  icon: Icon(Icons.delete_outline,
                      size: 18,
                      color: chat.selectedMsgIDs.isNotEmpty
                          ? AppColors.danger
                          : AppColors.disabled),
                  label: Text('删除',
                      style: TextStyle(
                          color: chat.selectedMsgIDs.isNotEmpty
                              ? AppColors.danger
                              : AppColors.disabled)),
                  onPressed: chat.selectedMsgIDs.isNotEmpty
                      ? () {
                          chat.deleteMessageForSelf(
                            conversationID: _selectedConversationID!,
                            clientMsgIDs: chat.selectedMsgIDs.toList(),
                          );
                          chat.clearMultiSelect();
                        }
                      : null,
                ),
              ] else ...[
                Text(
                  conv?.showName ?? '',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500),
                ),
                // 管理员可见对方最后登录 IP
                Builder(builder: (ctx) {
                  final canViewIP =
                      ctx.watch<AuthController>().currentUser?.canViewIP ??
                          false;
                  final rid = conv?.userID ?? '';
                  if (!canViewIP || rid.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return ConversationIPBadge(partnerUserID: rid);
                }),
              ],
            ],
          ),
        ),
        // Messages
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            child: chat.loading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('暂无消息，发一条消息吧'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (ctx, index) {
                          final msg = messages[index];
                          final isMsgMe = msg.sendID == ApiConfig.userID;
                          final selected =
                              chat.selectedMsgIDs.contains(msg.clientMsgID);
                          final retrying = chat.isRetryingMsg(msg.clientMsgID);
                          return Column(
                            crossAxisAlignment: isMsgMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              MessageBubble(
                                message: msg,
                                isMe: isMsgMe,
                                isSelected: selected,
                                showSenderName: sessionType == 3 && !isMsgMe,
                                reactions: reactionsMap[msg.clientMsgID] ?? {},
                                allImageUrls: allImageUrls,
                                onAvatarTap: () {
                                  Navigator.of(ctx).push(MaterialPageRoute(
                                    builder: (_) => UserDetailPage(
                                      targetUserID: msg.sendID,
                                      nickname: msg.senderNickname,
                                      faceURL: msg.senderFaceURL,
                                    ),
                                  ));
                                },
                                onLongPress: () => isMulti
                                    ? chat.toggleSelect(msg.clientMsgID)
                                    : _showDesktopMsgActions(ctx, msg, chat),
                                onTap: isMulti
                                    ? () => chat.toggleSelect(msg.clientMsgID)
                                    : null,
                              ),
                              if (retrying)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, bottom: 2),
                                  child: GestureDetector(
                                    onTap: () =>
                                        chat.forceRetry(msg.clientMsgID),
                                    child: Text(
                                      '收藏同步中(${chat.getRetryCount(msg.clientMsgID)}) 点击重试',
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.orange),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
          ),
        ),
        // 回复预览条
        if (chat.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.cardBackground,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Container(width: 3, height: 36, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '回复 ${chat.replyingTo!.senderNickname}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        chat.replyingTo!.previewText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => chat.setReplyingTo(null),
                  color: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        // 多选操作栏
        if (isMulti)
          const SizedBox.shrink() // 多选操作在 header 里
        else
          MessageInput(
            compact: true,
            onSend: (text) {
              if (chat.replyingTo != null) {
                chat.sendQuoteMessage(
                  recvID: recvID,
                  text: text,
                  quoteMsg: chat.replyingTo!,
                  sessionType: sessionType,
                );
                chat.setReplyingTo(null);
              } else {
                chat.sendTextMessage(
                  recvID: recvID,
                  text: text,
                  sessionType: sessionType,
                );
              }
            },
          ),
      ],
    );
  }

  /// 桌面端消息操作菜单（长按触发）
  void _showDesktopMsgActions(
      BuildContext ctx, Message msg, ChatController chat) {
    final isMe = msg.sendID == ApiConfig.userID;
    final isStarred = chat.isStarred(msg.clientMsgID);

    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (msg.isText)
                  _buildMsgAction(Icons.copy_outlined, '复制', () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg.previewText));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx)
                          .showSnackBar(const SnackBar(content: Text('已复制')));
                    }
                  }),
                _buildMsgAction(Icons.reply_outlined, '回复', () {
                  Navigator.pop(ctx);
                  chat.setReplyingTo(msg);
                }),
                _buildMsgAction(
                  isStarred ? Icons.star : Icons.star_outline,
                  isStarred ? '取消收藏' : '收藏',
                  () {
                    Navigator.pop(ctx);
                    chat.toggleStar(msg.clientMsgID);
                  },
                  color: AppColors.accent,
                ),
                if (isMe && chat.canRecall(msg))
                  _buildMsgAction(Icons.undo_outlined, '撤回', () {
                    Navigator.pop(ctx);
                    chat.revokeMessage(
                      conversationID: _selectedConversationID!,
                      seq: msg.seq,
                      clientMsgID: msg.clientMsgID,
                    );
                  }),
                _buildMsgAction(Icons.delete_outline, '删除', () {
                  Navigator.pop(ctx);
                  chat.deleteMessageForSelf(
                    conversationID: _selectedConversationID!,
                    clientMsgIDs: [msg.clientMsgID],
                  );
                }, color: AppColors.danger),
                _buildMsgAction(Icons.check_box_outlined, '多选', () {
                  Navigator.pop(ctx);
                  chat.enterMultiSelectMode(msg.clientMsgID);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMsgAction(IconData icon, String label, VoidCallback onTap,
      {Color color = AppColors.textPrimary}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(fontSize: 11, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
