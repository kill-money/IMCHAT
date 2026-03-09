import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/conversation_controller.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/conversation_item.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_text.dart';
import 'mobile_chat_page.dart';

class MobileConversationsPage extends StatefulWidget {
  const MobileConversationsPage({super.key});

  @override
  State<MobileConversationsPage> createState() =>
      _MobileConversationsPageState();
}

class _MobileConversationsPageState extends State<MobileConversationsPage> {
  @override
  void initState() {
    super.initState();
    final convCtrl = context.read<ConversationController>();
    Future.microtask(() {
      convCtrl.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ConversationController>();

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(
        title: '消息',
        showBack: false,
      ),
      body: controller.loading && controller.conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => controller.loadConversations(),
              child: controller.conversations.isEmpty
                  ? const Center(
                      child: AppText(
                        '暂无会话',
                        isSmall: true,
                      ),
                    )
                  : ListView.separated(
                      itemCount: controller.conversations.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 0.5,
                        indent: 72,
                        color: AppColors.divider,
                      ),
                      itemBuilder: (context, index) {
                        final conv = controller.conversations[index];
                        return ConversationItem(
                          conversation: conv,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MobileChatPage(
                                  conversationID: conv.conversationID,
                                  title: conv.showName,
                                  recvID: conv.userID,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}
