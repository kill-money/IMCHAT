import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/conversation_controller.dart';
import '../../core/controllers/chat_controller.dart';
import '../../core/controllers/status_controller.dart'; // 在线状态
import '../../core/api/api_client.dart';
import '../../shared/widgets/conversation_item.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/widgets/message_input.dart';
import 'pages/web_contacts_page.dart';
import 'pages/web_settings_page.dart';
import '../../shared/theme/colors.dart' show AppColors;

class WebLayout extends StatefulWidget {
  const WebLayout({super.key});

  @override
  State<WebLayout> createState() => _WebLayoutState();
}

class _WebLayoutState extends State<WebLayout> {
  int _tabIndex = 0; // 0=消息, 1=通讯录, 2=设置
  String? _selectedConversationID;

  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] WebLayout');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<ConversationController>().loadConversations();
      if (!mounted) return;
      context.read<ConversationController>().debugPrintState();
      _fetchStatuses();
    });
  }

  void _fetchStatuses() {
    final convCtrl = context.read<ConversationController>();
    final statusCtrl = context.read<StatusController>();
    final ids = convCtrl.conversations
        .where((c) => c.conversationType == 1 && c.userID.isNotEmpty)
        .map((c) => c.userID)
        .toList();
    statusCtrl.fetchStatuses(ids);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isNarrow = width < 768;

    return Scaffold(
      appBar: _buildTopNav(),
      body: _buildBody(isNarrow),
    );
  }

  PreferredSizeWidget _buildTopNav() {
    final auth = context.watch<AuthController>();
    return AppBar(
      title: const Text('乡村振兴3.0', style: TextStyle(fontSize: 18)),
      titleSpacing: 12,
      actions: [
        _tabButton('消息', Icons.chat, 0),
        _tabButton('通讯录', Icons.contacts, 1),
        _tabButton('设置', Icons.settings, 2),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              auth.currentUser?.nickname ?? '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout, size: 20),
          onPressed: () {
            auth.logout();
            Navigator.of(context).pushReplacementNamed('/login');
          },
          tooltip: '退出登录',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _tabButton(String label, IconData icon, int index) {
    final selected = _tabIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton.icon(
        onPressed: () => setState(() => _tabIndex = index),
        icon: Icon(icon,
            size: 18, color: selected ? Colors.white : Colors.white70),
        label: Text(label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? Colors.white : Colors.white70,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            )),
        style: TextButton.styleFrom(
          backgroundColor: selected ? Colors.white.withAlpha(30) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildBody(bool isNarrow) {
    switch (_tabIndex) {
      case 1:
        return const WebContactsPage();
      case 2:
        return const WebSettingsPage();
      default:
        return isNarrow ? _buildNarrowChat() : _buildWideChat();
    }
  }

  /// Narrow screen: show list or chat (single column)
  Widget _buildNarrowChat() {
    if (_selectedConversationID != null) {
      return _buildChatPanel(showBack: true);
    }
    return _buildConversationList();
  }

  /// Wide screen: side-by-side (dual column)
  Widget _buildWideChat() {
    return Row(
      children: [
        SizedBox(width: 320, child: _buildConversationList()),
        VerticalDivider(width: 1, color: AppColors.divider),
        Expanded(child: _buildChatPanel()),
      ],
    );
  }

  Widget _buildConversationList() {
    final controller = context.watch<ConversationController>();
    final statusCtrl = context.watch<StatusController>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索会话',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.pageBackground,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: controller.loading && controller.conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, index) {
                    final conv = controller.conversations[index];
                    return ConversationItem(
                      conversation: conv,
                      userStatus: conv.conversationType == 1
                          ? statusCtrl.getStatus(conv.userID)
                          : null,
                      selected: conv.conversationID == _selectedConversationID,
                      onTap: () {
                        setState(() {
                          _selectedConversationID = conv.conversationID;
                        });
                        final chat = context.read<ChatController>();
                        chat.setConversation(conv.conversationID);
                        chat.loadHistory(conversationID: conv.conversationID);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatPanel({bool showBack = false}) {
    if (_selectedConversationID == null) {
      return const Center(
        child: Text('选择一个会话开始聊天',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      );
    }

    final convCtrl = context.read<ConversationController>();
    final conv = convCtrl.getById(_selectedConversationID!);
    final chat = context.watch<ChatController>();
    final messages = chat.displayMessages;

    return Column(
      children: [
        // Header
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              if (showBack)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () =>
                      setState(() => _selectedConversationID = null),
                ),
              Text(
                conv?.showName ?? '',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: messages.isEmpty
              ? const Center(child: Text('暂无消息'))
              : ListView.builder(
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
            chat.sendTextMessage(
              recvID: conv?.userID ?? '',
              text: text,
            );
          },
        ),
      ],
    );
  }
}
