import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/api/chat_api.dart';
import '../../../core/services/im_sdk_service.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../../shared/pages/user_detail_page.dart';

/// Desktop contacts page — shown in the middle column when sidebar = contacts.
/// Includes friend list + friend request tabs + add friend dialog.
class DesktopContactsPage extends StatefulWidget {
  const DesktopContactsPage({super.key});

  @override
  State<DesktopContactsPage> createState() => _DesktopContactsPageState();
}

class _DesktopContactsPageState extends State<DesktopContactsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  StreamSubscription? _friendAppSub;
  StreamSubscription? _friendChangeSub;

  List<Map<String, dynamic>> _friends = [];
  bool _friendsLoading = false;

  List<Map<String, dynamic>> _applications = [];
  bool _appsLoading = false;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
    _loadApplications();
    // SDK 实时监听好友申请事件
    final sdkService = IMSDKService.instance;
    _friendAppSub = sdkService.onFriendApplicationChanged.listen((_) {
      if (mounted) _loadApplications();
    });
    _friendChangeSub = sdkService.onFriendChanged.listen((_) {
      if (mounted) _loadFriends();
    });
  }

  @override
  void dispose() {
    _friendAppSub?.cancel();
    _friendChangeSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _friendsLoading = true);
    try {
      final res = await FriendApi.getFriendList(pageNumber: 1, showNumber: 200);
      final list = res['data']?['friendsInfo'] as List? ?? [];
      if (mounted) setState(() => _friends = list.cast<Map<String, dynamic>>());
    } catch (e) {
      if (kDebugMode) debugPrint('加载好友列表失败: $e');
    }
    if (mounted) setState(() => _friendsLoading = false);
  }

  Future<void> _loadApplications() async {
    setState(() => _appsLoading = true);
    try {
      final res = await FriendApi.getRecvFriendApplicationList(pageNumber: 1);
      final list = res['data']?['friendRequests'] as List? ?? [];
      if (mounted) {
        setState(() => _applications = list.cast<Map<String, dynamic>>());
      }
    } catch (e) {
      if (kDebugMode) debugPrint('加载好友申请失败: $e');
    }
    if (mounted) setState(() => _appsLoading = false);
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _friends;
    final q = _searchQuery.toLowerCase();
    return _friends.where((f) {
      final info = f['friendUser'] as Map<String, dynamic>? ?? f;
      final name = (info['nickname'] ?? '').toString().toLowerCase();
      final id = (info['userID'] ?? '').toString().toLowerCase();
      return name.contains(q) || id.contains(q);
    }).toList();
  }

  int get _pendingCount =>
      _applications.where((a) => (a['handleResult'] ?? 0) == 0).length;

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddFriendDialog(onAdded: () {
        _loadFriends();
        _loadApplications();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add button
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              const Text('通讯录',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.person_add_outlined, size: 20),
                tooltip: '添加好友',
                onPressed: _showAddFriendDialog,
              ),
            ],
          ),
        ),
        // Tabs
        Container(
          color: AppColors.bgCard,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: [
              const Tab(text: '好友'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('新朋友'),
                    if (_pendingCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$_pendingCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        // Search bar (friends tab only)
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
              fillColor: AppColors.pageBackground,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFriendList(),
              _buildApplicationList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFriendList() {
    final list = _filtered;
    if (_friendsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (list.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? '暂无联系人' : '未找到相关好友',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) =>
          Divider(height: 0.5, indent: 60, color: AppColors.divider),
      itemBuilder: (context, index) {
        final f = list[index];
        final info = f['friendUser'] as Map<String, dynamic>? ?? f;
        final userID = info['userID']?.toString() ?? '';
        final nickname = info['nickname']?.toString() ?? userID;
        final faceURL = info['faceURL']?.toString() ?? '';
        final appRole = (info['appRole'] ?? 0) as int;
        final isOfficial = (info['isOfficial'] ?? 0) as int;
        return ListTile(
          dense: true,
          leading: UserAvatar(faceURL: faceURL, nickname: nickname, size: 36),
          title: UserNameWithBadge(
            nickname: nickname,
            appRole: appRole,
            isOfficial: isOfficial,
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text('ID: $userID',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_right,
              size: 16, color: AppColors.textSecondary),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => UserDetailPage(
              targetUserID: userID,
              nickname: nickname,
              faceURL: faceURL,
              appRole: appRole,
            ),
          )),
        );
      },
    );
  }

  Widget _buildApplicationList() {
    if (_appsLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_applications.isEmpty) {
      return const Center(
        child: Text('暂无好友申请', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      itemCount: _applications.length,
      separatorBuilder: (_, __) =>
          Divider(height: 0.5, indent: 60, color: AppColors.divider),
      itemBuilder: (context, i) {
        final app = _applications[i];
        final fromInfo = app['fromUserInfo'] as Map<String, dynamic>? ?? {};
        final fromID = fromInfo['userID']?.toString() ??
            app['fromUserID']?.toString() ??
            '';
        final nickname = fromInfo['nickname']?.toString() ?? fromID;
        final faceURL = fromInfo['faceURL']?.toString() ?? '';
        final reqMsg = app['reqMsg']?.toString() ?? '';
        final handleResult = (app['handleResult'] ?? 0) as int;

        return ListTile(
          dense: true,
          leading: UserAvatar(faceURL: faceURL, nickname: nickname, size: 36),
          title: Text(nickname, style: const TextStyle(fontSize: 13)),
          subtitle: reqMsg.isNotEmpty
              ? Text(reqMsg,
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary))
              : null,
          trailing: handleResult == 0
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  _actionBtn('拒绝', false, fromID),
                  const SizedBox(width: 6),
                  _actionBtn('同意', true, fromID),
                ])
              : Text(
                  handleResult == 1 ? '已同意' : '已拒绝',
                  style: TextStyle(
                    fontSize: 12,
                    color: handleResult == 1
                        ? AppColors.success
                        : AppColors.textSecondary,
                  ),
                ),
        );
      },
    );
  }

  Widget _actionBtn(String label, bool accept, String fromID) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accept ? AppColors.primary : AppColors.bgCard,
          foregroundColor: accept ? Colors.white : AppColors.primary,
          side: accept ? null : const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: Size.zero,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () => _handleApplication(fromID, accept),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Future<void> _handleApplication(String fromID, bool accept) async {
    try {
      await FriendApi.addFriendResponse(
        fromUserID: fromID,
        handleResult: accept ? 1 : -1,
      );
      await _loadApplications();
      if (accept) await _loadFriends();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('操作失败，请重试')),
        );
      }
    }
  }
}

