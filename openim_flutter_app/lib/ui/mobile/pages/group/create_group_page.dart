import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/api/chat_api.dart';
import '../../../../core/controllers/auth_controller.dart';
import '../../../../core/controllers/group_controller.dart';
import '../../../../shared/theme/colors.dart';
import '../../../../shared/theme/spacing.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../mobile_chat_page.dart';

/// 创建群聊页面
/// 1. 从好友列表中勾选成员（此处使用 FriendApi 获取好友，P0 暂用占位数据）
/// 2. 输入群名称
/// 3. 点击「创建」调用 GroupController.createGroup()
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _manualIDController = TextEditingController();

  // Selected user IDs
  final Set<String> _selectedIDs = {};

  // Manually added users (by userID input)
  final List<_ContactItem> _manualContacts = [];

  // Available friends loaded from FriendApi
  final List<_ContactItem> _contacts = [];
  List<_ContactItem> _filtered = [];
  bool _loadingFriends = false;
  bool _addingManual = false;

  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final res = await FriendApi.getFriendList(pageNumber: 1, showNumber: 500);
      final list = res['data']?['friendsInfo'] as List? ?? [];
      final items = list
          .map((f) {
            final info = f['friendUser'] as Map<String, dynamic>? ??
                f as Map<String, dynamic>;
            return _ContactItem(
              userID: info['userID']?.toString() ?? '',
              nickname: info['nickname']?.toString() ?? '',
              faceURL: info['faceURL']?.toString() ?? '',
            );
          })
          .where((c) => c.userID.isNotEmpty)
          .toList();
      if (mounted) {
        setState(() {
          _contacts.clear();
          _contacts.addAll(items);
          _filtered = List.from(_contacts);
        });
      }
    } catch (e) {
      if (kDebugMode) debugPrint('加载好友列表失败: $e');
    }
    if (mounted) setState(() => _loadingFriends = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _manualIDController.dispose();
    super.dispose();
  }

  /// 手动通过 userID 搜索并添加成员
  Future<void> _addManualUser() async {
    final input = _manualIDController.text.trim();
    if (input.isEmpty) return;
    if (_selectedIDs.contains(input)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('该用户已添加')));
      return;
    }
    setState(() => _addingManual = true);
    try {
      final res = await UserApi.getUsersInfo(userIDs: [input]);
      final users = res['data']?['usersInfo'] as List? ?? [];
      if (users.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('未找到该用户')));
        }
      } else {
        final u = users.first as Map<String, dynamic>;
        final item = _ContactItem(
          userID: u['userID']?.toString() ?? input,
          nickname: u['nickname']?.toString() ?? input,
          faceURL: u['faceURL']?.toString() ?? '',
        );
        if (mounted) {
          setState(() {
            _manualContacts.add(item);
            _selectedIDs.add(item.userID);
            _manualIDController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('查询用户异常: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('查询失败，请稍后重试')));
      }
    }
    if (mounted) setState(() => _addingManual = false);
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _contacts
          : _contacts
              .where(
                  (c) => c.nickname.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请输入群名称')));
      return;
    }
    if (_selectedIDs.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请至少选择一位成员')));
      return;
    }

    setState(() => _creating = true);
    try {
      final group = await context.read<GroupController>().createGroup(
            groupName: name,
            memberUserIDs: _selectedIDs.toList(),
          );
      if (!mounted) return;
      setState(() => _creating = false);

      if (group != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('群聊「${group.groupName}」创建成功')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MobileChatPage(
              conversationID: 'sg_${group.groupID}',
              title: group.groupName,
              sessionType: 3,
              groupID: group.groupID,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('创建群聊失败，请稍后重试')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _creating = false);
        debugPrint('创建群聊异常: $e');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('创建群聊失败，请稍后重试')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthController>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('创建群聊'),
        actions: [
          if (_creating)
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.lg),
              child: Center(
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else
            TextButton(
              onPressed: _create,
              child: const Text('创建',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
        ],
      ),
      body: Column(
        children: [
          // 群名称输入
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: '群名称（必填）',
                prefixIcon: Icon(Icons.group_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 已选成员 chips
          if (_selectedIDs.isNotEmpty)
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (me != null)
                    _MemberChip(
                      faceURL: me.faceURL,
                      nickname: me.nickname,
                      canRemove: false,
                      onRemove: () {},
                    ),
                  ..._contacts
                      .where((c) => _selectedIDs.contains(c.userID))
                      .map((c) => _MemberChip(
                            faceURL: c.faceURL,
                            nickname: c.nickname,
                            canRemove: true,
                            onRemove: () =>
                                setState(() => _selectedIDs.remove(c.userID)),
                          )),
                  ..._manualContacts
                      .where((c) => _selectedIDs.contains(c.userID))
                      .map((c) => _MemberChip(
                            faceURL: c.faceURL,
                            nickname: c.nickname,
                            canRemove: true,
                            onRemove: () => setState(() {
                              _selectedIDs.remove(c.userID);
                              _manualContacts
                                  .removeWhere((m) => m.userID == c.userID);
                            }),
                          )),
                ],
              ),
            ),

          // 手动添加成员（通过 userID）
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualIDController,
                    decoration: const InputDecoration(
                      hintText: '输入用户ID添加成员',
                      prefixIcon: Icon(Icons.person_add_outlined),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addManualUser(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _addingManual
                    ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: _addManualUser,
                        icon: const Icon(Icons.add_circle,
                            color: AppColors.primary, size: 32),
                      ),
              ],
            ),
          ),

          // 好友搜索框（仅在有好友时显示）
          if (_contacts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: const InputDecoration(
                  hintText: '搜索联系人',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),

          if (_contacts.isNotEmpty) const Divider(height: 1),

          // 联系人列表
          Expanded(
            child: _loadingFriends
                ? const Center(child: CircularProgressIndicator())
                : _contacts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.people_outline,
                                size: 64, color: AppColors.textSecondary),
                            SizedBox(height: AppSpacing.md),
                            Text('暂无好友，请通过上方输入框添加成员',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final c = _filtered[i];
                          final isSelected = _selectedIDs.contains(c.userID);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => setState(() {
                              if (isSelected) {
                                _selectedIDs.remove(c.userID);
                              } else {
                                _selectedIDs.add(c.userID);
                              }
                            }),
                            secondary: UserAvatar(
                              faceURL: c.faceURL,
                              nickname: c.nickname,
                              size: 40,
                            ),
                            title: Text(c.nickname),
                            activeColor: AppColors.primary,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem {
  final String userID;
  final String nickname;
  final String faceURL;
  const _ContactItem(
      {required this.userID, required this.nickname, required this.faceURL});
}

class _MemberChip extends StatelessWidget {
  final String faceURL;
  final String nickname;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MemberChip({
    required this.faceURL,
    required this.nickname,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              UserAvatar(faceURL: faceURL, nickname: nickname, size: 40),
              if (canRemove)
                Positioned(
                  top: -4,
                  right: -4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 42,
            child: Text(
              nickname,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
