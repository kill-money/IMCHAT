import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/conversation_controller.dart';
import '../../core/controllers/chat_controller.dart';
import '../../core/api/api_client.dart';
import '../../shared/widgets/conversation_item.dart';
import '../../shared/widgets/chat_bubble.dart';
import '../../shared/widgets/message_input.dart';
import '../../shared/widgets/user_avatar.dart';
import 'pages/desktop_contacts_page.dart';
import 'pages/desktop_settings_page.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({super.key});

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends State<DesktopLayout> with WindowListener {
  int _sidebarIndex = 0; // 0=chat, 1=contacts, 2=settings
  String? _selectedConversationID;
  double _listWidth = 280;
  static const double _minListWidth = 200;
  static const double _maxListWidth = 400;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    final convCtrl = context.read<ConversationController>();
    Future.microtask(() {
      convCtrl.loadConversations();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    // Minimize to system tray instead of closing
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left sidebar (narrow icon strip, ~60px)
          _buildSidebar(),
          // Middle panel (conversation list or contacts)
          _buildMiddlePanel(),
          // Drag handle for resizing
          _buildDragHandle(),
          // Right panel (chat or settings)
          Expanded(child: _buildRightPanel()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final auth = context.watch<AuthController>();
    return Container(
      width: 60,
      color: const Color(0xFF2E2E2E),
      child: Column(
        children: [
          const SizedBox(height: 20),
          UserAvatar(
            faceURL: auth.currentUser?.faceURL ?? '',
            nickname: auth.currentUser?.nickname ?? '',
            size: 36,
          ),
          const SizedBox(height: 24),
          _sidebarIcon(Icons.chat, 0),
          _sidebarIcon(Icons.contacts, 1),
          const Spacer(),
          _sidebarIcon(Icons.settings, 2),
          const SizedBox(height: 16),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey, size: 20),
            onPressed: () {
              auth.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            tooltip: '退出登录',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, int index) {
    final selected = _sidebarIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: ['消息', '通讯录', '设置'][index],
        child: InkWell(
          onTap: () => setState(() => _sidebarIndex = index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? Colors.white.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                color: selected ? Colors.white : Colors.grey[500], size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildMiddlePanel() {
    return SizedBox(
      width: _listWidth,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          border: Border(right: BorderSide(color: Colors.grey[300]!, width: 0)),
        ),
        child: _sidebarIndex == 1
            ? const DesktopContactsPage()
            : _buildConversationList(),
      ),
    );
  }

  Widget _buildDragHandle() {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            _listWidth = (_listWidth + details.delta.dx)
                .clamp(_minListWidth, _maxListWidth);
          });
        },
        child: Container(
          width: 4,
          color: Colors.grey[300],
        ),
      ),
    );
  }

  Widget _buildRightPanel() {
    if (_sidebarIndex == 2) {
      return const DesktopSettingsPage();
    }
    return _buildChatPanel();
  }

  Widget _buildConversationList() {
    final controller = context.watch<ConversationController>();
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        // List
        Expanded(
          child: controller.loading && controller.conversations.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: controller.conversations.length,
                  itemBuilder: (context, index) {
                    final conv = controller.conversations[index];
                    return ConversationItem(
                      conversation: conv,
                      selected:
                          conv.conversationID == _selectedConversationID,
                      onTap: () {
                        setState(() {
                          _selectedConversationID = conv.conversationID;
                        });
                        final chat = context.read<ChatController>();
                        chat.setConversation(conv.conversationID);
                        chat.loadHistory(
                            conversationID: conv.conversationID);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatPanel() {
    if (_selectedConversationID == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('选择一个会话开始聊天',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final convCtrl = context.read<ConversationController>();
    final conv = convCtrl.getById(_selectedConversationID!);
    final chat = context.watch<ChatController>();
    final messages = chat.currentMessages;

    return Column(
      children: [
        // Chat header
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            conv?.showName ?? '',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
        // Messages
        Expanded(
          child: Container(
            color: const Color(0xFFF5F5F5),
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
        ),
        // Input
        MessageInput(
          compact: true,
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