// ── 添加好友对话框（Desktop 适配）────────────────────────────────────────────

class _AddFriendDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddFriendDialog({required this.onAdded});

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _idCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  Map<String, dynamic>? _foundUser;
  bool _searching = false;
  bool _sending = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _idCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final id = _idCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _searching = true;
      _foundUser = null;
      _error = null;
      _sent = false;
    });
    try {
      final res = await UserApi.getUsersInfo(userIDs: [id]);
      final list = res['data']?['usersInfo'] as List? ?? [];
      if (list.isNotEmpty) {
        setState(() => _foundUser = list.first as Map<String, dynamic>);
      } else {
        setState(() => _error = '未找到该用户');
      }
    } catch (_) {
      setState(() => _error = '查询失败，请检查网络');
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _addFriend() async {
    if (_foundUser == null) return;
    setState(() => _sending = true);
    try {
      await FriendApi.addFriend(
        toUserID: _foundUser!['userID']?.toString() ?? '',
        reqMsg: _msgCtrl.text.trim(),
      );
      setState(() => _sent = true);
      widget.onAdded();
    } catch (_) {
      setState(() => _error = '发送申请失败');
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    // 使用 Dialog + SizedBox 固定宽度，避免 AlertDialog 内部
    // Align→ConstrainedBox(minWidth:280) 在桌面端鼠标 hitTest 时
    // 出现 size:MISSING 的 Flutter 框架 bug
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 360,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('添加好友',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _idCtrl,
                    decoration: InputDecoration(
                      hintText: '输入对方用户 ID',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _searching ? null : _search,
                  child: _searching
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('查找'),
                ),
              ]),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 12)),
              ],
              if (_foundUser != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.pageBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    UserAvatar(
                      faceURL: _foundUser!['faceURL']?.toString() ?? '',
                      nickname: _foundUser!['nickname']?.toString() ?? '',
                      size: 36,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_foundUser!['nickname']?.toString() ?? '',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          Text('ID: ${_foundUser!['userID']}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: '申请留言（选填）',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _sent ? AppColors.success : AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: (_sending || _sent) ? null : _addFriend,
                  child: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_sent ? '申请已发送 ✓' : '发送好友申请'),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
