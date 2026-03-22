# 项目进度报告 — IMCHAT 全栈即时通讯系统

> 生成时间：2025-06-13（最后更新：2026-03-21）  
> 项目由 AI 辅助全程编写，此报告为系统性梳理。

---

## 目录

1. [项目概览](#1-项目概览)
2. [已完成功能模块清单](#2-已完成功能模块清单)
   - [2.1 Flutter 客户端 (107 文件)](#21-flutter-客户端)
   - [2.2 Go 后端 openim-chat (256 文件)](#22-go-后端-openim-chat)
   - [2.3 Admin Web 管理后台 (129 文件)](#23-admin-web-管理后台)
3. [TODO/FIXME/占位实现](#3-todofixme占位实现)
4. [代码质量问题](#4-代码质量问题)
5. [优先级排序的下一步工作](#5-优先级排序的下一步工作)

---

## 1. 项目概览

| 子项目 | 技术栈 | 源文件数 | 说明 |
|--------|--------|----------|------|
| **openim_flutter_app** | Flutter 3.x / Dart | 107 | iOS/Android/Web/Windows 四端客户端 |
| **openim-chat** | Go 1.21 / Gin / MongoDB | 256 | 业务后端 (chat-api:10008 + admin-api:10009) |
| **openim-admin-web** | React / UMI 4 / Ant Design Pro / TS | 129 | 管理后台 (dev:8001) |
| **open-im-server-main** | Go / Kafka / etcd | — | IM 核心服务 (ws:10001, api:10002)，使用**预构建镜像** |
| **openim-docker** | Docker Compose | — | 7 容器编排 (mongo/redis/kafka/etcd/minio/server/chat) |

### 关键架构决策

| 决策 | 说明 |
|------|------|
| **无 OpenIM SDK** | Flutter 客户端不集成 openim_sdk，全部通过 HTTP REST + 10 秒轮询实现消息收发 |
| **三端适配** | 同一 codebase 通过 `mobile_layout` / `desktop_layout` / `web_layout` 分平台路由 |
| **Docker 容器化** | openim-chat 使用本地构建镜像 `openim-chat-local:latest`，Go 代码变更后需重新构建 |
| **密码安全** | 管理端 MD5→bcrypt 渐进迁移；敏感操作 HMAC-SHA256 挑战-响应；TOTP AES-256-GCM 加密存储 |

---

## 2. 已完成功能模块清单

> 标注说明：  
> - 🔵 **OpenIM 原生** = 使用 open-im-server 原生接口  
> - 🟠 **二开/自研** = 在 openim-chat 上自行扩展的功能  
> - 🟢 **前端独立** = 纯前端实现，不依赖特殊后端

---

### 2.1 Flutter 客户端

#### 2.1.1 页面模块

| 平台 | 页面 | 文件路径 | 分类 | 状态 |
|------|------|----------|------|------|
| **Mobile** | 首页（轮播+宫格+资讯） | `ui/mobile/pages/mobile_home_page.dart` | 🟢前端 | ✅ |
| **Mobile** | 会话列表 | `ui/mobile/pages/mobile_conversations_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 聊天页（10+ 消息类型） | `ui/mobile/pages/mobile_chat_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 通讯录（好友/申请） | `ui/mobile/pages/mobile_contacts_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 个人资料（IP信息展示） | `ui/mobile/pages/mobile_profile_page.dart` | 🟠二开 | ✅ |
| **Mobile** | 搜索 | `ui/mobile/pages/mobile_search_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 设置 | `ui/mobile/pages/mobile_settings_page.dart` | 🟢前端 | ✅ |
| **Mobile** | 钱包 | `ui/mobile/pages/wallet_page.dart` | 🟠二开 | ✅ |
| **Mobile** | 关于 | `ui/mobile/pages/mobile_about_page.dart` | 🟢前端 | ✅ |
| **Mobile** | 群组创建 | `ui/mobile/pages/group/create_group_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 群组详情 | `ui/mobile/pages/group/group_detail_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 群成员列表 | `ui/mobile/pages/group/group_member_list_page.dart` | 🔵原生 | ✅ |
| **Mobile** | 添加好友 | `ui/mobile/pages/add_friend_page.dart` | 🔵原生 | ✅ |
| **Desktop** | 三栏布局（侧栏+会话+聊天） | `ui/desktop/desktop_layout.dart` | 🟢前端 | ✅ |
| **Desktop** | 通讯录 | `ui/desktop/pages/desktop_contacts_page.dart` | 🔵原生 | ✅ |
| **Desktop** | 设置 | `ui/desktop/pages/desktop_settings_page.dart` | 🟢前端 | ✅ |
| **Web** | 响应式布局 | `ui/web/web_layout.dart` | 🟢前端 | ✅ |
| **Web** | 通讯录 | `ui/web/pages/web_contacts_page.dart` | 🔵原生 | ✅ |
| **共享** | 闪屏 | `shared/pages/splash_page.dart` | 🟢前端 | ✅ |
| **共享** | 登录 | `shared/pages/login_page.dart` | 🔵原生 | ✅ |
| **共享** | 注册 | `shared/pages/register_page.dart` | 🔵原生 | ✅ |
| **共享** | 忘记密码 | `shared/pages/forgot_password_page.dart` | 🔵原生 | ✅ |
| **共享** | 资料编辑 | `shared/pages/profile_edit_page.dart` | 🔵原生 | ✅ |
| **共享** | 用户详情 | `shared/pages/user_detail_page.dart` | 🔵原生 | ✅ |
| **共享** | 设备管理 | `shared/pages/device_manage_page.dart` | 🟠二开 | ✅ |
| **共享** | 隐私设置 | `shared/pages/privacy_settings_page.dart` | 🟢前端 | ✅ |
| **共享** | 收藏消息 | `shared/pages/starred_messages_page.dart` | 🟠二开 | ✅ |
| **共享** | 图片查看器 | `shared/pages/image_viewer_page.dart` | 🟢前端 | ✅ |
| **共享** | 法律条款 | `shared/pages/legal_content_page.dart` | 🟢前端 | ✅ |

#### 2.1.2 状态管理 (Controller)

| Controller | 分类 | 关键能力 | dispose 实现 |
|------------|------|---------|-------------|
| `AuthController` | 🔵原生 | 登录/注册/Token 管理/自动登录/角色判断 | ✅ 已修复 (2026-03-21) |
| `ConversationController` | 🔵原生 | 会话列表轮询/未读计数/名称+头像缓存 | ✅ 已修复 (2026-03-21) |
| `ChatController` | 🔵原生 | 消息收发/重试队列/多媒体消息/状态管理 | ✅ 已修复 (2026-03-21, +_disposed 标志) |
| `GroupController` | 🔵原生 | 群列表/创建/加入/退出/成员管理/权限 | ✅ 已修复 (2026-03-21) |
| `StatusController` | 🟠二开 | 用户在线状态轮询/批量查询 | ✅ 已实现 |
| `WalletController` | 🟠二开 | 余额查询/交易记录/银行卡管理 | ✅ 已修复 (2026-03-21) |
| `ConfigController` | 🟠二开 | 功能开关/动态配置 | ✅ 已修复 (2026-03-21) |

#### 2.1.3 API 层 (8 个文件)

| 文件 | 分类 | 关键方法 |
|------|------|---------|
| `api_client.dart` | 基础设施 | ApiConfig (编译时 IP)、共享 HTTP Client |
| `auth_api.dart` | 🔵原生 | login / register / getUserToken / getAdminToken |
| `chat_api.dart` → `MsgApi` | 🔵原生 | sendMsg / pullMsgBySeqs / markMsgsAsRead / revokeMsg |
| `chat_api.dart` → `FriendApi` | 🔵原生 | getFriendList / addFriend / respondFriendApplication |
| `chat_api.dart` → `UserApi` | 🔵原生 | getUsersInfo / updateSelfInfo / getSortedConversationList |
| `group_api.dart` | 🔵原生 | 17 个方法 — createGroup / joinGroup / getGroupMembers / ... |
| `wallet_api.dart` | 🟠二开 | getWallet / getTransactions / withdraw / getCards / addCard |
| `status_api.dart` | 🟠二开 | getUserStatus / batchGetStatus |
| `media_api.dart` | 🔵原生 | uploadImage / uploadVideo / uploadFile / getObjectURL |
| `user_api.dart` | 🟠二开 | getIPInfo / getOnlineStatus (管理端) |

#### 2.1.4 服务层

| 服务 | 分类 | 功能 |
|------|------|------|
| `im_polling_service.dart` | 🟢前端 | 10 秒间隔轮询新消息 + 自动注入 ChatController |
| `auth_storage_service.dart` | 🟢前端 | SharedPreferences Token 持久化 |
| `device_info_service.dart` | 🟢前端 | 平台检测 (iOS=1, Android=2, Web=3...) |
| `audio_playback_service.dart` | 🟢前端 | 语音消息播放 + 进度回调 |
| `audio_cache_service.dart` | 🟢前端 | 语音文件本地缓存 |
| `feature_registry.dart` | 🟠二开 | 功能开关前端注册表 |

#### 2.1.5 消息类型支持

| 类型 | contentType | 发送 | 接收/渲染 | Widget |
|------|-------------|------|----------|--------|
| 文本 | 101 | ✅ | ✅ | `text_message_content.dart` |
| 图片 | 102 | ✅ | ✅ | `image_message_content.dart` |
| 语音 | 103 | ✅ | ✅ | `voice_message_content.dart` |
| 视频 | 104 | ✅ | ✅ | `video_message_content.dart` |
| 文件 | 105 | ✅ | ✅ | `file_message_content.dart` |
| 位置 | 106 | ✅ | ✅ | `location_message_content.dart` |
| 名片 | 108 | ✅ | ✅ | `contact_message_content.dart` |
| 引用 | 114 | ✅ | ✅ | `quote_message_content.dart` |
| 合并转发 | 115 | ✅ | ✅ | `merge_message_content.dart` |
| 贴纸 | 201 | ✅ | ✅ | `sticker_message_content.dart` |
| 系统通知 | 1400+ | — | ✅ | 内联于 message bubble |

#### 2.1.6 共享组件库 (30+)

UI 原子组件：`AppButton` / `AppCard` / `AppText` / `AppTag` / `AppBadge` / `AppHeader` / `AppListTile` / `AppFeedback` / `AppModal` / `AppBottomSheet`  
业务组件：`UserAvatar` / `OnlineStatusWidget` / `VerifiedBadge` / `ConversationItem` / `MessageInput` / `VoiceRecordSheet` / `NetworkErrorWidget`

---

### 2.2 Go 后端 (openim-chat)

> openim-chat 在 OpenIM 原版基础上进行了**大规模二次开发**，新增 ~130+ 管理端端点和 ~25+ 聊天端端点。

#### 2.2.1 Admin API 处理器 (20+ 文件)

| 模块 | 文件 | 分类 | 状态 |
|------|------|------|------|
| 管理员认证 | `admin.go` | 🔵原生+改 | ✅ bcrypt 渐进迁移 |
| Token 刷新 | `refresh_token.go` | 🟠二开 | ✅ |
| Token 管理器 | `token_manager.go` | 🟠二开 | ✅ |
| TOTP 双因素 | `totp_manager.go` | 🟠二开 | ✅ AES-256-GCM 加密 |
| 安全审计日志 | `security_log_manager.go` | 🟠二开 | ✅ |
| 消息管理 | `message_manager.go` | 🟠二开 | ✅ 管理员撤回/删除 |
| 置顶消息 | `pinned_message_manager.go` | 🟠二开 | ✅ |
| 系统广播 | `broadcast_manager.go` + `broadcast_worker.go` | 🟠二开 | ✅ Redis MQ + Worker Pool |
| 批量创建 | `batch_create.go` | 🟠二开 | ✅ |
| 用户管理扩展 | `user_admin_manager.go` | 🟠二开 | ✅ |
| IP 角色管理 | `ip_role_manager.go` | 🟠二开 | ✅ |
| 钱包管理 | `wallet_manager.go` | 🟠二开 | ✅ 余额调整 + 审计日志 |
| 接待号管理 | `receptionist_manager.go` | 🟠二开 | ✅ |
| 功能开关 | `feature_toggle_manager.go` | 🟠二开 | ✅ |
| 群组限制 | `group_restriction_manager.go` | 🟠二开 | ✅ |
| 官方群组 | `official_group_manager.go` | 🟠二开 | ✅ |
| 群组配置 | `group_config_manager.go` | 🟠二开 | ✅ |
| 规则引擎 | `rule_engine.go` + 7 个 `rule_*.go` | 🟠二开 | ✅ |
| 权限管理 | `permission_manager.go` | 🟠二开 | ✅ RBAC |
| 白名单 | `whitelist_manager.go` | 🟠二开 | ✅ |
| 配置中心 | `config_manager.go` | 🟠二开 | ✅ etcd 热更新 |
| OpenAPI | `openapi.go` | 🟠二开 | ✅ Swagger 文档 |
| 内容过滤 | `content_filter_*.go` | 🟠二开 | ✅ |

#### 2.2.2 Chat API 处理器 (10+ 文件)

| 模块 | 文件 | 分类 | 状态 |
|------|------|------|------|
| 在线状态服务 | `presence_service.go` + `presence_gateway.go` + `presence_events.go` | 🟠二开 | ✅ |
| 状态查询 | `status_handler.go` | 🟠二开 | ✅ |
| 接待号（客户端） | `receptionist_handler.go` | 🟠二开 | ✅ |
| 推荐系统 | `referral_handler.go` | 🟠二开 | ✅ |
| 钱包操作 | `wallet_handler.go` | 🟠二开 | ✅ 提现=直接拒绝 |
| 收藏消息 | `starred_handler.go` | 🟠二开 | ✅ |
| 群组限制（客户端） | `group_restriction_handler.go` | 🟠二开 | ✅ |
| 官方群组（客户端） | `official_group_chat_handler.go` | 🟠二开 | ✅ |
| 消息操作 | `message_handler.go` | 🟠二开 | ✅ |
| IP 信息查询 | `ip_info_handler.go` | 🟠二开 | ✅ |

#### 2.2.3 自定义数据库表 (20+)

| 表名 | 用途 |
|------|------|
| `broadcast` | 系统广播（标题/内容/状态/发送目标） |
| `wallet` | 用户钱包余额 |
| `wallet_transaction` | 钱包交易流水 |
| `wallet_adjust_logs` | 管理员余额调整审计日志 |
| `feature_toggle` | 功能开关配置 |
| `group_restriction` | 群组创建/加入限制规则 |
| `receptionist` (invite_code + customer_binding) | 接待号绑定 |
| `referral` | 推荐关系 |
| `starred_message` | 收藏消息 |
| `content_filter_rule` | 内容过滤规则 |
| `message_edit` | 消息编辑记录 |
| `forbidden_account` | 用户封禁 |
| `official_group` | 官方群标记 |
| `pinned_message` | 置顶消息 |
| `whitelist` | 登录白名单 |
| `admin_permission` | 管理员权限 |
| `rule_snapshot` | 规则引擎快照 |
| `ip_forbidden` | IP 封禁 |
| `limit_user_login_ip` | 用户 IP 登录限制 |
| `invitation_register` | 邀请码 |
| `admin_totp_secrets` | TOTP 凭据（AES-256-GCM 加密） |

#### 2.2.4 自定义中间件 (17+)

| 中间件 | 功能 |
|--------|------|
| RBAC | 基于角色的访问控制 |
| Rate Limiter | 60/min 通用 + 5/min 认证 + 账户锁定 |
| Sensitive Verify | HMAC-SHA256 挑战-响应（密码确认） |
| Risk Control | IP + 管理员风险评分 |
| OpenAPI Validator | 请求/响应 Swagger 校验 |
| Device Bind | 设备绑定 |
| Tenant | 多租户 |
| Trace | 请求追踪 |
| Access Log | 访问日志 |
| Metrics | 指标采集 |
| Secure Response | 响应安全头 |
| Validation | 请求参数校验 |
| WS Auth | WebSocket 认证 |
| CSRF | 跨站请求伪造防护 |
| Security Headers | 安全 HTTP 头 |
| Cookie Auth | Cookie 认证 |
| Audit Middleware | 敏感操作审计 |

---

### 2.3 Admin Web 管理后台

#### 2.3.1 路由/页面清单 (31 路由)

| 分类 | 页面 | 路由 | 分类标记 | 状态 |
|------|------|------|---------|------|
| **仪表盘** | 数据概览 | `/dashboard` | 🔵原生 | ✅ |
| **账户** | 个人中心 | `/account/center` | 🟠二开 | ✅ |
| **账户** | 个人设置 | `/account/settings` | 🟠二开 | ✅ |
| **账户** | 权限管理 | `/account/permissions` | 🟠二开 | ✅ |
| **账户** | 双因素认证 | `/account/2fa` | 🟠二开 | ✅ |
| **用户管理** | 用户列表 | `/user-manage/list` | 🔵原生+改 | ✅ |
| **用户管理** | 在线用户 | `/user-manage/online` | 🔵原生 | ✅ |
| **用户管理** | 封禁管理 | `/user-manage/block` | 🔵原生+改 | ✅ |
| **用户管理** | 批量创建 | `/user-manage/batch` | 🟠二开 | ✅ |
| **群组管理** | 群组管理 | `/group-manage` | 🔵原生 | ✅ |
| **消息管理** | 消息搜索 | `/msg-manage/search` | 🔵原生 | ✅ |
| **消息管理** | 发送消息 | `/msg-manage/send` | 🔵原生 | ✅ |
| **消息管理** | 系统广播 | `/msg-manage/broadcast` | 🟠二开 | ✅ |
| **系统管理** | 管理员 | `/system/admin` | 🔵原生+改 | ✅ |
| **系统管理** | IP 封禁 | `/system/ip-forbidden` | 🔵原生 | ✅ |
| **系统管理** | IP 登录限制 | `/system/ip-user-limit` | 🟠二开 | ✅ |
| **系统管理** | 用户端管理员 | `/system/user-admin` | 🟠二开 | ✅ |
| **系统管理** | 资金管理 | `/system/wallet` | 🟠二开 | ✅ |
| **系统管理** | 配置中心 | `/system/config-center` | 🟠二开 | ✅ |
| **系统管理** | 内容过滤 | `/system/content-filter` | 🟠二开 | ✅ |
| **系统管理** | 功能开关 | `/system/feature-toggle` | 🟠二开 | ✅ |
| **系统管理** | 版本管理 | `/system/version` | 🟠二开 | ✅ |
| **系统管理** | 限流策略 | `/system/ratelimit` | 🟠二开 | ✅ |
| **系统管理** | 策略引擎 | `/system/policy` | 🟠二开 | ✅ |
| **安全管理** | 登录白名单 | `/security/whitelist` | 🟠二开 | ✅ |
| **安全管理** | 接待员管理 | `/security/receptionist` | 🟠二开 | ✅ |
| **安全管理** | 审计日志 | `/security/logs` | 🟠二开 | ✅ |
| **Banner** | Banner 管理 | `/banner-manage` | 🟠二开 | ⚠️ 隐藏 (10011 未部署) |
| **注册设置** | 邀请码 | `/register-setting/invitation` | 🔵原生 | ✅ |
| **注册设置** | 默认好友 | `/register-setting/default-friend` | 🔵原生 | ✅ |
| **注册设置** | 默认群组 | `/register-setting/default-group` | 🔵原生 | ✅ |

#### 2.3.2 API 函数统计

Admin Web 的 `src/services/openim/api.ts` 实现了 **~120+ API 函数**，按分类：

| 分类 | 函数数 | 代表方法 |
|------|--------|---------|
| 认证 & 2FA | 13 | adminLogin, setup2FA, verify2FA, login2FA |
| 用户管理 | 18 | searchUsers, blockUser, batchRegisterUsers, setAppRole |
| 群组管理 | 10 | getGroups, dismissGroup, muteGroup, setOfficialGroup |
| 消息管理 | 6 | searchMessages, sendMessage, adminRecallMessage |
| 统计 | 5 | getDashboardStats, getUserRegisterStats |
| 管理员 | 3 | searchAdmins, addAdmin, deleteAdmin |
| 邀请码 | 3 | searchInvitationCodes, genInvitationCodes |
| IP 管理 | 6 | searchForbiddenIPs, addForbiddenIP, addUserIPLimitLogin |
| 默认好友/群 | 6 | searchDefaultFriends, addDefaultFriends |
| 白名单 | 4 | searchWhitelist, addWhitelistUser |
| 接待员 | 4 | searchReceptionistInviteCodes, listReceptionistBindings |
| 用户端管理员 | 4 | searchUserAdmins, addUserAdmin, getReferralUsers |
| 钱包 | 5 | getUserWallet, adjustWalletBalance, reviewWithdraw |
| 安全日志 | 1 | searchSecurityLogs |
| 广播 | 6 | createBroadcast, sendBroadcast, searchBroadcasts |
| 内容过滤 | 3 | getFilterRules, upsertFilterRule |
| 功能开关 | 2 | getFeatureToggles, setFeatureToggle |
| 限流 | 4 | getRateLimitStats, checkDistRateLimit |
| 策略引擎 | 4 | getPolicyRules, evalPolicy, validatePolicy |
| 版本管理 | 4 | pageApplicationVersions, addApplicationVersion |
| 配置中心 | 6 | getConfigList, setConfig, restartService |
| 客户端配置 | 3 | getClientConfig, setClientConfig |

#### 2.3.3 敏感操作（密码门控）

以下操作通过 `sensitiveAdminRequest` 强制密码二次确认：

1. **用户删除** — `deleteUsers(userIDs, password)`
2. **用户角色变更** — `setAppRole(targetUserID, appRole, password)`
3. **余额调整** — `adjustWalletBalance(params, password)`
4. **提现审批** — `reviewWithdraw(requestID, action, password, reason)`
5. **广播发送** — `sendBroadcast(broadcastID, password)`

---

## 3. TODO/FIXME/占位实现

### 3.1 扫描结果

| 项目 | TODO/FIXME 数量 | 说明 |
|------|----------------|------|
| **Flutter App** | **0** | 无任何 TODO/FIXME/HACK/XXX 标注 |
| **Go Backend** | **3** (仅框架级) | `version/base.go` 中 2 个 gitVersion 废弃注释；`version/types.go` 中 1 个 api version 注释 |
| **Admin Web** | **1** (仅框架级) | `.umi/plugin-model/index.tsx` UMI 生成的 TODO；~~`requestErrorConfig.ts` 中 `REDIRECT` case 未实现~~ ✅ 已修复 (2026-03-21) |

### 3.2 需要关注的隐式占位

| 位置 | 问题 | 影响 |
|------|------|------|
| ~~Admin Web `requestErrorConfig.ts:65`~~ | ~~`ErrorShowType.REDIRECT` 分支为空 `break`~~ | ✅ 已修复 (2026-03-21) — 清除 token + 重定向到登录页 |
| ~~Admin Web `config/routes.ts`~~ | ~~4 个路由映射错误~~ | ✅ 已修复 (2026-03-21) — 3 条路径修正 + 移除 `/applet` |
| Go Backend `totp_manager.go` | `ParseToken()` handler 已实现但**未注册路由** | 死代码 |
| Flutter App | `WebSocketService` 文件存在但**零引用** | 死代码（改用 HTTP 轮询后遗留） |

---

## 4. 代码质量问题

### 4.1 🔴 高优先级

#### ~~H1. Flutter: 静默吞噬异常 (16+ 处)~~ ✅ 已修复 (2026-03-21)

所有 17 处 `catch (_) {}` 已替换为 `catch (e) { debugPrint('描述性消息: $e'); }`，覆盖 12 个文件。

---

#### ~~H2. Go: MongoDB 操作未检查错误~~ ✅ 已部分修复 (2026-03-21)

| 文件 | 行 | 操作 | 状态 |
|------|---|------|------|
| `totp_manager.go` | L361 | `DeleteOne()` — 禁用 2FA | ✅ 已添加 error 检查 + `ErrInternalServer` 返回 |
| `totp_manager.go` | L299 | `UpdateOne()` — 启用 2FA | ✅ 已添加 error 检查 + `ErrInternalServer` 返回 |
| `receptionist_handler.go` | L140 | `FindOne().Decode()` | ⚠️ 待修复 |

---

### 4.2 🟡 中优先级

#### ~~M1. Flutter: 6/7 Controller 缺少 `dispose()` 实现~~ ✅ 已修复 (2026-03-21)

全部 7/7 Controller 现在都实现了 `dispose()`。ChatController 额外添加了 `_disposed` 标志位以终止重试循环。

---

#### ~~M2. Go: Goroutine 火烧遗忘模式 (whitelist_manager.go)~~ ✅ 已修复 (2026-03-21)

3 个 goroutine 已改为：`context.Background()` + 10s 超时 + `log.Printf` 错误日志 + 闭包变量拷贝避免竞态。

---

#### M3. Go: `_ = err` 错误丢弃 — ✅ 关键路径已修复 (2026-03-21)

已修复 7 处关键路径：
- ✅ `referral_handler.go` — 5 处 `ImportFriend` / `CountByAdmin` / `SendTextMsg` 改为 `if err := ...; err != nil { log.Printf(...) }`
- ✅ `batch_create.go` — 2 处 `RegisterUser` / `whitelist.Create` 改为错误日志
- ⚠️ `broadcast_worker.go` — 广播状态更新（已有 DLQ 机制，暂不调整）

---

#### ~~M4. Admin Web: 4 个路由映射错误~~ ✅ 已修复 (2026-03-21)

| 路由 | 修复动作 |
|------|----------|
| `/content-filter` | ✅ 组件路径修正为 `./system/content-filter` |
| `/applet` | ✅ 已移除（无对应组件） |
| `/receptionist` | ✅ 组件路径修正为 `./security/receptionist` |
| `/wallet/withdraw-audit` | ✅ 组件路径修正为 `./system/wallet` |

---

### 4.3 🟢 低优先级

| 编号 | 问题 | 位置 |
|------|------|------|
| L1 | `console.log` 遗留在生产代码 | `openim-admin-web/src/global.tsx:18` |
| L2 | 大量 `any` 类型使用 | `requestErrorConfig.ts`, `services/swagger/*.ts` |
| L3 | Banner 服务端口 10011 未部署，页面已隐藏 | `banner-manage/index.tsx` |
| L4 | `ParseToken()` handler 已编写但未注册路由 | `openim-chat/internal/api/admin/admin.go:558` |

---

## 5. 优先级排序的下一步工作

### P0 — 紧急 (影响核心功能) ✅ 全部完成 (2026-03-21)

| # | 任务 | 状态 |
|---|------|------|
| **P0-1** | Flutter Controller dispose() — 6 个 Controller 全部实现 | ✅ |
| **P0-2** | Go TOTP MongoDB 错误检查 — UpdateOne/DeleteOne 补充错误返回 | ✅ |
| **P0-3** | Admin Web 路由映射 — 3 条修正 + 1 条移除 | ✅ |

### P1 — 重要 (稳定性 & 可维护性) ✅ 全部完成 (2026-03-21)

| # | 任务 | 状态 |
|---|------|------|
| **P1-1** | Flutter 静默异常处理 — 17 处 catch 块全部添加 debugPrint 日志 (12 文件) | ✅ |
| **P1-2** | Go whitelist_manager 同步可靠性 — 3 个 goroutine 添加超时 + 错误日志 + 变量拷贝 | ✅ |
| **P1-3** | Go `_ = err` 修复 — referral_handler 5 处 + batch_create 2 处 | ✅ |
| **P1-4** | Admin Web REDIRECT 错误处理 — 清除 token + history.replace('/login') | ✅ |

### P2 — 改进 (用户体验 & 代码质量)

| # | 任务 | 涉及文件 | 工作量 |
|---|------|---------|--------|
| **P2-1** | **消息实时性提升** — 可考虑将 10s 轮询改为 WebSocket 长连接 + 轮询降级 | `im_polling_service.dart`, `websocket_service.dart` | 大 |
| **P2-2** | **清理死代码** — 删除未使用的 `WebSocketService` 文件和未注册的 `ParseToken()` handler | 2 个文件 | 小 |
| **P2-3** | **TypeScript 类型安全** — 逐步消除 `any` 类型，添加严格接口定义 | `requestErrorConfig.ts`, `swagger/*.ts` | 中 |
| **P2-4** | **前端单元测试** — Flutter 和 Admin Web 目前均无业务逻辑单元测试 | `test/` 目录 | 大 |
| **P2-5** | **Banner 服务集成** — 如需 Banner 功能，需部署 10011 端口服务并取消路由隐藏 | Docker + 前端 | 中 |

### P3 — 可选 (长期改进)

| # | 任务 | 说明 |
|---|------|------|
| **P3-1** | **集成 OpenIM Flutter SDK** | 替代 HTTP 轮询，获得实时消息推送、离线推送、消息撤回回调等 |
| **P3-2** | **国际化 (i18n)** | Flutter 和 Admin Web 当前均为中文硬编码字符串 |
| **P3-3** | **CI/CD 流水线** | 自动构建、测试、Docker 镜像推送 |
| **P3-4** | **监控告警** | 基于已有 metrics 中间件构建 Grafana 面板 |

---

## 附录: 功能模块统计

| 维度 | 数量 |
|------|------|
| Flutter 页面 (Mobile+Desktop+Web+共享) | **30** |
| Flutter Controller | **7** |
| Flutter API 文件 | **8** |
| Flutter 消息类型 | **11** |
| Flutter 共享组件 | **30+** |
| Go Admin API 端点 | **~130+** |
| Go Chat API 端点 | **~25+** |
| Go 自定义数据库表 | **20+** |
| Go 自定义中间件 | **17+** |
| Admin Web 路由 | **31** |
| Admin Web API 函数 | **~120+** |
| 敏感操作 (密码门控) | **5** |
| **总功能模块** | **~300+ 端点/页面/组件** |

| 功能类型 | 数量 | 占比 |
|----------|------|------|
| 🔵 OpenIM 原生/微调 | ~40% | 基础 IM + 用户/群/消息/邀请码 |
| 🟠 二开/自研 | ~50% | 钱包/广播/接待号/白名单/风控/策略/RBAC/2FA/... |
| 🟢 纯前端 | ~10% | 首页/设置/关于/主题/平台适配 |
