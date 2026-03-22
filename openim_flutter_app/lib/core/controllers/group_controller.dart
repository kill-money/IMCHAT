import 'package:flutter/foundation.dart';
import '../api/group_api.dart';
import '../api/api_client.dart';
import '../models/group.dart';
import '../models/group_member.dart';

class GroupController extends ChangeNotifier {
  List<Group> _groups = [];
  final Map<String, List<GroupMember>> _membersMap = {};
  bool _loading = false;

  List<Group> get groups => _groups;
  bool get loading => _loading;

  void debugPrintState() {
    debugPrint('[GroupController] loading=$_loading groups=${_groups.length}');
  }

  List<GroupMember> membersOf(String groupID) => _membersMap[groupID] ?? [];

  // ─── Load ─────────────────────────────────────────────────────────────────

  Future<void> loadJoinedGroups() async {
    _loading = true;
    notifyListeners();
    try {
      final res = await GroupApi.getJoinedGroupList();
      final list = (res['data']?['groups'] as List?) ?? [];
      _groups =
          list.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('加载群列表失败: $e');
    }
    _loading = false;
    notifyListeners();
  }

  Future<List<GroupMember>> loadGroupMembers(String groupID) async {
    try {
      final res = await GroupApi.getGroupMemberList(groupID: groupID);
      final list = (res['data']?['members'] as List?) ?? [];
      final members = list
          .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
          .toList();
      _membersMap[groupID] = members;
      notifyListeners();
      return members;
    } catch (e) {
      if (kDebugMode) debugPrint('加载群成员失败: $e');
      return [];
    }
  }

  // ─── Create / Modify ──────────────────────────────────────────────────────

  Future<Group?> createGroup({
    required String groupName,
    required List<String> memberUserIDs,
    String faceURL = '',
    String introduction = '',
  }) async {
    try {
      final res = await GroupApi.createGroup(
        groupName: groupName,
        memberUserIDs: memberUserIDs,
        faceURL: faceURL,
        introduction: introduction,
      );
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        debugPrint(
            '[GroupController] 创建群失败: errCode=$errCode errMsg=${res['errMsg']}');
        return null;
      }
      final groupData = res['data']?['groupInfo'];
      if (groupData != null) {
        final group = Group.fromJson(groupData as Map<String, dynamic>);
        _groups.insert(0, group);
        notifyListeners();
        return group;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('创建群失败: $e');
    }
    return null;
  }

  Future<bool> inviteMembers({
    required String groupID,
    required List<String> userIDs,
  }) async {
    try {
      await GroupApi.inviteUserToGroup(
          groupID: groupID, invitedUserIDs: userIDs);
      await loadGroupMembers(groupID);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('邀请成员失败: $e');
      return false;
    }
  }

  Future<bool> removeMembers({
    required String groupID,
    required List<String> userIDs,
  }) async {
    try {
      await GroupApi.kickGroupMember(groupID: groupID, kickedUserIDs: userIDs);
      _membersMap[groupID]?.removeWhere((m) => userIDs.contains(m.userID));
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('移除成员失败: $e');
      return false;
    }
  }

  Future<bool> setMemberRole({
    required String groupID,
    required String userID,
    required int roleLevel,
  }) async {
    try {
      await GroupApi.setGroupMemberInfo(
          groupID: groupID, userID: userID, roleLevel: roleLevel);
      final members = _membersMap[groupID];
      if (members != null) {
        final idx = members.indexWhere((m) => m.userID == userID);
        if (idx >= 0) {
          members[idx] = members[idx].copyWith(roleLevel: roleLevel);
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint('设置角色失败: $e');
      return false;
    }
  }

  Future<bool> updateGroupInfo({
    required String groupID,
    String? name,
    String? faceURL,
    String? introduction,
    String? announcement,
  }) async {
    try {
      await GroupApi.setGroupInfo(
        groupID: groupID,
        groupName: name,
        faceURL: faceURL,
        introduction: introduction,
        announcement: announcement,
      );
      final idx = _groups.indexWhere((g) => g.groupID == groupID);
      if (idx >= 0) {
        _groups[idx] = _groups[idx].copyWith(
          groupName: name,
          faceURL: faceURL,
          introduction: introduction,
          announcement: announcement,
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('修改群信息失败: $e');
      return false;
    }
  }

  /// 禁言 / 解除禁言群成员（seconds=0 解除）
  Future<bool> muteMember({
    required String groupID,
    required String userID,
    required int seconds,
  }) async {
    try {
      await GroupApi.muteGroupMember(
          groupID: groupID, userID: userID, seconds: seconds);
      final members = _membersMap[groupID];
      if (members != null) {
        final idx = members.indexWhere((m) => m.userID == userID);
        if (idx >= 0) {
          final endTime = seconds == 0
              ? 0
              : DateTime.now().millisecondsSinceEpoch ~/ 1000 + seconds;
          members[idx] = members[idx].copyWith(muteEndTime: endTime);
          notifyListeners();
        }
      }
      return true;
    } catch (e) {
      debugPrint('禁言操作失败: $e');
      return false;
    }
  }

  Future<bool> muteGroup({
    required String groupID,
    required bool muted,
  }) async {
    try {
      await GroupApi.muteGroup(groupID: groupID, muted: muted);
      final idx = _groups.indexWhere((g) => g.groupID == groupID);
      if (idx >= 0) {
        _groups[idx] = _groups[idx].copyWith(isMuted: muted);
        notifyListeners();
      }
      return true;
    } catch (e) {
      debugPrint('全员禁言操作失败: $e');
      return false;
    }
  }

  Future<bool> dismissGroup(String groupID) async {
    try {
      await GroupApi.dismissGroup(groupID: groupID);
      _groups.removeWhere((g) => g.groupID == groupID);
      _membersMap.remove(groupID);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('解散群失败: $e');
      return false;
    }
  }

  Future<bool> quitGroup(String groupID) async {
    try {
      await GroupApi.quitGroup(groupID: groupID);
      _groups.removeWhere((g) => g.groupID == groupID);
      _membersMap.remove(groupID);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('退出群失败: $e');
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Group? getById(String groupID) {
    try {
      return _groups.firstWhere((g) => g.groupID == groupID);
    } catch (_) {
      return null;
    }
  }

  bool isOwner(String groupID) =>
      getById(groupID)?.ownerUserID == ApiConfig.userID;

  /// 获取当前用户在指定群中的成员信息
  GroupMember? getMyMember(String groupID) {
    final members = membersOf(groupID);
    try {
      return members.firstWhere((m) => m.userID == ApiConfig.userID);
    } catch (_) {
      return null;
    }
  }

  bool isAdmin(String groupID) {
    try {
      return membersOf(groupID)
          .firstWhere((m) => m.userID == ApiConfig.userID)
          .isAdmin;
    } catch (_) {
      return false;
    }
  }

  bool isAdminOrOwner(String groupID) {
    final members = membersOf(groupID);
    try {
      return members.firstWhere((m) => m.userID == ApiConfig.userID).isAdmin;
    } catch (_) {
      return false;
    }
  }

  /// 生成群邀请链接（deeplink 格式，可分享给他人扫码/点击加入）
  String generateInviteLink(String groupID) {
    return 'openim://${ApiConfig.apiHost}/join_group?group_id=$groupID&inviter=${ApiConfig.userID}';
  }

  @override
  void dispose() {
    _groups.clear();
    _membersMap.clear();
    super.dispose();
  }
}
