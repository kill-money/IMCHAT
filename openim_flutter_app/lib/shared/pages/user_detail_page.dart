import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/chat_api.dart';
import '../../core/api/user_api.dart' as ip_api;
import '../../core/controllers/auth_controller.dart';
import '../../core/controllers/status_controller.dart';
import '../../core/models/user_info.dart';
import '../../core/models/user_status.dart';
import '../../ui/mobile/pages/mobile_chat_page.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/user_avatar.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_text.dart';

/// 用户详情页 — 从服务器拉取完整资料，显示签名/性别/年龄等
class UserDetailPage extends StatefulWidget {
  final String targetUserID;
  final String nickname;
  final String faceURL;
  final int appRole;

  const UserDetailPage({
    super.key,
    required this.targetUserID,
    this.nickname = '',
    this.faceURL = '',
    this.appRole = 0,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  String? _lastIP;
  DateTime? _lastIPTime;
  bool _ipLoading = false;
  String? _ipError;

  UserStatus? _userStatus;

  /// 从服务器拉取的完整用户资料
  UserInfo? _fullUser;

  /// 好友关系：null=未检查, true=已是好友, false=非好友
  bool? _isFriend;

  @override
  void initState() {
    super.initState();
    _loadFullUser();
    _checkFriendship();
    final me = context.read<AuthController>().currentUser;
    if (me != null && me.isAppAdmin) {
      _loadIP();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<StatusController>()
          .fetchStatus(widget.targetUserID)
          .then((s) {
        if (mounted && s != null) setState(() => _userStatus = s);
      });
    });
  }

  Future<void> _loadFullUser() async {
    if (widget.targetUserID.isEmpty) return;
    try {
      final res = await UserApi.getUsersInfo(userIDs: [widget.targetUserID]);
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode == 0) {
        // IM 服务器返回 {data: {usersInfo: [...]}} 格式
        final dataField = res['data'];
        final List users;
        if (dataField is List) {
          users = dataField;
        } else if (dataField is Map) {
          users = (dataField['usersInfo'] as List?) ??
              (dataField['users'] as List?) ??
              [];
        } else {
          users = [];
        }
        if (users.isNotEmpty) {
          final raw = users[0] as Map<String, dynamic>;
          if (mounted) setState(() => _fullUser = UserInfo.fromJson(raw));
        }
      } else {
        debugPrint('[UserDetail] getUsersInfo errCode=$errCode');
      }
    } catch (e) {
      debugPrint('[UserDetail] loadFullUser error: $e');
    }
  }

  Future<void> _checkFriendship() async {
    // 不检查自己
    if (widget.targetUserID == ApiConfig.userID) return;
    try {
      final result = await FriendApi.isFriend(userID: widget.targetUserID);
      if (mounted) {
        setState(() => _isFriend = result);
      }
    } catch (e) {
      debugPrint('[UserDetail] checkFriendship error: $e');
      // 检查失败默认显示添加好友按钮
      if (mounted) setState(() => _isFriend = false);
    }
  }

  Future<void> _loadIP() async {
    setState(() {
      _ipLoading = true;
      _ipError = null;
    });
    try {
      final res =
          await ip_api.UserApi.getUserIPInfo(targetUserID: widget.targetUserID);
      final errCode = (res['errCode'] ?? 0) as int;
      if (errCode != 0) {
        setState(() => _ipError = res['errMsg']?.toString() ?? '查询失败');
      } else {
        final data = res['data'] as Map<String, dynamic>? ?? {};
        final ip = data['lastIP']?.toString() ?? '';
        final ts = data['lastIPTime'];
        setState(() {
          _lastIP = ip.isEmpty ? '暂无记录' : ip;
          if (ts != null && ts != 0) {
            _lastIPTime = DateTime.fromMillisecondsSinceEpoch(
              (ts as int) > 1e12.toInt() ? ts : ts * 1000,
            );
          }
        });
      }
    } catch (e) {
      setState(() => _ipError = '网络错误');
    } finally {
      setState(() => _ipLoading = false);
    }
  }

