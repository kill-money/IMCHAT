# 兴村振兴3.0 IM — 开发变更记录

> 项目名称：兴村振兴3.0 IM（openim_flutter_app）  
> 技术栈：Flutter 3.27.4 + Go（openim-chat 二开）+ OpenIM v3.8.x + Docker  
> 文档维护：每次功能迭代后更新本文件

---

## 版本概览

| 版本 | 日期 | 内容摘要 |
|------|------|----------|
| v0.1.0 | — | 项目脚手架，多平台适配布局 |
| v0.2.0 | — | 登录/注册认证模块 |
| v0.3.0 | — | 会话列表与聊天模块 |
| v0.4.0 | — | 【二开】钱包系统 |
| v0.5.0 | — | 【二开】在线状态系统（Presence）|
| v0.6.0 | — | 【二开】IP 溯源系统 |
| v0.7.0 | — | 【二开】推荐人/接待员系统 |
| v0.8.0 | — | App 图标替换（全平台）|
| v0.9.0 | — | 后端：Presence Gateway（Go）|
| v0.10.0 | — | 压力测试脚本（k6）|

---

## v0.1.0 — 项目脚手架

### 新增文件
| 文件 | 说明 |
|------|------|
| `lib/main.dart` | App 入口，平台检测，Provider 注册，路由配置 |
| `lib/core/api/api_client.dart` | ApiConfig（host、token），ImApi/ChatApi HTTP 封装 |
| `lib/ui/mobile/mobile_layout.dart` | 移动端底部导航（消息/通讯录/我的）|
| `lib/ui/desktop/desktop_layout.dart` | 桌面三栏布局（图标侧栏 + 会话列表 + 聊天区）|
| `lib/ui/web/web_layout.dart` | Web 响应式布局 |
| `lib/core/desktop_window.dart` | 桌面窗口尺寸（1100×700）+ 系统托盘最小化 |
| `lib/shared/theme/` | 主题色（colors.dart）、间距（spacing.dart）、排版（typography.dart）、app_theme.dart |
| `lib/shared/widgets/ui/` | 设计系统原子组件：AppButton、AppCard、AppBadge、AppHeader、AppModal、AppFeedback、AppProgressBar、AppTag、AppText |
| `pubspec.yaml` | 依赖：http、provider、web_socket_channel、window_manager、system_tray、flutter_localizations |

### 关键设计决策
- API Host 通过 `--dart-define=API_HOST=` 编译期注入，默认 `192.168.0.136`
- 平台路由通过 `kIsWeb` / `Platform.isWindows` 在 `main.dart` 判断，`/home` 路由返回对应平台 Layout
- 三个后端服务端口：im-server:10002、chat-api:10008、admin-api:10009、WS:10001

---

## v0.2.0 — 认证模块

### 新增文件
| 文件 | 说明 |
|------|------|
| `lib/core/api/auth_api.dart` | login（POST /account/login）、register（POST /account/register）、getUserToken |
| `lib/core/controllers/auth_controller.dart` | 状态管理：login/logout/register，错误码映射，受保存 imToken/chatToken/userID |
| `lib/core/models/user_info.dart` | UserInfo：nickname、faceURL、phoneNumber、appRole |
| `lib/shared/pages/auth_page.dart` | Tab 切换（登录Tab + 注册Tab），内联错误横幅 |
| `lib/shared/pages/login_page.dart` | 手机号 + 区号下拉 + 密码表单，动画错误提示 |
| `lib/shared/pages/register_page.dart` | 昵称 + 手机号 + 密码 + 邀请码表单 |
| `lib/shared/pages/splash_page.dart` | 启动页（3秒后跳转 /login），全屏启动图 |

### 错误码映射（AuthController）
| 错误码 | 含义 |
|--------|------|
| 20001 | 手机号未注册 |
| 20002 | 手机号已被注册 |
| 20003 | 密码错误（建议：不超过6次）|
| 20004 | 邀请码错误 |
| 20005 | 用户已被封禁 |
| 20006-20014 | 其他业务错误（已映射中文提示）|
| 10001 | 网络连接失败 |
| 10002 | 服务器内部错误 |

---

## v0.3.0 — 会话列表与聊天模块

