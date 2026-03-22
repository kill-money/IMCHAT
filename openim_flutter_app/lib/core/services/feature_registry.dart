/// 功能 → API 映射注册表
///
/// 将后端 API 能力与 UI 功能入口关联起来，
/// 配合 [ConfigController] 的 feature-flag 实现动态功能可见性。
library;

/// 单个功能入口的描述
class FeatureEntry {
  final String id;
  final String label;
  final String icon; // Material icon name（仅文档用途）
  final List<String> apiEndpoints; // 后端 API 路径前缀
  final String? configKey; // 对应 ConfigController.getBool 的 key（null = 始终可见）
  final bool adminOnly; // true = 仅管理员可见

  const FeatureEntry({
    required this.id,
    required this.label,
    this.icon = '',
    required this.apiEndpoints,
    this.configKey,
    this.adminOnly = false,
  });
}

/// 全局功能注册表 — 将后端 145 个 API 分组为用户可见的功能模块
class FeatureRegistry {
  FeatureRegistry._();

  // ─── 核心通讯 ──────────────────────────────────────────────
  static const chat = FeatureEntry(
    id: 'chat',
    label: '消息',
    icon: 'chat',
    apiEndpoints: [
      '/msg/send_msg',
      '/msg/pull_msg_by_seq',
      '/msg/revoke_msg',
      '/msg/delete_msg',
      '/msg/mark_msgs_as_read',
      '/msg/search_msg',
      '/msg/get_server_time',
    ],
  );

  static const conversation = FeatureEntry(
    id: 'conversation',
    label: '会话',
    icon: 'forum',
    apiEndpoints: [
      '/conversation/get_sorted_conversation_list',
      '/conversation/get_conversation',
      '/conversation/set_conversation',
      '/conversation/get_all_conversations',
    ],
  );

  // ─── 通讯录 / 好友 ────────────────────────────────────────
  static const contacts = FeatureEntry(
    id: 'contacts',
    label: '通讯录',
    icon: 'contacts',
    apiEndpoints: [
      '/friend/get_friend_list',
      '/friend/add_friend',
      '/friend/delete_friend',
      '/friend/get_friend_application_list',
      '/friend/add_friend_response',
      '/friend/set_friend_remark',
      '/friend/get_specified_friends_info',
      '/friend/import_friend',
      '/friend/is_friend',
    ],
  );

  // ─── 群组管理 ──────────────────────────────────────────────
  static const group = FeatureEntry(
    id: 'group',
    label: '群管理',
    icon: 'groups',
    apiEndpoints: [
      '/group/create_group',
      '/group/get_groups_info',
      '/group/get_joined_group_list',
      '/group/get_group_member_list',
      '/group/invite_user_to_group',
      '/group/kick_group_member',
      '/group/set_group_info',
      '/group/set_group_member_info',
      '/group/transfer_group',
      '/group/dismiss_group',
      '/group/quit_group',
      '/group/mute_group',
      '/group/cancel_mute_group',
      '/group/mute_group_member',
      '/group/cancel_mute_group_member',
      '/group/join_group',
      '/group/get_group_application_list',
      '/group/group_application_response',
    ],
  );

  // ─── 钱包 ─────────────────────────────────────────────────
  static const wallet = FeatureEntry(
    id: 'wallet',
    label: '钱包',
    icon: 'account_balance_wallet',
    configKey: 'wallet_enabled',
    apiEndpoints: [
      '/wallet/get_info',
      '/wallet/list_cards',
      '/wallet/add_card',
      '/wallet/remove_card',
      '/wallet/withdraw',
    ],
  );

  // ─── 用户资料 ──────────────────────────────────────────────
  static const userProfile = FeatureEntry(
    id: 'user_profile',
    label: '个人资料',
    icon: 'person',
    apiEndpoints: [
      '/user/get_users_info',
      '/user/update_user_info',
      '/user/get_users_online_status',
      '/user/search_users',
    ],
  );

