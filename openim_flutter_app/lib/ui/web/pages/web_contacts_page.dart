import 'package:flutter/material.dart';
import '../../../core/api/chat_api.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Web contacts page — displayed as the main content panel when Contacts tab is active.
class WebContactsPage extends StatefulWidget {
  const WebContactsPage({super.key});

  @override
  State<WebContactsPage> createState() => _WebContactsPageState();
}

class _WebContactsPageState extends State<WebContactsPage> {
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
      final res =
          await FriendApi.getFriendList(pageNumber: 1, showNumber: 200);
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
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索联系人',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _friends.isEmpty
                  ? const Center(
                      child: Text('暂无联系人',
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _friends.length,
                      itemBuilder: (context, index) {
                        final f = _friends[index];
                        final nickname =
                            f['nickname'] as String? ?? '未知';
                        final faceURL = f['faceURL'] as String? ?? '';
                        return ListTile(
                          leading: UserAvatar(
                            faceURL: faceURL,
                            nickname: nickname,
                            size: 38,
                          ),
                          title: Text(nickname,
                              style: const TextStyle(fontSize: 14)),
                          subtitle: Text(
                            f['userID'] as String? ?? '',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