### 新增文件
| 文件 | 说明 |
|------|------|
| `lib/core/api/chat_api.dart` | ConversationApi（get_sorted_conversation_list）、MsgApi（send_msg、pull_msg_by_seqs）、UserApi（get_users_info）全部对接 im-server:10002 |
| `lib/core/controllers/conversation_controller.dart` | loadConversations（分页）、getById |
| `lib/core/controllers/chat_controller.dart` | loadHistory、sendTextMessage、addIncomingMessage；`_messageMap` 按 conversationID 索引 |
| `lib/core/models/conversation.dart` | Conversation：conversationID、userID、showName、unreadCount、latestMsg 等 |
| `lib/core/models/message.dart` | Message 数据模型 |
| `lib/ui/mobile/pages/mobile_conversations_page.dart` | 会话列表页，下拉刷新，加载时获取在线状态 |
| `lib/ui/mobile/pages/mobile_chat_page.dart` | 聊天页，消息气泡列表，带滚动控制器 |
| `lib/ui/mobile/pages/mobile_contacts_page.dart` | **占位符**（待实现，当前仅显示图标）|
| `lib/shared/widgets/conversation_item.dart` | 会话列表项，用户头像 + 最新消息 + 未读角标 |
| `lib/shared/widgets/chat_bubble.dart` | 消息气泡（自己/对方样式区分）|
| `lib/shared/widgets/message_input.dart` | 消息输入框 + 发送按钮 |
| `lib/shared/widgets/user_avatar.dart` | 用户头像（字母头像 fallback）|
| `lib/utils/permission.dart` | 权限工具类 |

---

## v0.4.0 — 【二开】钱包系统

> **文件标记**：所有涉及文件注释含 `// 钱包`

### 新增文件
| 文件 | 说明 |
|------|------|
| `lib/core/models/wallet.dart` | WalletAccount（余额，单位分，balanceYuan 转元）、BankCard（id/bankName/cardNumber/cardHolder）|
| `lib/core/api/wallet_api.dart` | getWalletInfo、listCards、addCard、removeCard、withdraw — 全部 POST 到 chat-api:10008 |
| `lib/core/controllers/wallet_controller.dart` | loadWallet、loadCards、addCard、removeCard、withdraw；withdraw 返回错误信息字符串 |
| `lib/ui/mobile/pages/mobile_wallet_page.dart` | 完整 UI：余额卡片、银行卡列表、「添加银行卡」Dialog（银行名/卡号/持卡人）、「提现」Dialog（选卡+金额输入）|

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `lib/main.dart` | Provider 列表新增 `WalletController` |
| `lib/ui/mobile/pages/mobile_profile_page.dart` | 个人资料页新增「我的钱包」入口，点击 `Navigator.push` 到 MobileWalletPage |

---

## v0.5.0 — 【二开】在线状态系统（Presence Gateway）

> 分 Phase 1–4 实现，全部已完成。  
> **文件标记**：所有涉及文件注释含 `// 在线状态`

### 新增文件
| 文件 | 说明 |
|------|------|
| `lib/core/models/user_status.dart` | UserStatus（上次在线时间戳、isOnline 计算）、LastSeenPrivacy enum（everyone/contacts/nobody）、`lastSeenText`（Telegram 风格：「刚刚在线」「5分钟前」「今天」等）|
| `lib/core/api/status_api.dart` | getUserStatus、getBatchStatus（≤100 IDs/次）、getMyPrivacy、setMyPrivacy — 全部对接 chat-api:10008 |
| `lib/core/controllers/status_controller.dart` | LRU 缓存（max: 1000，TTL: 30s）、50ms debounce 批量合并请求、每批 ≤100 IDs、WS 重连补偿（重连后重新拉取所有缓存用户）、connectWebSocket/disconnectWebSocket/loadMyPrivacy/setPrivacy |
| `lib/core/services/websocket_service.dart` | **改造为 Presence Gateway WS**，连接 `ws://$apiHost:10008/ws/presence?token={chatToken}`（原 im WS 10001 不改动）、30s 心跳 `{'event':'heartbeat'}`、指数退避重连（2s→60s）、解析 `user_status_change` JSON 事件、`onReconnect` 回调 |

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `lib/main.dart` | Provider 新增 `StatusController`；`_HomeWrapper.initState` 调用 `statusCtrl.connectWebSocket()` 和 `loadMyPrivacy()` |
| `lib/core/api/api_client.dart` | 新增 `ApiConfig.presenceWsUrl` getter |
| `lib/shared/widgets/user_avatar.dart` | 新增 `isOnline` 参数，右下角绿点（10px #4CAF50，AnimatedOpacity 平滑淡入/出）|
| `lib/shared/widgets/conversation_item.dart` | 从 StatusController 读取在线状态，在线用户显示绿色副标题 + `lastSeenText`，UserAvatar 传 `isOnline` |
| `lib/ui/mobile/pages/mobile_conversations_page.dart` | initState 时批量 fetchStatuses（所有会话对方 userID）|

