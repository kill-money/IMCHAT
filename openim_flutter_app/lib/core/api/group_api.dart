/// OpenIM Group API endpoints
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart' as sdk;
import 'api_client.dart';

class GroupApi {
  /// 由 _HomeWrapper 设置，控制是否通过 SDK 路由群组操作
  static bool useSDK = false;

  /// SDK GroupInfo → HTTP 兼容 Map（补齐 createdTime 等 key 差异）
  static Map<String, dynamic> _groupToMap(sdk.GroupInfo g) {
    final m = g.toJson();
    // Group.fromJson 期望 'createdTime'，SDK 输出 'createTime'
    m['createdTime'] = m['createTime'] ?? 0;
    return m;
  }

  /// SDK GroupMembersInfo → HTTP 兼容 Map
  static Map<String, dynamic> _memberToMap(sdk.GroupMembersInfo m) =>
      m.toJson();

  /// 创建群
  static Future<Map<String, dynamic>> createGroup({
    required String groupName,
    required List<String> memberUserIDs,
    String faceURL = '',
    String introduction = '',
    int groupType = 2,
  }) async {
    if (useSDK) {
      try {
        final info = await sdk.OpenIM.iMManager.groupManager.createGroup(
          groupInfo: sdk.GroupInfo(
            groupID: '',
            groupName: groupName,
            faceURL: faceURL,
            introduction: introduction,
            groupType: groupType,
          ),
          memberUserIDs: memberUserIDs,
        );
        return {
          'errCode': 0,
          'data': {'groupInfo': _groupToMap(info)}
        };
      } catch (e) {
        debugPrint('[GroupApi] SDK createGroup error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/create_group', {
      'ownerUserID': ApiConfig.userID,
      'groupInfo': {
        'groupType': groupType,
        'groupName': groupName,
        'faceURL': faceURL,
        'introduction': introduction,
      },
      'memberUserIDs': memberUserIDs,
      'adminUserIDs': <String>[],
    });
  }

  /// 邀请成员入群
  static Future<Map<String, dynamic>> inviteUserToGroup({
    required String groupID,
    required List<String> invitedUserIDs,
    String reason = '',
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.inviteUserToGroup(
          groupID: groupID,
          userIDList: invitedUserIDs,
          reason: reason,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK inviteUserToGroup error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/invite_user_to_group', {
      'groupID': groupID,
      'invitedUserIDs': invitedUserIDs,
      'reason': reason,
    });
  }

  /// 踢出群成员
  static Future<Map<String, dynamic>> kickGroupMember({
    required String groupID,
    required List<String> kickedUserIDs,
    String reason = '',
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.kickGroupMember(
          groupID: groupID,
          userIDList: kickedUserIDs,
          reason: reason,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK kickGroupMember error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/kick_group_member', {
      'groupID': groupID,
      'kickedUserIDs': kickedUserIDs,
      'reason': reason,
    });
  }

  /// 获取群信息
  static Future<Map<String, dynamic>> getGroupsInfo({
    required List<String> groupIDs,
  }) async {
    if (useSDK) {
      try {
        final list = await sdk.OpenIM.iMManager.groupManager.getGroupsInfo(
          groupIDList: groupIDs,
        );
        return {
          'errCode': 0,
          'data': {'groups': list.map(_groupToMap).toList()},
        };
      } catch (e) {
        debugPrint('[GroupApi] SDK getGroupsInfo error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/get_groups_info', {'groupIDs': groupIDs});
  }

  /// 获取群成员列表
  static Future<Map<String, dynamic>> getGroupMemberList({
    required String groupID,
    int pageNumber = 1,
    int showNumber = 100,
    int filter = 0,
  }) async {
    if (useSDK) {
      try {
        final list = await sdk.OpenIM.iMManager.groupManager.getGroupMemberList(
          groupID: groupID,
          count: showNumber,
          offset: (pageNumber - 1) * showNumber,
          filter: filter,
        );
        return {
          'errCode': 0,
          'data': {'members': list.map(_memberToMap).toList()},
        };
      } catch (e) {
        debugPrint('[GroupApi] SDK getGroupMemberList error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/get_group_member_list', {
      'groupID': groupID,
      'filter': filter,
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  /// 获取已加入的群列表
  static Future<Map<String, dynamic>> getJoinedGroupList({
    int pageNumber = 1,
    int showNumber = 100,
  }) async {
    if (useSDK) {
      try {
        final list =
            await sdk.OpenIM.iMManager.groupManager.getJoinedGroupList();
        return {
          'errCode': 0,
          'data': {'groups': list.map(_groupToMap).toList()},
        };
      } catch (e) {
        debugPrint('[GroupApi] SDK getJoinedGroupList error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/get_joined_group_list', {
      'fromUserID': ApiConfig.userID,
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  /// 设置群成员角色（roleLevel: 20=成员, 60=管理员）
  static Future<Map<String, dynamic>> setGroupMemberInfo({
    required String groupID,
    required String userID,
    int? roleLevel,
    String? nickname,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.setGroupMemberInfo(
          groupMembersInfo: sdk.SetGroupMemberInfo(
            groupID: groupID,
            userID: userID,
            roleLevel: roleLevel,
            nickname: nickname,
          ),
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK setGroupMemberInfo error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/set_group_member_info', {
      'members': [
        {
          'groupID': groupID,
          'userID': userID,
          if (roleLevel != null) 'roleLevel': roleLevel,
          if (nickname != null) 'nickname': nickname,
        }
      ],
    });
  }

  /// 转让群主
  static Future<Map<String, dynamic>> transferGroupOwner({
    required String groupID,
    required String newOwnerUserID,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.transferGroupOwner(
          groupID: groupID,
          userID: newOwnerUserID,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK transferGroupOwner error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/transfer_group', {
      'groupID': groupID,
      'newOwnerUserID': newOwnerUserID,
    });
  }

  /// 解散群（群主专用）
  static Future<Map<String, dynamic>> dismissGroup({
    required String groupID,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.dismissGroup(groupID: groupID);
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK dismissGroup error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/dismiss_group', {'groupID': groupID});
  }

  /// 退出群
  static Future<Map<String, dynamic>> quitGroup({
    required String groupID,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.quitGroup(groupID: groupID);
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK quitGroup error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/quit_group', {'groupID': groupID});
  }

  /// 修改群信息
  static Future<Map<String, dynamic>> setGroupInfo({
    required String groupID,
    String? groupName,
    String? faceURL,
    String? introduction,
    String? announcement,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.setGroupInfo(
          sdk.GroupInfo(
            groupID: groupID,
            groupName: groupName,
            faceURL: faceURL,
            introduction: introduction,
            notification: announcement,
          ),
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK setGroupInfo error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/set_group_info', {
      'groupInfoForSet': {
        'groupID': groupID,
        if (groupName != null) 'groupName': groupName,
        if (faceURL != null) 'faceURL': faceURL,
        if (introduction != null) 'introduction': introduction,
        if (announcement != null) 'announcement': announcement,
      },
    });
  }

  /// 设置群成员上限 — 通过 im-server 的 set_group_info（群主权限）
  static Future<Map<String, dynamic>> setMaxMemberCount({
    required String groupID,
    required int maxMemberCount,
  }) async {
    if (useSDK) {
      try {
        // SDK setGroupInfo 无 maxMemberCount 字段，回退到 HTTP
        return await ImApi.post('/group/set_group_info', {
          'groupInfoForSet': {
            'groupID': groupID,
            'maxMemberCount': maxMemberCount,
          },
        });
      } catch (e) {
        debugPrint('[GroupApi] SDK setMaxMemberCount fallback error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/set_group_info', {
      'groupInfoForSet': {
        'groupID': groupID,
        'maxMemberCount': maxMemberCount,
      },
    });
  }

  /// 禁言群成员（seconds=0 解除禁言）
  static Future<Map<String, dynamic>> muteGroupMember({
    required String groupID,
    required String userID,
    required int seconds,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.changeGroupMemberMute(
          groupID: groupID,
          userID: userID,
          seconds: seconds,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK muteGroupMember error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/mute_group_member', {
      'groupID': groupID,
      'userID': userID,
      'mutedSeconds': seconds,
    });
  }

  /// 全员禁言 / 解除全员禁言
  static Future<Map<String, dynamic>> muteGroup({
    required String groupID,
    required bool muted,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.changeGroupMute(
          groupID: groupID,
          mute: muted,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK muteGroup error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    final endpoint = muted ? '/group/mute_group' : '/group/cancel_mute_group';
    return ImApi.post(endpoint, {'groupID': groupID});
  }

  /// 申请加入群（邀请链接流程；openIM joinSource=3 表示分享链接）
  static Future<Map<String, dynamic>> joinGroup({
    required String groupID,
    String inviterUserID = '',
    String reqMessage = '通过邀请链接加入',
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.groupManager.joinGroup(
          groupID: groupID,
          reason: reqMessage,
          joinSource: 3,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[GroupApi] SDK joinGroup error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/group/join_group', {
      'groupID': groupID,
      'reqMessage': reqMessage,
      'joinSource': 3,
      if (inviterUserID.isNotEmpty) 'inviterUserID': inviterUserID,
    });
  }

  /// 批量查询群的官方认证状态（调用 chat-api POST /group/official/status）
  /// 此端点始终走 HTTP（SDK 无对应方法）
  static Future<Map<String, dynamic>> getGroupOfficialStatus({
    required List<String> groupIDs,
  }) {
    return ChatApi.post('/group/official/status', {'groupIDs': groupIDs});
  }
}
