import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/chat_api.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/ui/app_text.dart';

/// 独立的"添加好友"页面
/// 通过用户 ID 搜索对方，确认后发送好友申请。
class AddFriendPage extends StatefulWidget {
  const AddFriendPage({super.key});

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
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
    final keyword = _idCtrl.text.trim();
    if (keyword.isEmpty) return;
    // 防止添加自己
    if (keyword == ApiConfig.userID) {
      setState(() => _error = '不能添加自己为好友');
      return;
    }
    setState(() {
      _searching = true;
      _foundUser = null;
      _error = null;
      _sent = false;
    });
    try {
      // 优先调用支持手机号+userID的统一搜索接口
      // 若服务端未部署该接口则降级为 userID 精确查询
      Map<String, dynamic> res;
      List list = [];
      try {
        res = await UserApi.searchUser(keyword: keyword);
        final data = res['data'];
        if (data is Map) {
          list = (data['usersInfo'] ?? data['users'] ?? []) as List;
        } else if (data is List) {
          list = data;
        }
      } catch (_) {
        // 降级：按 userID 查询
        res = await UserApi.getUsersInfo(userIDs: [keyword]);
        list = res['data']?['usersInfo'] as List? ?? [];
      }
      if (list.isNotEmpty) {
        setState(() => _foundUser = list.first as Map<String, dynamic>);
      } else {
        setState(() => _error = '未找到该用户，请确认 ID 或手机号后重试');
      }
    } catch (_) {
      setState(() => _error = '查询失败，请检查网络后重试');
    }
    if (mounted) setState(() => _searching = false);
  }

  Future<void> _addFriend() async {
    if (_foundUser == null) return;
    setState(() => _sending = true);
    try {
      final toUID = _foundUser!['userID']?.toString() ?? '';
      debugPrint(
          '[AddFriend] calling addFriend toUserID=$toUID reqMsg=${_msgCtrl.text.trim()}');
      final res = await FriendApi.addFriend(
        toUserID: toUID,
        reqMsg: _msgCtrl.text.trim(),
      );
      debugPrint('[AddFriend] result: $res');
      if ((res['errCode'] ?? 0) != 0) {
        debugPrint(
            '[AddFriend] failed: errCode=${res['errCode']} errMsg=${res['errMsg']}');
        setState(() => _error = '发送申请失败，请重试');
      } else {
        setState(() => _sent = true);
      }
    } catch (_) {
      setState(() => _error = '发送申请失败，请重试');
    }
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('添加好友'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 搜索框
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(
                      hintText: '输入用户 ID 或手机号',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _searching ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _searching
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('搜索'),
                ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                  textAlign: TextAlign.center),
            ],

            // 搜索结果
            if (_foundUser != null) ...[
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    UserAvatar(
                      faceURL: _foundUser!['faceURL']?.toString() ?? '',
                      nickname: _foundUser!['nickname']?.toString() ?? '',
                      size: 64,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      _foundUser!['nickname']?.toString() ?? '',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    AppText(
                      'ID: ${_foundUser!['userID']}',
                      isSmall: true,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!_sent) ...[
                      TextField(
                        controller: _msgCtrl,
                        decoration: const InputDecoration(
                          hintText: '附言（可选）',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        maxLines: 2,
                        maxLength: 60,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _sending ? null : _addFriend,
                          icon: _sending
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.person_add_outlined),
                          label: const Text('发送好友申请'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ] else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle, color: AppColors.success),
                          SizedBox(width: 6),
                          Text('申请已发送，等待对方同意',
                              style: TextStyle(color: AppColors.success)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
