import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/group_api.dart';
import '../../../../core/controllers/conversation_controller.dart';
import '../../../../core/controllers/group_controller.dart';
import '../../../../core/models/group.dart';
import '../../../../core/models/group_member.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/spacing.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/verified_badge.dart';
import 'group_member_list_page.dart';

/// 群详情页
class GroupDetailPage extends StatefulWidget {
  final String groupID;

  const GroupDetailPage({super.key, required this.groupID});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  List<GroupMember> _members = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final ctrl = context.read<GroupController>();
    final members = await ctrl.loadGroupMembers(widget.groupID);
    if (mounted) setState(() => _members = members);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupController>();
    final group = ctrl.getById(widget.groupID);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('群详情')),
        body: const Center(child: Text('群信息不存在')),
      );
    }

    final myUserID = ApiConfig.userID;
    final isOwner = group.ownerUserID == myUserID;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('群详情'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditGroupDialog(context, group),
              tooltip: '编辑群信息',
            ),
        ],
      ),
      body: ListView(
        children: [
          // ── 群头像 + 名称 + 人数 ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                UserAvatar(
                  faceURL: group.faceURL,
                  nickname: group.groupName,
                  size: 72,
                ),
                const SizedBox(height: AppSpacing.md),
                GroupNameWithBadge(
                  name: group.groupName,
                  isOfficialGroup: group.isOfficialGroup,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                  badgeSize: 18,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${group.memberCount} 位成员',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (group.maxMemberCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '(上限 ${group.maxMemberCount} 人)',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
                if (group.introduction.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    group.introduction,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // ── 成员预览（最多 5 人） ──────────────────────────────────────────
          _SectionCard(
            title: '群成员 (${_members.length})',
            trailing: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupMemberListPage(groupID: widget.groupID),
                ),
              ),
              child: const Text('查看全部 >'),
            ),
            child: _members.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: _members.length > 5
                          ? 6
                          : _members.length + (isOwner ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i == 5 || i == _members.length) {
                          return _AddMemberButton(onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GroupMemberListPage(
                                    groupID: widget.groupID),
                              ),
                            );
                          });
                        }
                        final m = _members[i];
                        return _MemberPreview(member: m);
                      },
                    ),
                  ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── 群公告 ──────────────────────────────────────────────────────
          _SectionCard(
            title: '群公告',
            trailing: (isOwner || ctrl.isAdminOrOwner(widget.groupID))
                ? TextButton(
                    onPressed: () => _showAnnouncementDialog(context, group),
                    child: const Text('编辑',
                        style: TextStyle(color: AppColors.primary)),
                  )
                : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
              child: group.announcement.isNotEmpty
                  ? Text(
                      group.announcement,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textPrimary),
                    )
                  : Text(
                      isOwner ? '点击「编辑」发布群公告' : '暂无群公告',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── 邀请链接 ────────────────────────────────────────────────────
          _SectionCard(
            title: '群邀请',
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  const Icon(Icons.link, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text('生成群邀请链接，分享给好友加入群聊'),
                  ),
                  ElevatedButton(
                    onPressed: () => _showInviteDialog(context, group),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    ),
                    child: const Text('邀请'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── 设置 ────────────────────────────────────────────────────────
          Builder(builder: (context) {
            final convCtrl = context.watch<ConversationController>();
            final convID = 'sg_${widget.groupID}';
            final conv = convCtrl.getById(convID);
            final isPinned = conv?.isPinned ?? false;
            final isMuted = conv?.isMuted ?? false;
            return _SectionCard(
              title: '设置',
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.push_pin_outlined,
                    label: '置顶该群聊',
                    trailing: Switch(
                      value: isPinned,
                      onChanged: (val) {
                        convCtrl.pinConversation(convID, pinned: val);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.volume_off_outlined,
                    label: '消息免打扰',
                    trailing: Switch(
                      value: isMuted,
                      onChanged: (val) {
                        convCtrl.setMuteStatus(convID, recvMsgOpt: val ? 2 : 0);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  if (isOwner)
                    _SettingTile(
                      icon: Icons.do_not_disturb_on_outlined,
                      label: '全员禁言',
                      trailing: Switch(
                        value: group.isMuted,
                        onChanged: (val) => context
                            .read<GroupController>()
                            .muteGroup(groupID: widget.groupID, muted: val),
                        activeColor: AppColors.primary,
                      ),
                    ),
                  if (isOwner)
                    _SettingTile(
                      icon: Icons.people_outline,
                      label: '成员上限',
                      trailing: Text(
                        '${group.maxMemberCount}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                      onTap: () => _showMaxMemberDialog(context, group),
                    ),
                ],
              ),
            );
          }),

          const SizedBox(height: AppSpacing.md),

          // ── 危险操作区 ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                if (isOwner) ...[
                  _DangerButton(
                    label: '转让群主',
                    color: AppColors.accent,
                    onTap: () => _showTransferDialog(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DangerButton(
                    label: '解散该群',
                    onTap: () => _confirmDismiss(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _DangerButton(
                  label: '退出群聊',
                  onTap: () => _confirmQuit(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _showInviteDialog(BuildContext ctx, Group group) {
    final link =
        context.read<GroupController>().generateInviteLink(group.groupID);
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('群邀请链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.pageBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                link,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              '有效期 7 天，点击下方按钮复制或分享',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: link));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制到剪贴板')),
              );
            },
            child: const Text('复制'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              Share.share(
                '加入群聊「${group.groupName}」：$link',
                subject: '群邀请链接',
              );
            },
            child: const Text('分享'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext ctx, Group group) {
    final ctrl = TextEditingController(text: group.announcement);
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('群公告'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '输入群公告内容…',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          maxLength: 500,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<GroupController>().updateGroupInfo(
                    groupID: widget.groupID,
                    announcement: ctrl.text.trim(),
                  );
            },
            child: const Text('发布', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showMaxMemberDialog(BuildContext ctx, Group group) {
    final ctrl = TextEditingController(text: '${group.maxMemberCount}');
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('设置成员上限'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: '请输入数字（如500、1000）',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim());
              if (val == null || val < 1) return;
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(ctx);
              try {
                final resp = await GroupApi.setMaxMemberCount(
                  groupID: widget.groupID,
                  maxMemberCount: val,
                );
                if (!mounted) return;
                if (resp['errCode'] == 0) {
                  context.read<GroupController>().updateGroupInfo(
                        groupID: widget.groupID,
                      );
                  messenger.showSnackBar(
                    SnackBar(content: Text('成员上限已更新为 $val')),
                  );
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('设置失败，请稍后重试')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                debugPrint('设置成员上限异常: $e');
                messenger.showSnackBar(
                  const SnackBar(content: Text('网络错误，请稍后重试')),
                );
              }
            },
            child: const Text('确定', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showEditGroupDialog(BuildContext ctx, Group group) {
    final nameCtrl = TextEditingController(text: group.groupName);
    final introCtrl = TextEditingController(text: group.introduction);
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('编辑群信息'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: '群名称')),
            const SizedBox(height: AppSpacing.md),
            TextField(
                controller: introCtrl,
                decoration: const InputDecoration(labelText: '群简介'),
                maxLines: 3),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.read<GroupController>().updateGroupInfo(
                    groupID: widget.groupID,
                    name: nameCtrl.text.trim().isNotEmpty
                        ? nameCtrl.text.trim()
                        : null,
                    introduction: introCtrl.text.trim().isNotEmpty
                        ? introCtrl.text.trim()
                        : null,
                  );
            },
            child: const Text('保存', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog(BuildContext ctx) {
    // Only show members that are NOT the current owner
    final candidates =
        _members.where((m) => m.userID != ApiConfig.userID).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('群内没有其他成员，无法转让')),
      );
      return;
    }
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('转让群主'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: candidates.length,
            itemBuilder: (_, i) {
              final m = candidates[i];
              return ListTile(
                leading: UserAvatar(
                    faceURL: m.faceURL, nickname: m.nickname, size: 36),
                title: Text(m.nickname),
                subtitle: Text(m.roleLabel.isNotEmpty ? m.roleLabel : '成员',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                onTap: () => _confirmTransfer(ctx, m),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }

  void _confirmTransfer(BuildContext ctx, GroupMember target) {
    Navigator.of(ctx).pop(); // close member picker
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('确认转让'),
        content: Text('确定将群主转让给「${target.nickname}」吗？\n转让后你将变为普通成员。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(ctx);
              try {
                final resp = await GroupApi.transferGroupOwner(
                  groupID: widget.groupID,
                  newOwnerUserID: target.userID,
                );
                if (!mounted) return;
                if ((resp['errCode'] ?? 0) == 0) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('已转让群主给 ${target.nickname}')),
                  );
                  await _load(); // 刷新成员列表 + 群信息
                  if (!mounted) return;
                  context.read<GroupController>().loadJoinedGroups(); // 刷新群列表
                } else {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('转让失败，请稍后重试')),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                debugPrint('转让群主异常: $e');
                messenger.showSnackBar(
                  const SnackBar(content: Text('网络错误，请稍后重试')),
                );
              }
            },
            child:
                const Text('确认转让', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _confirmDismiss(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('解散群聊'),
        content: const Text('确定要解散该群聊吗？此操作不可恢复。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await context
                  .read<GroupController>()
                  .dismissGroup(widget.groupID);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).popUntil((r) => r.isFirst);
              }
            },
            child: const Text('解散', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _confirmQuit(BuildContext ctx) {
    showDialog<void>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('退出群聊'),
        content: const Text('确定要退出该群聊吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final ok = await context
                  .read<GroupController>()
                  .quitGroup(widget.groupID);
              if (ok && ctx.mounted) {
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('退出', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _MemberPreview extends StatelessWidget {
  final GroupMember member;

  const _MemberPreview({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              UserAvatar(
                  faceURL: member.faceURL, nickname: member.nickname, size: 48),
              if (member.isOwner)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star, size: 8, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 48,
            child: Text(
              member.nickname,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMemberButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMemberButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 2),
            const Text('添加', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DangerButton({required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.danger;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label),
      ),
    );
  }
}
