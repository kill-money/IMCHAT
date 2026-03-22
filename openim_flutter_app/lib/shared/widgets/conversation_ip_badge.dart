/// 推荐系统 — 对话头部 IP 显示徽章（仅对 canViewIP 用户可见）
library;

import 'package:flutter/material.dart';
import '../../core/api/user_api.dart';
import '../theme/colors.dart';

class ConversationIPBadge extends StatefulWidget {
  /// The user ID of the conversation partner (recvID).
  final String partnerUserID;

  const ConversationIPBadge({super.key, required this.partnerUserID});

  @override
  State<ConversationIPBadge> createState() => _ConversationIPBadgeState();
}

class _ConversationIPBadgeState extends State<ConversationIPBadge> {
  String? _ip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchIP();
  }

  @override
  void didUpdateWidget(ConversationIPBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.partnerUserID != widget.partnerUserID) {
      setState(() {
        _ip = null;
        _loading = true;
      });
      _fetchIP();
    }
  }

  Future<void> _fetchIP() async {
    if (widget.partnerUserID.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res =
          await UserApi.getUserIPInfo(targetUserID: widget.partnerUserID);
      if (res['errCode'] == 0) {
        final data = res['data'] ?? {};
        final ip = data['lastIP']?.toString() ?? '';
        if (mounted) {
          setState(() {
            _ip = ip.isEmpty ? null : ip;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_ip == null || _ip!.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _ip!,
        style: TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
