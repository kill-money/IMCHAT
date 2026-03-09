import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/chat_controller.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/widgets/chat_bubble.dart';
import '../../../shared/widgets/message_input.dart';

class MobileChatPage extends StatefulWidget {
  final String conversationID;
  final String title;
  final String recvID;

  const MobileChatPage({
    super.key,
    required this.conversationID,
    required this.title,
    this.recvID = '',
  });

  @override
  State<MobileChatPage> createState() => _MobileChatPageState();
}

class _MobileChatPageState extends State<MobileChatPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final chat = context.read<ChatController>();
    chat.setConversation(widget.conversationID);
    chat.loadHistory(conversationID: widget.conversationID);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final messages = chat.currentMessages;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: chat.loading && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('暂无消息'))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          return ChatBubble(
                            text: msg.textContent,
                            isMe: msg.sendID == ApiConfig.userID,
                            contentType: msg.contentType,
                          );
                        },
                      ),
          ),
          MessageInput(
            onSend: (text) {
              chat.sendTextMessage(recvID: widget.recvID, text: text);
              Future.delayed(
                  const Duration(milliseconds: 100), _scrollToBottom);
            },
          ),
        ],
      ),
    );
  }
}
