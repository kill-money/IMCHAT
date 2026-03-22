import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

enum AttachmentType { gallery, camera, file, voice, location, sticker }

class MessageInput extends StatefulWidget {
  final Function(String text) onSend;

  /// 用户选择附件类型时触发（由父页面处理文件选取与上传）
  final Function(AttachmentType type)? onAttach;

  final bool compact;

  const MessageInput({
    super.key,
    required this.onSend,
    this.onAttach,
    this.compact = false,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AttachmentSheet(
        onSelect: (type) {
          Navigator.of(context).pop();
          widget.onAttach?.call(type);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compact ? AppSpacing.sm : AppSpacing.md,
        vertical: widget.compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // 附件按钮
          if (widget.onAttach != null)
            IconButton(
              onPressed: _showAttachmentSheet,
              icon: const Icon(Icons.add_circle_outline,
                  color: AppColors.primary),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              tooltip: '附件',
            ),
          const SizedBox(width: AppSpacing.xs),
          // 输入框
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '输入消息…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                isDense: true,
              ),
              maxLines: widget.compact ? 1 : 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          // 发送按钮
          IconButton(
            onPressed: _send,
            icon: const Icon(Icons.send, color: AppColors.primary),
            tooltip: '发送',
          ),
        ],
      ),
    );
  }
}

// ─── Attachment sheet ────────────────────────────────────────────────────────

class _AttachmentSheet extends StatelessWidget {
  final ValueChanged<AttachmentType> onSelect;

  const _AttachmentSheet({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
            children: [
              _AttachItem(
                icon: Icons.photo_library_outlined,
                label: '图库',
                color: AppColors.indigo,
                onTap: () => onSelect(AttachmentType.gallery),
              ),
              _AttachItem(
                icon: Icons.camera_alt_outlined,
                label: '相机',
                color: AppColors.teal,
                onTap: () => onSelect(AttachmentType.camera),
              ),
              _AttachItem(
                icon: Icons.insert_drive_file_outlined,
                label: '文件',
                color: AppColors.activity,
                onTap: () => onSelect(AttachmentType.file),
              ),
              _AttachItem(
                icon: Icons.mic_outlined,
                label: '语音',
                color: AppColors.primary,
                onTap: () => onSelect(AttachmentType.voice),
              ),
              _AttachItem(
                icon: Icons.location_on_outlined,
                label: '位置',
                color: AppColors.harvest,
                onTap: () => onSelect(AttachmentType.location),
              ),
              _AttachItem(
                icon: Icons.emoji_emotions_outlined,
                label: '表情包',
                color: AppColors.accent,
                onTap: () => onSelect(AttachmentType.sticker),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
