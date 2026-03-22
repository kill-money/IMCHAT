import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/group_api.dart';
import '../../../../core/controllers/group_controller.dart';
import '../../../../core/models/group_member.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/spacing.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../../../../shared/widgets/verified_badge.dart';

/// 群成员列表页（全量展示 + 管理功能）
class GroupMemberListPage extends StatefulWidget {
  final String groupID;

  const GroupMemberListPage({super.key, required this.groupID});

  @override
  State<GroupMemberListPage> createState() => _GroupMemberListPageState();
}

class _GroupMemberListPageState extends State<GroupMemberListPage> {
  List<GroupMember> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final members =
        await context.read<GroupController>().loadGroupMembers(widget.groupID);
    if (mounted) {
      setState(() {
        _members = members;
        _loading = false;
      });
    }
  }

  bool get _amOwnerOrAdmin {
    final ctrl = context.read<GroupController>();
    return ctrl.isOwner(widget.groupID) || ctrl.isAdmin(widget.groupID);
  }

  bool get _amOwner => context.read<GroupController>().isOwner(widget.groupID);

  Future<void> _removeMember(GroupMember member) async {
    final ok = await context.read<GroupController>().removeMembers(
      groupID: widget.groupID,
      userIDs: [member.userID],
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _members.removeWhere((m) => m.userID == member.userID));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('移除成员失败')));
    }
  }

  Future<void> _muteMember(GroupMember member, int seconds) async {
    final ctrl = context.read<GroupController>();
    final ok = await ctrl.muteMember(
      groupID: widget.groupID,
      userID: member.userID,
      seconds: seconds,
    );
    if (!mounted) return;
    if (ok) {
      await _load();
      if (!mounted) return;
      final msg = seconds == 0 ? '已解除禁言' : '禁言成功';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('操作失败')));
    }
  }

  void _showMuteDurationPicker(GroupMember member) {
    const options = [
      ('10 分钟', 600),
      ('1 小时', 3600),
      ('8 小时', 28800),
      ('1 天', 86400),
      ('7 天', 604800),
    ];
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('选择禁言时长',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
              ...options.map(
                (e) => ListTile(
                  title: Text(e.$1),
                  onTap: () {
                    Navigator.of(context).pop();
                    _muteMember(member, e.$2);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberActions(GroupMember member) {
    final myID = ApiConfig.userID;
    final amOwner = _amOwner;

    if (member.userID == myID) return; // 不对自己操作

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
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
              leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary)),
              title: Text(member.nickname),
              subtitle:
                  Text(member.roleLabel.isNotEmpty ? member.roleLabel : '普通成员'),
            ),
            const Divider(),
            // 设置/取消管理员（群主操作）
            if (amOwner && !member.isOwner)
              ListTile(
                leading: Icon(
                  member.isAdmin
                      ? Icons.remove_moderator_outlined
                      : Icons.admin_panel_settings_outlined,
                  color: AppColors.primary,
                ),
                title: Text(member.isAdmin ? '取消管理员' : '设为管理员'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await context.read<GroupController>().setMemberRole(
                        groupID: widget.groupID,
                        userID: member.userID,
                        roleLevel: member.isAdmin
                            ? GroupMemberRole.member
                            : GroupMemberRole.admin,
                      );
                  await _load();
                },
              ),
            // 转让群主（群主操作）
            if (amOwner && !member.isOwner)
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppColors.accent),
                title: const Text('转让群主'),
                onTap: () {
                  Navigator.of(context).pop();
                  _confirmTransferOwner(member);
                },
              ),
            // 移除成员（群主或管理员，但不能移除群主）
            if (_amOwnerOrAdmin && !member.isOwner)
              ListTile(
                leading: const Icon(Icons.person_remove_outlined,
                    color: AppColors.danger),
                title: const Text('移出群聊',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Navigator.of(context).pop();
                  _removeMember(member);
                },
              ),
            // 禁言 / 解除禁言（群主或管理员，不能禁言群主）
            if (_amOwnerOrAdmin && !member.isOwner)
              ListTile(
                leading: Icon(
                  member.isMuted
                      ? Icons.volume_up_outlined
                      : Icons.volume_off_outlined,
                  color: AppColors.accent,
                ),
                title: Text(member.isMuted ? '解除禁言' : '禁言'),
                onTap: () {
                  Navigator.of(context).pop();
                  if (member.isMuted) {
                    _muteMember(member, 0);
                  } else {
                    _showMuteDurationPicker(member);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  void _confirmTransferOwner(GroupMember target) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认转让群主'),
        content: Text('确定将群主转让给「${target.nickname}」吗？\n转让后你将变为普通成员。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final messenger = ScaffoldMessenger.of(context);
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
                  await _load();
                  if (!mounted) return;
                  await context.read<GroupController>().loadJoinedGroups();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text('群成员 (${_members.length})'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('暂无成员信息'))
              : ListView.separated(
                  itemCount: _members.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 0.5, indent: 72, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final m = _members[i];
                    return ListTile(
                      onTap: () => _showMemberActions(m),
                      leading: UserAvatar(
                          faceURL: m.faceURL, nickname: m.nickname, size: 44),
                      title: Row(
                        children: [
                          Flexible(
                            child: UserNameWithBadge(
                              nickname: m.nickname,
                              appRole: m.appRole,
                              isOfficial: m.isOfficial,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (m.roleLabel.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: m.isOwner
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                m.roleLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: m.isOwner
                                      ? AppColors.accent
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text('加入时间: ${_formatDate(m.joinTime)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    );
                  },
                ),
    );
  }

  String _formatDate(int ms) {
    if (ms == 0) return '未知';
    final d = DateTime.fromMillisecondsSinceEpoch(ms * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
