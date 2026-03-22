/// Chat & conversation API calls (im-server)
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart' as sdk;

import 'api_client.dart';
import '../services/device_info_service.dart';

class ConversationApi {
  static Future<Map<String, dynamic>> getSortedConversationList({
    required int pageNumber,
    int showNumber = 20,
  }) {
    return ImApi.post('/conversation/get_sorted_conversation_list', {
      'userID': ApiConfig.userID,
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  static Future<Map<String, dynamic>> getConversation({
    required String conversationID,
  }) {
    return ImApi.post('/conversation/get_conversation', {
      'ownerUserID': ApiConfig.userID,
      'conversationID': conversationID,
    });
  }
}

class MsgApi {
  /// 由 _HomeWrapper 设置
  static bool useSDK = false;

  static Future<Map<String, dynamic>> sendMsg({
    required String sendID,
    required String recvID,
    required int sessionType,
    required int contentType,
    required dynamic content,
  }) {
    return ImApi.post('/msg/send_msg', {
      'sendID': sendID,
      'recvID': recvID,
      'senderPlatformID': getCurrentPlatformId(),
      'sessionType': sessionType,
      'contentType': contentType,
      'content': content,
    });
  }

  static Future<Map<String, dynamic>> pullMsgBySeqs({
    required List<Map<String, dynamic>> seqRanges,
  }) {
    return ImApi.post('/msg/pull_msg_by_seq', {
      'userID': ApiConfig.userID,
      'seqRanges': seqRanges,
    });
  }

  /// 撤回消息（仅发送方，OpenIM 会广播撤回通知）
  static Future<Map<String, dynamic>> revokeMsg({
    required String conversationID,
    required int seq,
  }) {
    return ImApi.post('/msg/revoke_msg', {
      'userID': ApiConfig.userID,
      'conversationID': conversationID,
      'seq': seq,
    });
  }

  /// 删除消息（仅对自己，不影响对方）
  static Future<Map<String, dynamic>> deleteMsg({
    required String conversationID,
    required List<int> seqs,
  }) async {
    // SDK 模式下暂无按 seq 批量删除的等价方法，降级到 HTTP
    return ImApi.post('/msg/delete_msgs', {
      'userID': ApiConfig.userID,
      'conversationID': conversationID,
      'seqs': seqs,
    });
  }

  /// 清空指定会话的全部消息（仅自己）
  static Future<Map<String, dynamic>> clearConversationMsg({
    required List<String> conversationIDs,
  }) async {
    if (useSDK) {
      try {
        for (final cid in conversationIDs) {
          await sdk.OpenIM.iMManager.conversationManager
              .clearConversationAndDeleteAllMsg(conversationID: cid);
        }
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[MsgApi] SDK clearConversationMsg error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/msg/user_clear_all_msg', {
      'userID': ApiConfig.userID,
      'conversationIDs': conversationIDs,
    });
  }

  /// 查询一批会话的已读/最大 seq（用于轻量级轮询检测新消息）。
  /// [conversationIDs] 为空时后端返回当前用户所有会话的 seq。
  /// 响应 data.seqs: Map\<conversationID, {hasReadSeq, maxSeq, maxSeqTime}\>
  static Future<Map<String, dynamic>> getConversationsHasReadAndMaxSeq({
    List<String> conversationIDs = const [],
  }) {
    return ImApi.post('/msg/get_conversations_has_read_and_max_seq', {
      'userID': ApiConfig.userID,
      'conversationIDs': conversationIDs,
    });
  }

  /// 标记消息为已读（OpenIM v3.8 接口）
  static Future<Map<String, dynamic>> markMsgsAsRead({
    required String conversationID,
    required List<int> seqs,
  }) {
    return ImApi.post('/msg/mark_msgs_as_read', {
      'userID': ApiConfig.userID,
      'conversationID': conversationID,
      'seqs': seqs,
    });
  }
}

class UserApi {
  static Future<Map<String, dynamic>> getUsersInfo({
    required List<String> userIDs,
  }) {
    return ImApi.post('/user/get_users_info', {
      'userIDs': userIDs,
    });
  }

  /// 更新用户信息 — 调用 chat-api（10008）/user/update。
  /// Chat 服务器会同时更新自身数据库并同步到 IM 服务器。
  /// openimsdk/protocol 的自定义 wrapperspb 有 UnmarshalJSON，
  /// 将 JSON 裸值直接反序列化到 wrapper 内部字段，无需 {"value": v} 包装。
  static Future<Map<String, dynamic>> updateUserInfo({
    required String userID,
    String? nickname,
    String? faceURL,
    int? gender,
    int? birth,
  }) {
    final body = <String, dynamic>{'userID': userID};
    if (nickname != null) body['nickname'] = nickname;
    if (faceURL != null) body['faceURL'] = faceURL;
    if (gender != null) body['gender'] = gender;
    if (birth != null) body['birth'] = birth;
    return ChatApi.post('/user/update', body);
  }

  /// 通过用户 ID 或手机号搜索用户
  /// keyword 可以是 userID 或手机号（e164 格式）
  /// 调用 chat-api（port 10008）POST /user/search，返回含 appRole 的结果
  static Future<Map<String, dynamic>> searchUser({
    required String keyword,
  }) {
    return ChatApi.post('/user/search', {'keyword': keyword});
  }
}

class FriendApi {
  /// 由 _HomeWrapper 设置，控制是否通过 SDK 路由好友操作
  static bool useSDK = false;

  static Future<Map<String, dynamic>> getFriendList({
    required int pageNumber,
    int showNumber = 100,
  }) async {
    if (useSDK) {
      try {
        final list =
            await sdk.OpenIM.iMManager.friendshipManager.getFriendList();
        return {
          'errCode': 0,
          'data': {
            'friendsInfo': list
                .map((f) => {
                      'friendUser': {
                        'userID': f.userID ?? '',
                        'nickname': f.nickname ?? '',
                        'faceURL': f.faceURL ?? '',
                        'appRole': 0,
                        'isOfficial': 0,
                      },
                      'remark': f.remark ?? '',
                    })
                .toList(),
          },
        };
      } catch (e) {
        debugPrint('[FriendApi] SDK getFriendList error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/friend/get_friend_list', {
      'userID': ApiConfig.userID,
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  static Future<Map<String, dynamic>> addFriend({
    required String toUserID,
    String reqMsg = '',
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.friendshipManager.addFriend(
          userID: toUserID,
          reason: reqMsg,
        );
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[FriendApi] SDK addFriend error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/friend/add_friend', {
      'fromUserID': ApiConfig.userID,
      'toUserID': toUserID,
      'reqMsg': reqMsg,
    });
  }

  /// 获取收到的好友申请列表
  static Future<Map<String, dynamic>> getRecvFriendApplicationList({
    required int pageNumber,
    int showNumber = 50,
  }) async {
    if (useSDK) {
      try {
        final list = await sdk.OpenIM.iMManager.friendshipManager
            .getFriendApplicationListAsRecipient();
        return {
          'errCode': 0,
          'data': {
            'friendRequests': list
                .map((a) => {
                      'fromUserID': a.fromUserID ?? '',
                      'toUserID': a.toUserID ?? '',
                      'reqMsg': a.reqMsg ?? '',
                      'handleResult': a.handleResult ?? 0,
                      'fromUserInfo': {
                        'userID': a.fromUserID ?? '',
                        'nickname': a.fromNickname ?? '',
                        'faceURL': a.fromFaceURL ?? '',
                      },
                    })
                .toList(),
          },
        };
      } catch (e) {
        debugPrint('[FriendApi] SDK getRecvApplicationList error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/friend/get_recv_friend_application_list', {
      'userID': ApiConfig.userID,
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  /// 处理好友申请（同意/拒绝）
  /// [handleResult] 1=同意 -1=拒绝
  static Future<Map<String, dynamic>> addFriendResponse({
    required String fromUserID,
    required int handleResult,
    String handleMsg = '',
  }) async {
    if (useSDK) {
      try {
        if (handleResult == 1) {
          await sdk.OpenIM.iMManager.friendshipManager.acceptFriendApplication(
              userID: fromUserID, handleMsg: handleMsg);
        } else {
          await sdk.OpenIM.iMManager.friendshipManager.refuseFriendApplication(
              userID: fromUserID, handleMsg: handleMsg);
        }
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[FriendApi] SDK addFriendResponse error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/friend/add_friend_response', {
      'toUserID': ApiConfig.userID,
      'fromUserID': fromUserID,
      'handleResult': handleResult,
      'handleMsg': handleMsg,
    });
  }

  /// 检查是否为好友关系
  static Future<bool> isFriend({
    required String userID,
  }) async {
    if (useSDK) {
      try {
        final list = await sdk.OpenIM.iMManager.friendshipManager
            .checkFriend(userIDList: [userID]);
        return list.isNotEmpty && list[0].result == 1;
      } catch (e) {
        debugPrint('[FriendApi] SDK checkFriend error: $e');
        return false;
      }
    }
    try {
      final res = await ImApi.post('/friend/is_friend', {
        'userID1': ApiConfig.userID,
        'userID2': userID,
      });
      if ((res['errCode'] ?? 0) == 0) {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        return data['inUser1Friends'] == true || data['inUser2Friends'] == true;
      }
    } catch (e) {
      debugPrint('[FriendApi] isFriend error: $e');
    }
    return false;
  }

  /// 删除好友
  static Future<Map<String, dynamic>> deleteFriend({
    required String userID,
  }) async {
    if (useSDK) {
      try {
        await sdk.OpenIM.iMManager.friendshipManager
            .deleteFriend(userID: userID);
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[FriendApi] SDK deleteFriend error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/friend/delete_friend', {
      'ownerUserID': ApiConfig.userID,
      'friendUserID': userID,
    });
  }
}

class ConversationSettingApi {
  /// 由 _HomeWrapper 设置
  static bool useSDK = false;

  /// 批量设置会话属性（置顶 / 免打扰 / 归档）
  static Future<Map<String, dynamic>> setConversations({
    required List<Map<String, dynamic>> conversations,
  }) async {
    if (useSDK) {
      try {
        for (final conv in conversations) {
          final cid = conv['conversationID'] as String;
          final req = sdk.ConversationReq(
            isPinned: conv['isPinned'] as bool?,
            recvMsgOpt: conv['recvMsgOpt'] as int?,
          );
          await sdk.OpenIM.iMManager.conversationManager
              .setConversation(cid, req);
        }
        return {'errCode': 0};
      } catch (e) {
        debugPrint('[ConversationSettingApi] SDK setConversations error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/conversation/set_conversations', {
      'userID': ApiConfig.userID,
      'conversations': conversations,
    });
  }

  /// 删除会话（从列表中移除，不删消息记录）
  static Future<Map<String, dynamic>> deleteConversations({
    required List<String> conversationIDs,
  }) async {
    if (useSDK) {
      try {
        for (final cid in conversationIDs) {
          await sdk.OpenIM.iMManager.conversationManager
              .hideConversation(conversationID: cid);
        }
        return {'errCode': 0};
      } catch (e) {
        debugPrint(
            '[ConversationSettingApi] SDK deleteConversations error: $e');
        return {'errCode': -1, 'errMsg': e.toString()};
      }
    }
    return ImApi.post('/conversation/delete_conversations', {
      'ownerUserID': ApiConfig.userID,
      'conversationIDs': conversationIDs,
    });
  }
}

// ─── 消息扩展 API（chat-api port 10008） ─────────────────────────────

class ChatMsgApi {
  /// 编辑消息（仅发送方，2分钟内）
  static Future<Map<String, dynamic>> editMessage({
    required String conversationID,
    required String messageID,
    required String senderID,
    required String newContent,
    required int sendTime,
    String groupID = '',
  }) {
    return ChatApi.post('/chat_msg/edit', {
      'conversationID': conversationID,
      'messageID': messageID,
      'senderID': senderID,
      'groupID': groupID,
      'newContent': newContent,
      'sendTime': sendTime,
    });
  }

  /// 批量获取消息编辑记录
  static Future<Map<String, dynamic>> getMessageEdits({
    required List<String> messageIDs,
  }) {
    return ChatApi.post('/chat_msg/edits', {'messageIDs': messageIDs});
  }

  /// 撤回消息（仅发送方，2分钟内）
  static Future<Map<String, dynamic>> recallMessage({
    required String conversationID,
    required int seq,
    required String senderID,
    required int sendTime,
  }) {
    return ChatApi.post('/chat_msg/recall', {
      'conversationID': conversationID,
      'seq': seq,
      'senderID': senderID,
      'sendTime': sendTime,
    });
  }

  /// 群主/管理员删除群消息
  static Future<Map<String, dynamic>> deleteGroupMessage({
    required String conversationID,
    required String groupID,
    required List<int> seqs,
    required String operatorID,
  }) {
    return ChatApi.post('/chat_msg/delete_group', {
      'conversationID': conversationID,
      'groupID': groupID,
      'seqs': seqs,
      'operatorID': operatorID,
    });
  }

  /// 仅自己删除消息
  static Future<Map<String, dynamic>> deleteSelfMessage({
    required String conversationID,
    required List<int> seqs,
    required String userID,
  }) {
    return ChatApi.post('/chat_msg/delete_self', {
      'conversationID': conversationID,
      'seqs': seqs,
      'userID': userID,
    });
  }

  /// 合并转发
  static Future<Map<String, dynamic>> mergeForward({
    required String sendID,
    required int sessionType,
    required String title,
    required List<Map<String, dynamic>> multiMessage,
    String recvID = '',
    String groupID = '',
    String senderNickname = '',
    List<String> abstractList = const [],
  }) {
    return ChatApi.post('/chat_msg/merge_forward', {
      'sendID': sendID,
      'recvID': recvID,
      'groupID': groupID,
      'sessionType': sessionType,
      'senderNickname': senderNickname,
      'title': title,
      'abstractList': abstractList,
      'multiMessage': multiMessage,
    });
  }

  /// 内容过滤检查
  static Future<Map<String, dynamic>> checkContent({
    required String content,
  }) {
    return ChatApi.post('/chat_msg/check_content', {'content': content});
  }
}

class GroupMsgApi {
  /// 置顶消息
  static Future<Map<String, dynamic>> pinMessage({
    required String groupID,
    required String messageID,
    required String operatorID,
  }) {
    return ChatApi.post('/group_msg/pin', {
      'groupID': groupID,
      'messageID': messageID,
      'operatorID': operatorID,
    });
  }

  /// 取消置顶
  static Future<Map<String, dynamic>> unpinMessage({
    required String groupID,
    required String messageID,
    required String operatorID,
  }) {
    return ChatApi.post('/group_msg/unpin', {
      'groupID': groupID,
      'messageID': messageID,
      'operatorID': operatorID,
    });
  }

  /// 获取置顶消息列表
  static Future<Map<String, dynamic>> getPinnedMessages({
    required String groupID,
  }) {
    return ChatApi.post('/group_msg/pin/list', {'groupID': groupID});
  }
}

class GroupConfigApi {
  /// 查询群成员角色
  static Future<Map<String, dynamic>> getGroupMemberRole({
    required String groupID,
    required String userID,
  }) {
    return ChatApi.post('/group_config/member_role', {
      'groupID': groupID,
      'userID': userID,
    });
  }
}
