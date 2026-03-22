import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/chat_api.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/controllers/conversation_controller.dart';
import '../../../core/controllers/group_controller.dart';
import '../../../core/controllers/status_controller.dart';
import '../../../core/models/group_permission.dart';
import '../../../core/models/message.dart';
import '../../../core/utils/content_filter.dart';
import '../../../shared/pages/user_detail_page.dart';
import 'group/group_detail_page.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/widgets/conversation_ip_badge.dart';
import '../../../shared/widgets/message_input.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../../shared/widgets/messages/message_bubble.dart';
import '../../../shared/widgets/ui/app_text.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/voice_record_sheet.dart';

class MobileChatPage extends StatefulWidget {
  final String conversationID;
  final String title;
  final String recvID;

  /// sessionType: 1=单聊, 3=群聊
  final int sessionType;

  /// 对方官方认证角色：0=普通，1=官方账号
  final int appRole;

  /// 对方是否官方账号（isOfficial 字段）
  final int isOfficialUser;

  /// 是否官方群（群聊时使用）
  final bool isOfficialGroup;

  /// 群 ID（群聊时用于导航群详情）
  final String groupID;

  const MobileChatPage({
    super.key,
    required this.conversationID,
    required this.title,
    this.recvID = '',
    this.sessionType = 1,
    this.appRole = 0,
    this.isOfficialUser = 0,
    this.isOfficialGroup = false,
    this.groupID = '',
  });

  @override
  State<MobileChatPage> createState() => _MobileChatPageState();
}

class _MobileChatPageState extends State<MobileChatPage> {
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();

