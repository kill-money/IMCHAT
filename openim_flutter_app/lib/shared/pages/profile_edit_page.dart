import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/api/api_client.dart';
import '../../core/api/chat_api.dart';
import '../../core/api/media_api.dart';
import '../../core/controllers/auth_controller.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/user_avatar.dart';
import '../widgets/ui/app_button.dart';
import '../widgets/ui/app_card.dart';
import '../widgets/ui/app_header.dart';
import '../widgets/ui/app_text.dart';

/// 个人资料编辑页 — 修改昵称、签名、性别、出生日期
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _nicknameCtrl;
  late final TextEditingController _signatureCtrl;
  int _gender = 0; // 0=unknown, 1=male, 2=female
  DateTime? _birthDate;
  bool _saving = false;
  bool _uploadingAvatar = false;
  String? _newFaceURL; // 上传后的新头像 URL
  String? _error;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nicknameCtrl = TextEditingController(text: user?.nickname ?? '');
    _signatureCtrl = TextEditingController(text: user?.signature ?? '');
    _gender = user?.gender ?? 0;
    if (user != null && user.birth != 0) {
      try {
        // birth 是秒级时间戳；防御性处理：若值过大则视为毫秒
        final birthSec =
            user.birth > 9999999999 ? user.birth ~/ 1000 : user.birth;
        _birthDate = DateTime.fromMillisecondsSinceEpoch(birthSec * 1000);
      } catch (_) {
        // 时间戳异常，忽略
      }
    }
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _signatureCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (file == null) return;
      setState(() => _uploadingAvatar = true);
      final bytes = await file.readAsBytes();
      final filename = file.name;
      final url = await MediaApi.uploadFile(bytes: bytes, filename: filename);
      if (url != null && url.isNotEmpty) {
        setState(() => _newFaceURL = url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('头像上传失败，请重试')),
          );
        }
      }
    } catch (e) {
      debugPrint('选择/上传头像失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('头像上传失败，请重试')),
        );
      }
    }
    if (mounted) setState(() => _uploadingAvatar = false);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.isEmpty) {
      setState(() => _error = '昵称不能为空');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthController>();
      final userID = auth.currentUser?.userID ?? '';
      final signature = _signatureCtrl.text.trim();
      // birth 字段统一用秒级时间戳
      final birthSec = _birthDate != null
          ? _birthDate!.millisecondsSinceEpoch ~/ 1000
          : null;

      // 1. 更新基本信息（昵称、头像、性别、出生日期）
      final res = await UserApi.updateUserInfo(
        userID: userID,
        nickname: nickname,
        faceURL: _newFaceURL,
        gender: _gender,
        birth: birthSec,
      );

      // 只检查 errCode，禁止向用户暴露后端原始错误信息
      if ((res['errCode'] ?? 0) != 0) {
        setState(() => _error = '保存失败，请稍后重试');
        return;
      }

      // 2. 签名独立更新（chat 服务器不支持 signature，存入 IM 服务器 ex 字段）
      {
        final exStr = jsonEncode({'signature': signature});
        try {
          final sigRes = await ImApi.post('/user/update_user_info_ex', {
            'userInfo': {
              'userID': userID,
              'ex': exStr,
            },
          });
          if ((sigRes['errCode'] ?? 0) != 0) {
            debugPrint('[ProfileEdit] 签名更新失败: ${sigRes['errCode']}');
          }
        } catch (e) {
          debugPrint('[ProfileEdit] 签名更新异常: $e');
        }
      }

      // 3. 更新本地缓存
      auth.updateLocalUser(
        nickname: nickname,
        faceURL: _newFaceURL,
        gender: _gender,
        signature: signature,
        birth: birthSec,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('资料已更新'),
            duration: Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      // 任何异常只显示友好提示，禁止暴露 JSON / 技术细节
      setState(() => _error = '网络错误，请稍后重试');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(title: '编辑资料'),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // 头像预览（点击更换）
          Center(
            child: GestureDetector(
              onTap: _uploadingAvatar ? null : _pickAvatar,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(
                    faceURL: _newFaceURL ?? user?.faceURL ?? '',
                    nickname: user?.nickname ?? '',
                    size: 80,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: _uploadingAvatar
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.camera_alt,
                              size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // 昵称输入
          _buildTextField('昵称', _nicknameCtrl, '请输入昵称', maxLength: 30),
          const SizedBox(height: AppSpacing.md),

          // 签名输入
          _buildTextField('个性签名', _signatureCtrl, '写点什么吧…', maxLength: 100),
          const SizedBox(height: AppSpacing.md),

          // 性别选择
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  '性别',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _genderChip('男', 1),
                    const SizedBox(width: AppSpacing.sm),
                    _genderChip('女', 2),
                    const SizedBox(width: AppSpacing.sm),
                    _genderChip('未设置', 0),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 出生日期选择
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: _pickBirthDate,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText('出生日期',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        _birthDate != null
                            ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
                            : '未设置',
                        style: TextStyle(
                          color: _birthDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 用户 ID（只读）
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            margin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText('用户 ID',
                    style: TextStyle(color: AppColors.textSecondary)),
                AppText(
                  user?.userID ?? '',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],

          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: '保存',
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLength = 30,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(label,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: ctrl,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, int value) {
    final selected = _gender == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _gender = value),
    );
  }
}
