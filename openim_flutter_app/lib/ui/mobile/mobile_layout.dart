import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/controllers/conversation_controller.dart';
import '../../shared/theme/colors.dart';
import 'pages/mobile_home_page.dart';
import 'pages/mobile_conversations_page.dart';
import 'pages/mobile_contacts_page.dart';
import 'pages/mobile_profile_page.dart';
import 'pages/mobile_search_page.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 0;

  final _pages = const [
    MobileHomePage(),
    MobileConversationsPage(),
    MobileContactsPage(),
    MobileProfilePage(),
  ];

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MobileSearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversations = context.watch<ConversationController>().conversations;
    final totalUnread =
        conversations.fold<int>(0, (sum, c) => sum + c.unreadCount);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: _badgedIcon(Icons.chat_bubble_outline, totalUnread),
            activeIcon: _badgedIcon(Icons.chat_bubble, totalUnread),
            label: '消息',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.contacts_outlined),
            activeIcon: Icon(Icons.contacts),
            label: '通讯录',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton.small(
              backgroundColor: AppColors.primary,
              onPressed: _openSearch,
              child: const Icon(Icons.search, color: Colors.white),
            )
          : null,
    );
  }

  Widget _badgedIcon(IconData icon, int count) {
    if (count == 0) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              textScaler: const TextScaler.linear(1.0),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