  void _sendMessage() {
    // 构建单聊 conversationID（OpenIM 规则: si_smallerID_largerID）
    final ids = [ApiConfig.userID, widget.targetUserID]..sort();
    final conversationID = 'si_${ids[0]}_${ids[1]}';
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MobileChatPage(
        conversationID: conversationID,
        title: _displayName,
        recvID: widget.targetUserID,
        sessionType: 1,
      ),
    ));
  }

  Future<void> _addFriend() async {
    final res = await FriendApi.addFriend(
      toUserID: widget.targetUserID,
      reqMsg: '你好，请求添加好友',
    );
    if (!mounted) return;
    if ((res['errCode'] ?? 0) == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('好友申请已发送'), duration: Duration(seconds: 2)),
      );
    } else {
      debugPrint('[UserDetail] addFriend errMsg: ${res['errMsg']}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('发送失败，请稍后重试'), duration: Duration(seconds: 2)),
      );
    }
  }

  String get _displayName {
    if (_fullUser != null && _fullUser!.nickname.isNotEmpty) {
      return _fullUser!.nickname;
    }
    return widget.nickname.isNotEmpty ? widget.nickname : '未知用户';
  }

  String get _displayFaceURL => _fullUser?.faceURL ?? widget.faceURL;
  int get _displayAppRole => _fullUser?.appRole ?? widget.appRole;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    final isAdmin = me?.isAppAdmin ?? false;
    final isMe = widget.targetUserID == me?.userID;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('用户详情')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── 基本信息卡 ──
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                UserAvatar(
                  faceURL: _displayFaceURL,
                  nickname: _displayName,
                  size: 64,
                  showAdminBadge: _displayAppRole >= 1,
                  isOnline: _userStatus?.isOnline ?? false,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(_displayName, isTitle: true),
                      const SizedBox(height: AppSpacing.xs),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: widget.targetUserID));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('已复制用户 ID'),
                                duration: Duration(seconds: 1)),
                          );
                        },
                        child: AppText(
                          'ID: ${widget.targetUserID}',
                          isSmall: true,
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      if (_displayAppRole >= 1) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const AppText(
                            '管理员',
                            isSmall: true,
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                      if (_userStatus != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _userStatus!.isOnline
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            AppText(
                              _userStatus!.lastSeenText,
                              isSmall: true,
                              style: TextStyle(
                                color: _userStatus!.isOnline
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 个人资料卡 ──
          if (_fullUser != null || widget.nickname.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    '个人资料',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_fullUser != null) ...[
                    _infoRow('性别', _fullUser!.genderText),
                    if (_fullUser!.age != null)
                      _infoRow('年龄', '${_fullUser!.age} 岁'),
                    if (_fullUser!.signature.isNotEmpty)
                      _infoRow('签名', _fullUser!.signature),
                  ] else
                    const AppText(
                      '加载中…',
                      isSmall: true,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],

          // ── 操作按钮 ──
          if (!isMe) ...[
            const SizedBox(height: AppSpacing.xl),
            if (_isFriend == true)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('发消息'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              )
            else if (_isFriend == false)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addFriend,
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('添加好友'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
          ],

          // ── IP 信息卡（仅管理员可见）──
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      const AppText(
                        'IP 信息',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (_ipLoading)
                        const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      if (!_ipLoading && _lastIP != null)
                        GestureDetector(
                          onTap: _loadIP,
                          child: const Icon(Icons.refresh,
                              size: 16, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_ipError != null)
                    AppText(_ipError!,
                        isSmall: true,
                        style: const TextStyle(color: AppColors.danger))
                  else if (_ipLoading)
                    const AppText('查询中…',
                        isSmall: true,
                        style: TextStyle(color: AppColors.textSecondary))
                  else ...[
                    _ipRow('最后登录 IP', _lastIP ?? '-'),
                    if (_lastIPTime != null)
                      _ipRow('最后登录时间', _formatTime(_lastIPTime!)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: AppText(label,
                  isSmall: true,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(child: AppText(value, isSmall: true)),
          ],
        ),
      );

  Widget _ipRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: AppText(label,
                  isSmall: true,
                  style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('已复制'), duration: Duration(seconds: 1)),
                  );
                },
                child: AppText(value, isSmall: true),
              ),
            ),
          ],
        ),
      );

  String _formatTime(DateTime dt) {
    return '${dt.year}-${_p(dt.month)}-${_p(dt.day)} '
        '${_p(dt.hour)}:${_p(dt.minute)}';
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}

/// 便捷跳转方法
void pushUserDetail(BuildContext context, UserInfo user) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => UserDetailPage(
      targetUserID: user.userID,
      nickname: user.nickname,
      faceURL: user.faceURL,
      appRole: user.appRole,
    ),
  ));
}
