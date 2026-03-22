import 'group_member.dart';

/// 群权限体系 — 集中定义群主/管理员/普通成员的操作权限
///
/// | 功能             | 群主 | 管理员 | 普通成员 |
/// |-----------------|------|--------|---------|
/// | 删除他人消息      | ✅   | ❌     | ❌      |
/// | 撤回自己消息      | ✅   | ✅     | ✅      |
/// | 编辑自己消息      | ✅   | ✅     | ✅      |
/// | 群公告/置顶       | ✅   | ✅     | ❌      |
/// | 踢人             | ✅   | ✅     | ❌      |
/// | 修改群人数上限    | ✅   | ❌     | ❌      |
/// | 转让群主          | ✅   | ❌     | ❌      |
/// | 解散群            | ✅   | ❌     | ❌      |
/// | 设置管理员        | ✅   | ❌     | ❌      |
/// | 禁言成员          | ✅   | ✅     | ❌      |
class GroupPermission {
  final int roleLevel;

  const GroupPermission(this.roleLevel);

  bool get isOwner => roleLevel == GroupMemberRole.owner;
  bool get isAdmin => roleLevel >= GroupMemberRole.admin;
  bool get isMember => roleLevel >= GroupMemberRole.member;

  /// 能否删除他人消息（仅群主）
  bool get canDeleteOthersMessage => isOwner;

  /// 能否撤回自己的消息（所有人）
  bool get canRevokeSelfMessage => isMember;

  /// 能否编辑自己的消息（所有人）
  bool get canEditSelfMessage => isMember;

  /// 能否设置群公告
  bool get canSetAnnouncement => isAdmin;

  /// 能否置顶消息
  bool get canPinMessage => isAdmin;

  /// 能否踢人
  bool get canKickMember => isAdmin;

  /// 能否修改群人数上限（仅群主）
  bool get canSetMaxMemberCount => isOwner;

  /// 能否转让群主
  bool get canTransferOwnership => isOwner;

  /// 能否解散群
  bool get canDismissGroup => isOwner;

  /// 能否设置管理员
  bool get canSetAdmin => isOwner;

  /// 能否禁言成员
  bool get canMuteMember => isAdmin;

  /// 能否邀请新成员
  bool get canInvite => isAdmin;
}
