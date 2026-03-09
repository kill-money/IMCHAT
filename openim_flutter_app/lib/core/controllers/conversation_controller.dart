import 'package:flutter/foundation.dart';
import '../api/chat_api.dart';
import '../models/conversation.dart';

class ConversationController extends ChangeNotifier {
  List<Conversation> _conversations = [];
  bool _loading = false;

  List<Conversation> get conversations => _conversations;
  bool get loading => _loading;

  Future<void> loadConversations({int page = 1}) async {
    _loading = true;
    notifyListeners();

    try {
      final res = await ConversationApi.getSortedConversationList(
        pageNumber: page,
      );
      final list = res['data']?['conversationElems'] as List? ?? [];
      if (page == 1) {
        _conversations = list
            .map((e) =>
                Conversation.fromJson(e['conversation'] as Map<String, dynamic>))
            .toList();
      } else {
        _conversations.addAll(list
            .map((e) =>
                Conversation.fromJson(e['conversation'] as Map<String, dynamic>))
            .toList());
      }
    } catch (e) {
      debugPrint('加载会话列表失败: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Conversation? getById(String id) {
    try {
      return _conversations.firstWhere((c) => c.conversationID == id);
    } catch (_) {
      return null;
    }
  }
}
