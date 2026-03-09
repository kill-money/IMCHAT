import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/chat_api.dart';
import '../models/message.dart';

class ChatController extends ChangeNotifier {
  final Map<String, List<Message>> _messageMap = {};
  String _currentConversationID = '';
  bool _loading = false;

  List<Message> get currentMessages =>
      _messageMap[_currentConversationID] ?? [];
  String get currentConversationID => _currentConversationID;
  bool get loading => _loading;

  void setConversation(String conversationID) {
    _currentConversationID = conversationID;
    notifyListeners();
  }

  Future<void> loadHistory({
    required String conversationID,
    int startSeq = 0,
    int endSeq = 0,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await MsgApi.pullMsgBySeqs(seqRanges: [
        {
          'conversationID': conversationID,
          'begin': startSeq,
          'end': endSeq,
          'num': 20,
        }
      ]);
      final msgs = res['data']?['msgs'] as List? ?? [];
      final list = msgs.map((e) => Message.fromJson(e as Map<String, dynamic>)).toList();
      _messageMap[conversationID] = list;
    } catch (e) {
      debugPrint('加载历史消息失败: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> sendTextMessage({
    required String recvID,
    required String text,
    int sessionType = 1,
  }) async {
    final tempMsg = Message(
      clientMsgID: DateTime.now().millisecondsSinceEpoch.toString(),
      sendID: ApiConfig.userID,
      recvID: recvID,
      contentType: 101,
      content: {'text': text},
      sendTime: DateTime.now().millisecondsSinceEpoch,
      status: 1,
    );

    _messageMap[_currentConversationID] ??= [];
    _messageMap[_currentConversationID]!.add(tempMsg);
    notifyListeners();

    try {
      await MsgApi.sendMsg(
        sendID: ApiConfig.userID,
        recvID: recvID,
        sessionType: sessionType,
        contentType: 101,
        content: {'text': text},
      );
      return true;
    } catch (e) {
      debugPrint('发送消息失败: $e');
      return false;
    }
  }

  void addIncomingMessage(String conversationID, Message msg) {
    _messageMap[conversationID] ??= [];
    _messageMap[conversationID]!.add(msg);
    notifyListeners();
  }
}
