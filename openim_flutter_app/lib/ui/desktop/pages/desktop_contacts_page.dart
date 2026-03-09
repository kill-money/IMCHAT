import 'package:flutter/material.dart';
import '../../../core/api/chat_api.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Desktop contacts page — shown in the middle column when sidebar = contacts.
class DesktopContactsPage extends StatefulWidget {
  const DesktopContactsPage({super.key});

  @override
  State<DesktopContactsPage> createState() => _DesktopContactsPageState();
}

class _DesktopContactsPageState extends State<DesktopContactsPage> {
  List<Map<String, dynamic>> _friends = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _loading = true);
    try {
      final res = await FriendApi.getFriendList(pageNumber: 1, showNumber: 200);
      final list = res['data']?['friendsInfo'] as List? ?? [];
      setState(() {
        _friends = list.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint('加载好友列表失败: $e');
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          alignment: Alignment.centerLeft,
          child: const Text('通讯录',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索联系人',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
                  ? const Center(
                      child: Text('暂无联系人',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: _friends.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 0.5,
                        indent: 60,
                        color: Colors.grey[200],
                      ),
                      itemBuilder: (context, index) {
                        final f = _friends[index];
                        final info = f['friendUser'] as Map<String, dynamic>? ?? f;
                        return ListTile(
                          dense: true,
                          leading: UserAvatar(
                            faceURL: info['faceURL'] ?? '',
                            nickname: info['nickname'] ?? '',
                            size: 36,
                          ),
                          title: Text(
                            info['nickname'] ?? info['userID'] ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            'ID: ${info['userID'] ?? ''}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
