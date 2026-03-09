import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSend;
  final bool compact;

  const MessageInput({
    super.key,
    required this.onSend,
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
        horizontal: widget.compact ? AppSpacing.sm : AppSpacing.lg,
        vertical: widget.compact ? AppSpacing.xs : AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: const Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: '输入消息...',
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
          const SizedBox(width: AppSpacing.sm),
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
