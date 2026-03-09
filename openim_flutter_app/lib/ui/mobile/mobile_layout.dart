import 'package:flutter/material.dart';
import 'pages/mobile_conversations_page.dart';
import 'pages/mobile_contacts_page.dart';
import 'pages/mobile_profile_page.dart';

class MobileLayout extends StatefulWidget {
  const MobileLayout({super.key});

  @override
  State<MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends State<MobileLayout> {
  int _currentIndex = 0;

  final _pages = const [
    MobileConversationsPage(),
    MobileContactsPage(),
    MobileProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '消息'),
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: '通讯录'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