  // ─── 消息编辑 ──────────────────────────────────────────────
  static const messageEdit = FeatureEntry(
    id: 'message_edit',
    label: '消息编辑',
    icon: 'edit',
    configKey: 'edit_message_enabled',
    apiEndpoints: ['/msg/revoke_msg', '/msg/delete_msg'],
  );

  // ─── 客户端配置 ────────────────────────────────────────────
  static const clientConfig = FeatureEntry(
    id: 'client_config',
    label: '客户端配置',
    icon: 'settings_applications',
    apiEndpoints: [
      '/client_config/get',
      '/client_config/set',
      '/client_config/del',
    ],
    adminOnly: true,
  );

  // ─── 在线状态 ──────────────────────────────────────────────
  static const onlineStatus = FeatureEntry(
    id: 'online_status',
    label: '在线状态',
    icon: 'circle',
    apiEndpoints: [
      '/user/get_users_online_status',
      '/user/subscribe_users_status',
    ],
  );

  // ─── 收藏消息 ──────────────────────────────────────────────
  static const starredMessages = FeatureEntry(
    id: 'starred_messages',
    label: '收藏',
    icon: 'star',
    apiEndpoints: ['/msg/search_msg'],
  );

  // ─── 设备管理 ──────────────────────────────────────────────
  static const deviceManage = FeatureEntry(
    id: 'device_manage',
    label: '设备管理',
    icon: 'devices',
    apiEndpoints: ['/auth/force_logout'],
  );

  // ─── 隐私设置 ──────────────────────────────────────────────
  static const privacySettings = FeatureEntry(
    id: 'privacy_settings',
    label: '隐私设置',
    icon: 'shield',
    apiEndpoints: ['/user/get_users_online_status'],
  );

  // ─── 白名单 ────────────────────────────────────────────────
  static const whitelist = FeatureEntry(
    id: 'whitelist',
    label: '白名单登录',
    icon: 'verified_user',
    configKey: 'whitelistLoginEnabled',
    apiEndpoints: ['/whitelist/check'],
  );

  // ─── Admin 专属：用户管理 ──────────────────────────────────
  static const adminUserManage = FeatureEntry(
    id: 'admin_user_manage',
    label: '用户管理',
    icon: 'manage_accounts',
    adminOnly: true,
    apiEndpoints: [
      '/user/search',
      '/user/block',
      '/user/unblock',
      '/user/block_list',
      '/user/reset_password',
    ],
  );

  // ─── Admin 专属：群组管理 ──────────────────────────────────
  static const adminGroupManage = FeatureEntry(
    id: 'admin_group_manage',
    label: '群组管理(Admin)',
    icon: 'admin_panel_settings',
    adminOnly: true,
    apiEndpoints: ['/group/search', '/group/create', '/group/dismiss'],
  );

  // ─── Admin 专属：统计 ──────────────────────────────────────
  static const adminStatistics = FeatureEntry(
    id: 'admin_statistics',
    label: '数据统计',
    icon: 'bar_chart',
    adminOnly: true,
    apiEndpoints: [
      '/statistic/new_user_count',
      '/statistic/login_user_count',
    ],
  );

  // ─── Admin 专属：版本管理 ──────────────────────────────────
  static const adminVersionManage = FeatureEntry(
    id: 'admin_version_manage',
    label: '版本管理',
    icon: 'system_update',
    adminOnly: true,
    apiEndpoints: [
      '/application_version/page',
      '/application_version/add',
      '/application_version/update',
      '/application_version/delete',
    ],
  );

  /// 所有功能条目（供遍历 / 搜索用）
  static const List<FeatureEntry> all = [
    chat,
    conversation,
    contacts,
    group,
    wallet,
    userProfile,
    messageEdit,
    clientConfig,
    onlineStatus,
    starredMessages,
    deviceManage,
    privacySettings,
    whitelist,
    adminUserManage,
    adminGroupManage,
    adminStatistics,
    adminVersionManage,
  ];

  /// 按 id 查找
  static FeatureEntry? byId(String id) {
    for (final e in all) {
      if (e.id == id) return e;
    }
    return null;
  }
}