---

## v0.6.0 — 【二开】管理员 IP 溯源系统

> **文件标记**：涉及文件注释含 `// IP溯源`

### 新增文件
| 文件 | 说明 |
|------|------|
| `lib/core/api/user_api.dart` | `UserApi.getUserIPInfo({required String targetUserID})`，POST `/user/ip_info` 到 chat-api:10008 |
| `lib/shared/widgets/conversation_ip_badge.dart` | 悬浮徽章：后台获取对方最后登录 IP/城市/设备，`canViewIP` 管理员可见，`partnerUserID` 变化时自动刷新 |
| `lib/shared/pages/user_detail_page.dart` | 用户详情页：显示在线状态文字、最后登录 IP（管理员专有），通过 `StatusController.fetchStatus()` 获取数据 |

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `lib/core/models/user_info.dart` | 新增 `appRole`（0=普通用户，1=管理员）、`isUserAdmin`（推荐人专属）、`isAppAdmin`（appRole≥1）、`canViewIP`（isAppAdmin 派生属性）|
| `lib/ui/mobile/pages/mobile_chat_page.dart` | AppBar title 区域对 `canViewIP` 用户显示 `ConversationIPBadge` |
| `lib/ui/mobile/pages/mobile_profile_page.dart` | 管理员在个人资料卡片中可见「最后登录 IP」字段 |
| `lib/shared/widgets/user_avatar.dart` | 新增 `showAdminBadge` 参数，管理员右下角显示盾牌图标（优先级低于绿点）|

---

## v0.7.0 — 【二开】推荐人/接待员绑定系统

> 支持通过邀请链接 `?ref=<code>` 注册时自动绑定推荐关系和接待员。

### 修改文件
| 文件 | 修改内容 |
|------|----------|
| `lib/core/api/api_client.dart` | Web 平台解析 URL `?ref=` 参数，存入 `ApiConfig.downloadReferrer` |
| `lib/core/api/auth_api.dart` | register 请求体新增 `downloadReferrer` 字段（来自 `ApiConfig.downloadReferrer`）|
| `lib/core/controllers/auth_controller.dart` | register 成功后解析 `receptionistID`，保存到 `_lastReceptionistID` |
| `lib/shared/pages/register_page.dart` | 表单新增「邀请码」（invitationCode）字段；注册成功后如有 receptionistID 显示接待员绑定成功提示 |

---

## v0.8.0 — App 图标全平台替换

> 来源图片：`assets/favicon.png`（487×487，蓝色鸽标，圆角）

### Android（`android/app/src/main/res/`）
| 目录 | 尺寸 | 文件 |
|------|------|------|
| mipmap-mdpi | 48×48 | ic_launcher.png |
| mipmap-hdpi | 72×72 | ic_launcher.png |
| mipmap-xhdpi | 96×96 | ic_launcher.png |
| mipmap-xxhdpi | 144×144 | ic_launcher.png |
| mipmap-xxxhdpi | 192×192 | ic_launcher.png |

### iOS（`ios/Runner/Assets.xcassets/AppIcon.appiconset/`）
15 个尺寸，20pt → 1024pt（含 @2x/@3x 变体）

### Web（`web/`）
| 文件 | 尺寸 |
|------|------|
| favicon.png | 32×32 |
| icons/Icon-192.png | 192×192 |
| icons/Icon-512.png | 512×512 |
| icons/Icon-maskable-192.png | 192×192 |
| icons/Icon-maskable-512.png | 512×512 |

### Windows（`windows/runner/resources/app_icon.ico`）
多尺寸 ICO：16/24/32/48/64/128/256

### 系统托盘（桌面）
`assets/app_icon.png`（256×256），`SystemTray.setSystemTrayInfo` 使用

---

## v0.9.0 — 后端：Presence Gateway（Go）

> 文件位于 `openim-chat/` 目录，在 openim-chat 二开基础上新增。

