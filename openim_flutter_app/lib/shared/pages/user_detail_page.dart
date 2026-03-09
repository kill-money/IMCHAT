import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/api/user_api.dart';
import '../../core/controllers/auth_controller.dart';
import '../../core/models/user_info.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/user_avatar.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_text.dart';

/// 用户详情页 — 普通用户看基本信息；用户端管理员额外看 IP 信息
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

  @override
  void initState() {
    super.initState();
    final me = context.read<AuthController>().currentUser;
    // 只有用户端管理员及以上才发 IP 查询请求
    if (me != null && me.isAppAdmin) {
      _loadIP();
    }
  }

  Future<void> _loadIP() async {
    setState(() {
      _ipLoading = true;
      _ipError = null;
    });
    try {
      final res = await UserApi.getUserIPInfo(targetUserID: widget.targetUserID);
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

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthController>().currentUser;
    final isAdmin = me?.isAppAdmin ?? false;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('用户详情')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ── 基本信息卡 ─────────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.zero,
            child: Row(
              children: [
                UserAvatar(
                  faceURL: widget.faceURL,
                  nickname: widget.nickname,
                  size: 64,
                  showAdminBadge: widget.appRole >= 1,
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        widget.nickname.isNotEmpty ? widget.nickname : '未知用户',
                        isTitle: true,
                      ),
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
                      if (widget.appRole >= 1) ...[
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
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── IP 信息卡（仅管理员可见，不渲染给普通用户）─────────────────
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
                        content: Text('已复制'),
                        duration: Duration(seconds: 1)),
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
