/// Chat & conversation API calls (im-server)
library;

import 'api_client.dart';

class ConversationApi {
  static Future<Map<String, dynamic>> getSortedConversationList({
    required int pageNumber,
    int showNumber = 20,
  }) {
    return ImApi.post('/conversation/get_sorted_conversation_list', {
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  static Future<Map<String, dynamic>> getConversation({
    required String conversationID,
  }) {
    return ImApi.post('/conversation/get_conversation', {
      'conversationID': conversationID,
    });
  }
}

class MsgApi {
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
      'senderPlatformID': 1,
      'sessionType': sessionType,
      'contentType': contentType,
      'content': content,
    });
  }

  static Future<Map<String, dynamic>> pullMsgBySeqs({
    required List<Map<String, dynamic>> seqRanges,
  }) {
    return ImApi.post('/msg/pull_msg_by_seqs', {
      'seqRanges': seqRanges,
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

  static Future<Map<String, dynamic>> updateUserInfo({
    required Map<String, dynamic> userInfo,
  }) {
    return ImApi.post('/user/update_user_info', {
      'userInfo': userInfo,
    });
  }

  /// 二开：查询指定用户最近登录 IP（需管理员或用户端管理员 token）
  static Future<Map<String, dynamic>> getUserIPInfo({
    required String userID,
  }) {
    return ChatApi.post('/user/ip_info', {'userID': userID});
  }
}

class FriendApi {
  static Future<Map<String, dynamic>> getFriendList({
    required int pageNumber,
    int showNumber = 100,
  }) {
    return ImApi.post('/friend/get_friend_list', {
      'pagination': {'pageNumber': pageNumber, 'showNumber': showNumber},
    });
  }

  static Future<Map<String, dynamic>> addFriend({
    required String toUserID,
    String reqMsg = '',
  }) {
    return ImApi.post('/friend/add_friend', {
      'toUserID': toUserID,
      'reqMsg': reqMsg,
    });
  }
}