  // 搜索状态
  bool _searchMode = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // 群公告 banner 是否已关闭
  bool _announcementDismissed = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] MobileChatPage convID=${widget.conversationID}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatController>();
      chat.setConversation(widget.conversationID);
      chat.loadHistory(conversationID: widget.conversationID);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // ─── Send ─────────────────────────────────────────────────────────────────

  Future<void> _sendText(String text) async {
    // 群聊中过滤联系方式
    if (widget.sessionType == 3 && ContentFilter.containsContactInfo(text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(ContentFilter.warningMessage)),
        );
      }
      return;
    }

    final chat = context.read<ChatController>();
    if (chat.replyingTo != null) {
      await chat.sendQuoteMessage(
        recvID: widget.recvID,
        text: text,
        quoteMsg: chat.replyingTo!,
        sessionType: widget.sessionType,
      );
      chat.setReplyingTo(null);
    } else {
      await chat.sendTextMessage(
        recvID: widget.recvID,
        text: text,
        sessionType: widget.sessionType,
      );
    }
    Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
  }

  Future<void> _handleAttach(AttachmentType type) async {
    final chat = context.read<ChatController>();
    switch (type) {
      case AttachmentType.gallery:
        final file = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (file != null && mounted) {
          final bytes = await file.readAsBytes();
          final filename = file.name;
          await chat.pickAndSendImage(
            recvID: widget.recvID,
            bytes: bytes,
            filename: filename,
            sessionType: widget.sessionType,
          );
          Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
        }

      case AttachmentType.camera:
        final file = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        if (file != null && mounted) {
          final bytes = await file.readAsBytes();
          final filename = file.name;
          await chat.pickAndSendImage(
            recvID: widget.recvID,
            bytes: bytes,
            filename: filename,
            sessionType: widget.sessionType,
          );
          Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
        }

      case AttachmentType.file:
        final result = await FilePicker.platform.pickFiles(withData: true);
        if (result != null && result.files.single.bytes != null && mounted) {
          final bytes = result.files.single.bytes!;
          final filename = result.files.single.name;
          await chat.pickAndSendFile(
            recvID: widget.recvID,
            bytes: bytes,
            filename: filename,
            sessionType: widget.sessionType,
          );
        }

      case AttachmentType.voice:
        if (!mounted) return;
        final result = await VoiceRecordSheet.show(context);
        if (result != null && mounted) {
          final bytes = await File(result.path).readAsBytes();
          final filename = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await chat.sendVoiceFromFile(
            recvID: widget.recvID,
            bytes: bytes,
            filename: filename,
            durationMs: result.durationMs,
            sessionType: widget.sessionType,
          );
          // 删除临时文件
          try {
            File(result.path).deleteSync();
          } catch (e) {
            debugPrint('删除临时附件文件失败: $e');
          }
          Future.delayed(const Duration(milliseconds: 120), _scrollToBottom);
        }

      case AttachmentType.location:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('位置分享功能即将上线')),
          );
        }

      case AttachmentType.sticker:
        _showStickerPicker(context);
    }
  }

  // 表情包选择器（示例实现：内置表情面板）
  void _showStickerPicker(BuildContext ctx) {
    final chat = ctx.read<ChatController>();
    final recvID = _effectiveRecvID();
    // 内置常用表情包 URL（实际业务中可替换为请求表情包列表 API）
    const stickers = [
      '😀',
      '😂',
      '🤓',
      '🤔',
      '😘',
      '😜',
      '👍',
      '👎',
      '❤️',
      '🔥',
      '🎉',
      '😢',
      '😱',
      '😡',
      '🥳',
      '🙏',
      '🙌',
      '💪',
    ];
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('表情',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: stickers.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  // 表情 emoji 作为自定义消息发送（sticker contentType=112）
                  chat.sendSticker(
                    recvID: recvID,
                    url: stickers[i],
                    name: stickers[i],
                    sessionType: widget.sessionType,
                  );
                },
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Text(stickers[i], style: const TextStyle(fontSize: 26)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _effectiveRecvID() {
    if (widget.conversationID.startsWith('sg_')) {
      return widget.conversationID.replaceFirst('sg_', '');
    }
    return widget.conversationID;
  }

  // ─── Long-press actions ───────────────────────────────────────────────────

  void _showMessageActions(BuildContext ctx, Message msg) {
    final chat = ctx.read<ChatController>();
    final isMe = msg.sendID == ApiConfig.userID;

    // 在 showModalBottomSheet 前一次性计算，避免 builder 重建时重新求值
    final canRecall = isMe && chat.canRecall(msg);
    final canEdit = isMe && msg.isText;
    final isStarred = chat.isStarred(msg.clientMsgID);

    // 群聊时获取当前用户权限
    GroupPermission? perm;
    if (widget.sessionType == 3) {
      final groupID = widget.conversationID.replaceFirst('sg_', '');
      final groupCtrl = ctx.read<GroupController>();
      final myMember = groupCtrl.getMyMember(groupID);
      if (myMember != null) {
        perm = GroupPermission(myMember.roleLevel);
      }
    }

    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MessageActionsSheet(
        message: msg,
        isMe: isMe,
        isStarred: isStarred,
        canRecall: canRecall,
        canEdit: canEdit,
        canGroupDelete: !isMe && (perm?.canDeleteOthersMessage ?? false),
        canPin: perm?.canPinMessage ?? false,
        isGroupChat: widget.sessionType == 3,
        onAction: (action) {
          Navigator.of(ctx).pop();
          _handleMessageAction(action, msg, chat);
        },
      ),
    );
  }

  void _handleMessageAction(
      _MsgAction action, Message msg, ChatController chat) {
    switch (action) {
      case _MsgAction.copy:
        Clipboard.setData(ClipboardData(text: msg.previewText));
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('已复制')));

      case _MsgAction.reply:
        chat.setReplyingTo(msg);

      case _MsgAction.star:
        chat.toggleStar(msg.clientMsgID);

      case _MsgAction.revoke:
        chat
            .revokeMessage(
          conversationID: widget.conversationID,
          seq: msg.seq,
          clientMsgID: msg.clientMsgID,
        )
            .then((ok) {
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('撤回失败：已超过2分钟')),
            );
          }
        });

      case _MsgAction.edit:
        _showEditDialog(msg, chat);

      case _MsgAction.groupDelete:
        _confirmGroupDelete(msg, chat);

      case _MsgAction.pin:
        if (widget.sessionType == 3) {
          final groupID = widget.conversationID.replaceFirst('sg_', '');
          GroupMsgApi.pinMessage(
            groupID: groupID,
            messageID: msg.clientMsgID,
            operatorID: ApiConfig.userID,
          ).then((resp) {
            if (mounted) {
              final ok = resp['errCode'] == null || resp['errCode'] == 0;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok ? '已置顶' : '置顶失败，请稍后重试')),
              );
            }
          });
        }

      case _MsgAction.delete:
        chat.deleteMessageForSelf(
          conversationID: widget.conversationID,
          clientMsgIDs: [msg.clientMsgID],
        );

      case _MsgAction.multiSelect:
        chat.enterMultiSelectMode(msg.clientMsgID);

      case _MsgAction.forward:
        _showForwardPicker(context, msg);

      case _MsgAction.react:
        _showEmojiReactionPicker(context, msg);
    }
  }

  /// 编辑消息对话框（仅文本）
  void _showEditDialog(Message msg, ChatController chat) {
    final controller = TextEditingController(text: msg.textContent);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入新的消息内容',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty || newText == msg.textContent) {
                Navigator.of(ctx).pop();
                return;
              }
              Navigator.of(ctx).pop();
              await chat.editMessage(
                conversationID: widget.conversationID,
                clientMsgID: msg.clientMsgID,
                newText: newText,
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 群主删除他人消息确认
  void _confirmGroupDelete(Message msg, ChatController chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除消息'),
        content: const Text('确定要删除该成员的消息吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.of(ctx).pop();
              chat.deleteGroupMessage(
                conversationID: widget.conversationID,
                clientMsgID: msg.clientMsgID,
                groupID: widget.conversationID.replaceFirst('sg_', ''),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _showEmojiReactionPicker(BuildContext ctx, Message msg) {
    final chat = ctx.read<ChatController>();
    final recvID = _effectiveRecvID();
    const emojis = ['👍', '❤️', '😂', '😮', '😢', '😡'];
    showModalBottomSheet<void>(
      context: ctx,
      backgroundColor: AppColors.pageBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: emojis
              .map((e) => GestureDetector(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      chat.sendReaction(
                        recvID: recvID,
                        reactToMsgID: msg.clientMsgID,
                        emoji: e,
                        sessionType: widget.sessionType,
                      );
                    },
                    child: Text(e, style: const TextStyle(fontSize: 30)),
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showForwardPicker(BuildContext ctx, Message msg) {
    final convs = context.read<ConversationController>().conversations;
    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text('转发给',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: convs.length,
              itemBuilder: (_, i) {
                final c = convs[i];
                return ListTile(
                  leading: UserAvatar(
                      faceURL: c.faceURL, nickname: c.showName, size: 40),
                  title: Text(c.showName),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final targetRecvID =
                        c.conversationType == 1 ? c.userID : c.groupID;
                    final ok =
                        await context.read<ChatController>().forwardMessage(
                              message: msg,
                              targetRecvID: targetRecvID,
                              targetSessionType: c.conversationType,
                            );
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(ok ? '转发成功' : '转发失败')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }

  /// 合并转发选择会话
  void _showMergeForwardPicker(BuildContext ctx, ChatController chat) {
    final convs = context.read<ConversationController>().conversations;
    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Text('合并转发到',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: convs.length,
              itemBuilder: (_, i) {
                final c = convs[i];
                return ListTile(
                  leading: UserAvatar(
                      faceURL: c.faceURL, nickname: c.showName, size: 40),
                  title: Text(c.showName),
                  onTap: () async {
                    Navigator.of(sheetCtx).pop();
                    final targetRecvID =
                        c.conversationType == 1 ? c.userID : c.groupID;
                    final ok = await chat.mergeForwardMessages(
                      conversationID: widget.conversationID,
                      targetRecvID: targetRecvID,
                      targetSessionType: c.conversationType,
                      title: '${widget.title}的聊天记录',
                    );
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(ok ? '合并转发成功' : '转发失败')),
                      );
                    }
                  },
                );
              },
            ),
          ),
          SizedBox(height: MediaQuery.of(ctx).padding.bottom + AppSpacing.md),
        ],
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final isMulti = chat.multiSelectMode;

    // 搜索过滤（使用 displayMessages 过滤掉 reaction 类型消息）
    final allMessages = chat.displayMessages;
    final messages = _searchQuery.isEmpty
        ? allMessages
        : allMessages
            .where((m) => m.previewText
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();
    final reactionsMap = chat.reactionsMap;

    // 提取所有图片URL用于画廊模式
    final allImageUrls = messages
        .where((m) => m.isImage)
        .map((m) => m.imageContent?.url ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && isMulti) chat.clearMultiSelect();
      },
      child: Scaffold(
        appBar: _buildAppBar(context, chat),
        body: Column(
          children: [
            // 搜索栏
            if (_searchMode)
              Material(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '搜索消息...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() {
                          _searchMode = false;
                          _searchQuery = '';
                          _searchCtrl.clear();
                        }),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
              ),
            // 群公告 Banner（群聊且有公告时显示，可关闭）
            if (widget.sessionType == 3 && !_announcementDismissed)
              Builder(builder: (context) {
                final groupID = widget.conversationID.replaceFirst('sg_', '');
                final group = context.watch<GroupController>().getById(groupID);
                final ann = group?.announcement ?? '';
                if (ann.isEmpty) return const SizedBox.shrink();
                return Material(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.accent.withValues(alpha: 0.15)
                      : AppColors.accentSurface,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign_outlined,
                            color: AppColors.accent, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            ann,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _announcementDismissed = true),
                          child: const Icon(Icons.close, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            Expanded(
              child: chat.loading && messages.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                      ? Center(
                          child: AppText(
                          _searchQuery.isEmpty ? '暂无消息，发一条消息吧' : '未找到匹配消息',
                          isSmall: true,
                        ))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: messages.length,
                          itemBuilder: (ctx, i) {
                            final msg = messages[i];
                            final isMsgMe = msg.sendID == ApiConfig.userID;
                            final selected =
                                chat.selectedMsgIDs.contains(msg.clientMsgID);
                            final retrying =
                                chat.isRetryingMsg(msg.clientMsgID);
                            return Column(
                              crossAxisAlignment: isMsgMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                MessageBubble(
                                  message: msg,
                                  isMe: isMsgMe,
                                  isSelected: selected,
                                  showSenderName:
                                      widget.sessionType == 3 && !isMsgMe,
                                  reactions:
                                      reactionsMap[msg.clientMsgID] ?? {},
                                  allImageUrls: allImageUrls,
                                  onAvatarTap: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: (_) => UserDetailPage(
                                        targetUserID: msg.sendID,
                                        nickname: msg.senderNickname,
                                        faceURL: msg.senderFaceURL,
                                      ),
                                    ));
                                  },
                                  onReactionTap: (emoji) {
                                    // 再次点击同一 reaction => 撤回（暂时取消）
                                    // 简单起见：始终添加自己的 reaction
                                    final recvID =
                                        widget.conversationID.contains('sg_')
                                            ? widget.conversationID
                                                .replaceFirst('sg_', '')
                                            : msg.sendID == ApiConfig.userID
                                                ? widget.conversationID
                                                : msg.sendID;
                                    chat.sendReaction(
                                      recvID: recvID,
                                      reactToMsgID: msg.clientMsgID,
                                      emoji: emoji,
                                      sessionType: widget.sessionType,
                                    );
                                  },
                                  onLongPress: () => isMulti
                                      ? chat.toggleSelect(msg.clientMsgID)
                                      : _showMessageActions(ctx, msg),
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
                                            fontSize: 11,
                                            color: AppColors.activity),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
            ),
            // 回复预览条
            if (chat.replyingTo != null)
              _ReplyBar(
                message: chat.replyingTo!,
                onCancel: () => chat.setReplyingTo(null),
              ),
            // 多选操作栏
            if (isMulti)
              _MultiSelectBar(
                count: chat.selectedMsgIDs.length,
                onDelete: () {
                  chat.deleteMessageForSelf(
                    conversationID: widget.conversationID,
                    clientMsgIDs: chat.selectedMsgIDs.toList(),
                  );
                  chat.clearMultiSelect();
                },
                onCancel: chat.clearMultiSelect,
                onMergeForward: () => _showMergeForwardPicker(context, chat),
              )
            else if (!_searchMode)
              MessageInput(
                onSend: _sendText,
                onAttach: _handleAttach,
              ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ChatController chat) {
    if (chat.multiSelectMode) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: chat.clearMultiSelect,
        ),
        title: Text('已选 ${chat.selectedMsgIDs.length} 条'),
      );
    }

    return AppBar(
      title: Builder(builder: (ctx) {
        final auth = ctx.watch<AuthController>();
        final canViewIP = auth.currentUser?.canViewIP ?? false;
        // 金色官方徽章优先于蓝色管理员徽章
        Widget? badge;
        if (widget.isOfficialUser >= 1 || widget.isOfficialGroup) {
          badge = const VerifiedBadge.gold(size: 18);
        } else if (widget.appRole >= 1) {
          badge = const VerifiedBadge(size: 18);
        }
        // 单聊时显示最后上线时间
        final statusCtrl = ctx.watch<StatusController>();
        final status = widget.sessionType == 1 && widget.recvID.isNotEmpty
            ? statusCtrl.getStatus(widget.recvID)
            : null;
        final subtitle = status?.lastSeenText;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: AppText(widget.title, isTitle: true)),
                if (badge != null) badge,
                if (canViewIP && widget.recvID.isNotEmpty)
                  ConversationIPBadge(partnerUserID: widget.recvID),
              ],
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: status!.isOnline ? AppColors.success : Colors.white70,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        );
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: '搜索消息',
          onPressed: () => setState(() {
            _searchMode = !_searchMode;
            if (!_searchMode) {
              _searchQuery = '';
              _searchCtrl.clear();
            }
          }),
        ),
        if (widget.sessionType == 3 && widget.groupID.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '群详情',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupDetailPage(groupID: widget.groupID),
                ),
              );
            },
          ),
        if (widget.sessionType == 1 && widget.recvID.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: '用户详情',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UserDetailPage(
                    targetUserID: widget.recvID,
                    nickname: widget.title,
                    faceURL: '',
                    appRole: widget.appRole,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// ─── Reply preview bar ───────────────────────────────────────────────────────

class _ReplyBar extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const _ReplyBar({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '回复 ${message.senderNickname}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  message.previewText,
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
            onPressed: onCancel,
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

// ─── Multi-select bottom bar ──────────────────────────────────────────────────

class _MultiSelectBar extends StatelessWidget {
  final int count;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback onMergeForward;

  const _MultiSelectBar({
    required this.count,
    required this.onDelete,
    required this.onCancel,
    required this.onMergeForward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.close),
            label: const Text('取消'),
          ),
          TextButton.icon(
            onPressed: count > 0 ? onDelete : null,
            icon: Icon(Icons.delete_outline,
                color: count > 0 ? AppColors.danger : AppColors.disabled),
            label: Text('删除 ($count)',
                style: TextStyle(
                    color: count > 0 ? AppColors.danger : AppColors.disabled)),
          ),
          TextButton.icon(
            onPressed: count > 0 ? onMergeForward : null,
            icon: const Icon(Icons.forward_to_inbox_outlined),
            label: Text('合并转发 ($count)'),
          ),
        ],
      ),
    );
  }
}

// ─── Message actions sheet ────────────────────────────────────────────────────

enum _MsgAction {
  copy,
  reply,
  star,
  revoke,
  edit,
  pin,
  groupDelete,
  delete,
  multiSelect,
  forward,
  react,
}

class _MessageActionsSheet extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isStarred;
  final bool canRecall;
  final bool canEdit;
  final bool canGroupDelete;
  final bool canPin;
  final bool isGroupChat;
  final ValueChanged<_MsgAction> onAction;

  const _MessageActionsSheet({
    required this.message,
    required this.isMe,
    required this.isStarred,
    required this.canRecall,
    required this.canEdit,
    required this.canGroupDelete,
    required this.canPin,
    required this.isGroupChat,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
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
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              if (message.isText)
                _ActionChip(
                  icon: Icons.copy_outlined,
                  label: '复制',
                  onTap: () => onAction(_MsgAction.copy),
                ),
              _ActionChip(
                icon: Icons.reply_outlined,
                label: '回复',
                onTap: () => onAction(_MsgAction.reply),
              ),
              _ActionChip(
                icon: isStarred ? Icons.star : Icons.star_outline,
                label: isStarred ? '取消收藏' : '收藏',
                color: AppColors.accent,
                onTap: () => onAction(_MsgAction.star),
              ),
              _ActionChip(
                icon: Icons.forward_to_inbox_outlined,
                label: '转发',
                onTap: () => onAction(_MsgAction.forward),
              ),
              _ActionChip(
                icon: Icons.add_reaction_outlined,
                label: '表情回应',
                color: AppColors.accent,
                onTap: () => onAction(_MsgAction.react),
              ),
              if (canEdit)
                _ActionChip(
                  icon: Icons.edit_outlined,
                  label: '编辑',
                  color: AppColors.primary,
                  onTap: () => onAction(_MsgAction.edit),
                ),
              if (canRecall)
                _ActionChip(
                  icon: Icons.undo_outlined,
                  label: '撤回',
                  onTap: () => onAction(_MsgAction.revoke),
                ),
              if (canPin)
                _ActionChip(
                  icon: Icons.push_pin_outlined,
                  label: '置顶',
                  color: AppColors.accent,
                  onTap: () => onAction(_MsgAction.pin),
                ),
              if (canGroupDelete)
                _ActionChip(
                  icon: Icons.delete_forever_outlined,
                  label: '删除(群主)',
                  color: AppColors.danger,
                  onTap: () => onAction(_MsgAction.groupDelete),
                ),
              _ActionChip(
                icon: Icons.delete_outline,
                label: '删除(仅自己)',
                color: AppColors.danger,
                onTap: () => onAction(_MsgAction.delete),
              ),
              _ActionChip(
                icon: Icons.check_box_outlined,
                label: '多选',
                onTap: () => onAction(_MsgAction.multiSelect),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    this.color = AppColors.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(label,
                style: TextStyle(fontSize: 12, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
