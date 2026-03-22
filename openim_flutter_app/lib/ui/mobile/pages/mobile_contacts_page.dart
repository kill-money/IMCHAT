import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/api/chat_api.dart';
import '../../../core/controllers/status_controller.dart';
import '../../../core/services/im_sdk_service.dart';
import '../../../shared/pages/user_detail_page.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/verified_badge.dart';
import '../../../shared/widgets/ui/app_header.dart';
import '../../../shared/widgets/ui/app_text.dart';
import 'add_friend_page.dart';
import 'group/create_group_page.dart';

class MobileContactsPage extends StatefulWidget {
  const MobileContactsPage({super.key});

  @override
  State<MobileContactsPage> createState() => _MobileContactsPageState();
}

class _MobileContactsPageState extends State<MobileContactsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _refreshTimer;
  StreamSubscription? _friendAppSub;
  StreamSubscription? _friendChangeSub;

  // 好友列表
  List<Map<String, dynamic>> _friends = [];
  bool _friendsLoading = false;

  // 收到的好友申请
  List<Map<String, dynamic>> _applications = [];
  bool _appsLoading = false;

  // 本地搜索过滤
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFriends();
    _loadApplications();
    // 每 30 秒自动刷新好友申请，实现准实时通知
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadApplications();
    });
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
    _refreshTimer?.cancel();
    _friendAppSub?.cancel();
    _friendChangeSub?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    setState(() => _friendsLoading = true);
    try {
      final res = await FriendApi.getFriendList(pageNumber: 1, showNumber: 200);
      final list = res['data']?['friendsInfo'] as List? ?? [];
      if (mounted) {
        setState(() => _friends = list.cast<Map<String, dynamic>>());
        // 批量拉取在线状态
        final ids = _friends
            .map((f) {
              final info = f['friendUser'] as Map<String, dynamic>? ?? f;
              return (info['userID'] ?? '').toString();
            })
            .where((id) => id.isNotEmpty)
            .toList();
        context.read<StatusController>().fetchStatuses(ids);
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('加载好友申请失败，下拉可重试')),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppHeader(
        title: '通讯录',
        showBack: false,
        right: PopupMenuButton<String>(
          icon: const Icon(Icons.add_circle_outline,
              color: Colors.white, size: 24),
          tooltip: '操作',
          onSelected: (value) {
            if (value == 'add_friend') {
              Navigator.of(context)
                  .push(
                MaterialPageRoute(builder: (_) => const AddFriendPage()),
              )
                  .then((_) {
                _loadFriends();
                _loadApplications();
              });
            } else if (value == 'create_group') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateGroupPage()),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'add_friend',
              child: Row(children: [
                Icon(Icons.person_add_outlined, size: 20),
                SizedBox(width: 10),
                Text('添加好友'),
              ]),
            ),
            PopupMenuItem(
              value: 'create_group',
              child: Row(children: [
                Icon(Icons.group_add_outlined, size: 20),
                SizedBox(width: 10),
                Text('创建群聊'),
              ]),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            color: AppColors.cardBackground,
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
                          child: Text(
                            '$_pendingCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      ),
    );
  }

  // ── 好友列表 Tab ────────────────────────────────────────────────────────────

  Widget _buildFriendList() {
    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索昵称或 ID',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        // 列表
        Expanded(
          child: _friendsLoading
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : RefreshIndicator(
                  onRefresh: _loadFriends,
                  child: _filtered.isEmpty
                      ? ListView(children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.people_outline,
                                    size: 56,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.22)),
                                const SizedBox(height: AppSpacing.md),
                                AppText(
                                  _searchQuery.isEmpty
                                      ? '暂无好友，点右上角添加'
                                      : '未找到相关好友',
                                  isSmall: true,
                                  style: const TextStyle(
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        ])
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const Divider(
                            height: 0.5,
                            indent: 72,
                            color: AppColors.divider,
                          ),
                          itemBuilder: (context, i) {
                            final f = _filtered[i];
                            final info =
                                f['friendUser'] as Map<String, dynamic>? ?? f;
                            final userID = info['userID']?.toString() ?? '';
                            final nickname =
                                info['nickname']?.toString() ?? userID;
                            final faceURL = info['faceURL']?.toString() ?? '';
                            final appRole = (info['appRole'] ?? 0) as int;
                            final isOfficial = (info['isOfficial'] ?? 0) as int;
                            final status = context
                                .watch<StatusController>()
                                .getStatus(userID);
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.xs,
                              ),
                              leading: UserAvatar(
                                faceURL: faceURL,
                                nickname: nickname,
                                size: 44,
                                isOnline: status?.isOnline ?? false,
                              ),
                              title: UserNameWithBadge(
                                nickname: nickname,
                                appRole: appRole,
                                isOfficial: isOfficial,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                              subtitle: status != null
                                  ? AppText(
                                      status.lastSeenText,
                                      isSmall: true,
                                      style: TextStyle(
                                        color: status.isOnline
                                            ? AppColors.success
                                            : AppColors.textSecondary,
                                      ),
                                    )
                                  : null,
                              trailing: const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => UserDetailPage(
                                    targetUserID: userID,
                                    nickname: nickname,
                                    faceURL: faceURL,
                                    appRole: appRole,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }

  // ── 新朋友 Tab ──────────────────────────────────────────────────────────────

  Widget _buildApplicationList() {
    return _appsLoading
        ? Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _loadApplications,
            child: _applications.isEmpty
                ? ListView(children: [
                    const SizedBox(height: 80),
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none,
                              size: 56,
                              color: AppColors.primary.withValues(alpha: 0.22)),
                          const SizedBox(height: AppSpacing.md),
                          AppText('暂无好友申请',
                              isSmall: true,
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  ])
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: _applications.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 0.5,
                      indent: 72,
                      color: AppColors.divider,
                    ),
                    itemBuilder: (context, i) {
                      final app = _applications[i];
                      final fromInfo =
                          app['fromUserInfo'] as Map<String, dynamic>? ?? {};
                      final fromID = fromInfo['userID']?.toString() ??
                          app['fromUserID']?.toString() ??
                          '';
                      final nickname =
                          fromInfo['nickname']?.toString() ?? fromID;
                      final faceURL = fromInfo['faceURL']?.toString() ?? '';
                      final reqMsg = app['reqMsg']?.toString() ?? '';
                      final handleResult = (app['handleResult'] ?? 0) as int;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        leading: UserAvatar(
                          faceURL: faceURL,
                          nickname: nickname,
                          size: 44,
                        ),
                        title: AppText(nickname),
                        subtitle: reqMsg.isNotEmpty
                            ? AppText(reqMsg,
                                isSmall: true,
                                style: const TextStyle(
                                    color: AppColors.textSecondary))
                            : null,
                        trailing: handleResult == 0
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _actionBtn('拒绝', false, fromID),
                                  const SizedBox(width: 8),
                                  _actionBtn('同意', true, fromID),
                                ],
                              )
                            : AppText(
                                handleResult == 1 ? '已同意' : '已拒绝',
                                isSmall: true,
                                style: TextStyle(
                                  color: handleResult == 1
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                ),
                              ),
                      );
                    },
                  ),
          );
  }

  Widget _actionBtn(String label, bool accept, String fromID) {
    return SizedBox(
      height: 30,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              accept ? AppColors.primary : AppColors.cardBackground,
          foregroundColor: accept ? Colors.white : AppColors.primary,
          side: accept ? null : const BorderSide(color: AppColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