### 新增/修改后端文件
| 文件 | 类型 | 说明 |
|------|------|------|
| `openim-chat/go.mod` | 修改 | 新增 `github.com/gorilla/websocket` 直接依赖 |
| `openim-chat/internal/api/chat/start.go` | 修改 | 初始化 PresenceGateway，注册 `GET /ws/presence` 路由 |
| `openim-chat/internal/api/chat/presence_gateway.go` | 新增 | WS Hub 实现：客户端注册/注销、广播 status_change 事件 |
| `openim-chat/internal/api/chat/status_handler.go` | 新增 | HTTP Handler：getBatchStatus、getUserStatus、getMyPrivacy、setMyPrivacy；Redis PubSub 监听状态变更推送 |
| `openim-chat/pkg/common/db/cache/status.go` | 存量（复用）| Redis 状态读写层 |

### 接口清单（chat-api:10008）
| 路径 | 方法 | 说明 |
|------|------|------|
| `GET /ws/presence` | WS Upgrade | Presence WebSocket，`?token=` 认证 |
| `POST /user/status` | HTTP | 查询单个用户状态 |
| `POST /user/batch_status` | HTTP | 批量查询（≤100 IDs）|
| `POST /user/privacy` | HTTP | 查询当前用户隐私设置 |
| `POST /user/set_privacy` | HTTP | 修改隐私设置 |
| `POST /user/ip_info` | HTTP | 管理员查询 IP 信息 |

---

## v0.10.0 — 压力测试脚本

> 工具：k6 (`openim-chat/tests/load/presence_load_test.js`)

### 测试场景
| 场景 | 模式 | VU 数量 | 说明 |
|------|------|---------|------|
| `batch_status_query` | HTTP | 5000 | 批量状态接口压测 |
| `ws_presence_connections` | WebSocket | 10000 | WS 连接并发压测 |

### SLA 阈值
- p95 响应时间 < 10ms
- WS 错误数 < 100
- 整体错误率 < 1%

---

## 已知问题与待开发功能

### 已修复
| Issue | 修复版本 | 说明 |
|-------|---------|------|
| `conversation_ip_badge.dart` 导入错误 | hotfix | 错误导入 `chat_api.dart` 改为 `user_api.dart`，参数名 `userID` 改为 `targetUserID` |
| 文档注释 HTML 尖括号警告 | hotfix | `<chatToken>` 改为 `{chatToken}` |

### 待实现
| 功能 | 优先级 | 位置 |
|------|--------|------|
| 通讯录页面（好友列表/搜索/添加好友）| P1 | `lib/ui/mobile/pages/mobile_contacts_page.dart`（当前为占位符）|
| 桌面端会话列表状态集成 | P2 | `lib/ui/desktop/` |
| Web 端状态显示集成 | P2 | `lib/ui/web/` |
| 设置页（隐私/通知/主题）| P3 | `lib/ui/mobile/pages/` 占位符 |
| 关于页 | P3 | 占位符 |
| iOS 真机测试 | P2 | — |

---

## 系统架构图

```
┌─────────────────────────────────────────────────┐
│               Flutter Client（兴村振兴3.0）         │
│   Mobile / Desktop / Web（同一代码库）          │
└───────────────┬─────────────────────────────────┘
                │ HTTP / WebSocket
        ┌───────┴──────────────┐
        │                      │
  ┌─────┴──────┐         ┌─────┴──────┐
  │ chat-api   │         │ im-server  │
  │  :10008    │         │  :10002    │
  │            │         │  WS:10001  │
  │ /account/* │         │  /msg/*    │
  │ /user/*    │         │ /conversation/*│
  │ /wallet/*  │         └────────────┘
  │ /ws/presence│
  └─────┬──────┘
        │
  ┌─────┴──────┐
  │   Redis    │
  │ (PubSub)  │
  └────────────┘
```

---

## 文件完整性检查记录（最后验证时间）

运行 `flutter analyze` 结果：**No issues found**

| 模块 | 文件数 | 状态 |
|------|-------|------|
| core/api | 6 | ✅ 完整 |
| core/controllers | 5 | ✅ 完整 |
| core/models | 5 | ✅ 完整 |
| core/services | 1 | ✅ 完整 |
| ui/mobile | 6（layout + 5 pages）| ✅ 完整 |
| ui/desktop | 3（layout + 2 pages）| ✅ 完整 |
| ui/web | 3（layout + 2 pages）| ✅ 完整 |
| shared/pages | 5 | ✅ 完整 |
| shared/widgets | 7（含 ui/ 9个原子组件）| ✅ 完整 |
| shared/theme | 4 | ✅ 完整 |
| utils | 1 | ✅ 完整 |
| assets | — | ✅ 完整（config/images/app_icon.png）|

**所有二开功能模块均已到位，无文件缺失或路径错乱。**
