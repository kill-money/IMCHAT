# 项目状态报告 — IMCHAT 全栈审计

> 生成日期：2025-07-18  
> 范围：Flutter 客户端 · Go 后端 (openim-chat) · React 管理后台 (openim-admin-web)

---

## 目录

1. [项目概览](#1-项目概览)
2. [已实现功能清单](#2-已实现功能清单)
3. [未完成 / TODO / FIXME](#3-未完成--todo--fixme)
4. [生产质量问题](#4-生产质量问题)
   - 4.1 错误处理
   - 4.2 权限与安全
   - 4.3 资源清理
   - 4.4 数据一致性
   - 4.5 硬编码值
   - 4.6 UI/UX 问题
   - 4.7 安全漏洞
5. [生产就绪评分](#5-生产就绪评分)

---

## 1. 项目概览

| 组件 | 技术栈 | 代码行 (估) | 文件数 |
|------|--------|-------------|--------|
| **Flutter 客户端** | Dart 3.x + Flutter 3.6 + OpenIM SDK 3.8 | ~15,000 | ~80 |
| **Go 后端** (openim-chat) | Go 1.21 + Gin + MongoDB + Redis | ~25,000 | ~60 |
| **Admin 管理后台** | React 19 + UMI 4 + Ant Design 6 + TypeScript 5 | ~12,000 | ~45 |
| **基础设施** | Docker Compose + Nginx + Redis + MongoDB | — | ~10 |

### 服务架构

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Flutter App  │────▶│ openim-chat  │────▶│ openim-server│
│ (多平台客户端) │     │ :10008/:10009│     │ :10001/:10002│
└──────────────┘     └──────────────┘     └──────────────┘
                            │
┌──────────────┐            │
│ Admin Web    │────────────┘
│ (管理后台:8001)│
└──────────────┘
```

---

## 2. 已实现功能清单

### 2.1 Flutter 客户端（39 页面 · 7 Controller · 6 Service）

| 模块 | 功能 | 状态 | 核心文件 |
|------|------|------|----------|
| **认证** | 登录 / 注册 / 忘记密码 / 会话恢复 | ✅ 完整 | auth_controller.dart, auth_api.dart |
| **会话** | 会话列表 / 搜索 / 删除 / 置顶 | ✅ 完整 | conversation_controller.dart |
| **消息** | 文本 / 图片 / 语音 / 视频 / 文件 / 表情 / 位置 / 引用 / 合并转发 | ✅ 完整 | chat_controller.dart, message.dart |
| **消息操作** | 收藏 / 撤回 / 编辑 / 删除 / 重试队列 | ✅ 完整 | chat_controller.dart |
| **好友** | 好友列表 / 添加好友 / 删除好友 / 好友申请 | ✅ 完整 | mobile_contacts_page.dart |
| **群聊** | 创建群 / 群详情 / 成员管理 / 踢人 / 群编辑 | ✅ 完整 | group_controller.dart, group_api.dart |
| **用户资料** | 个人主页 / 编辑资料 / 用户详情 / IP 溯源 | ✅ 完整 | user_detail_page.dart |
| **在线状态** | 实时在线/离线 / 隐私设置 / WebSocket 推送 | ✅ 完整 | status_controller.dart, websocket_service.dart |
| **钱包** | 余额显示 / 银行卡管理 / 提现（受控） | ✅ 完整 | wallet_controller.dart, wallet_api.dart |
| **设置** | 移动端/桌面端/Web 端设置 / 密码修改 / 关于页 | ✅ 完整 | mobile_settings_page.dart |
| **隐私** | "最后在线时间" 可见范围设置 | ✅ 完整 | privacy_settings_page.dart |
| **设备管理** | 已登录设备列表 / 远程踢出 | ✅ 完整 | device_manage_page.dart |
| **多媒体** | 图片查看器 / 语音录制播放 / 文件上传下载 | ✅ 完整 | media_api.dart, audio_playback_service.dart |
| **内容过滤** | 群聊敏感信息拦截（联系方式/URL） | ✅ 完整 | content_filter.dart |
| **SDK 抽象层** | IMService 接口 / SDKIMService / HTTPIMService 切换 | ✅ 完整 | im_service.dart, sdk_im_service.dart |
| **多平台** | Mobile (BottomNav) / Desktop (3-Panel+系统托盘) / Web (响应式) | ✅ 完整 | mobile_layout.dart, desktop_layout.dart, web_layout.dart |
| **设计系统** | AppButton/Card/Badge/Header/Modal/Feedback/Tag/ListTile | ✅ 完整 | shared/widgets/ui/ |
| **主题** | 亮/暗双模式 + 中国红主题 + WCAG 对比度工具 | ✅ 完整 | colors.dart, app_theme.dart |

### 2.2 Go 后端 (openim-chat)（200+ 路由 · 17 Manager · 13 Handler）

| 模块 | 功能 | 状态 | 路由数 |
|------|------|------|--------|
| **认证** | admin 登录 / 2FA(TOTP) / 双 Token(access+refresh) / 密码 bcrypt 迁移 | ✅ 完整 | 15 |
| **用户管理** | 搜索 / 批量创建 / JSON/XLSX 导入 / 删除 / appRole / 官方认证 | ✅ 完整 | 20 |
| **封禁系统** | IP 封禁 / 用户封禁 / IP 登录限制 | ✅ 完整 | 9 |
| **钱包** | 余额查询 / 调整 / 交易记录 / 提现审批 | ✅ 完整 | 5 |
| **广播系统** | CRUD / 异步 Redis MQ / Worker Pool(10 goroutine) / DLQ / 批量发送 | ✅ 完整 | 9 |
| **内容过滤** | 规则 CRUD / 消息内容检查（关键词/正则） | ✅ 完整 | 4 |
| **消息操作** | 编辑(2min) / 撤回 / 群消息删除 / 自删 / 合并转发 | ✅ 完整 | 7 |
| **群管理** | 消息置顶 / 群成员最大数 / 群限制(禁止加友/查看资料) / 官方群 | ✅ 完整 | 10 |
| **Feature Toggle** | 编辑消息 / 合并转发 / 内容过滤 开关 | ✅ 完整 | 3 |
| **规则引擎** | 字节码 VM / 策略 DSL / 分片 / 热更新 / 版本回滚 / 快照 | ✅ 完整 | 16 |
| **限流** | 本地限流 + 分布式限流(Redis Lua) / IP 级别 + 行为级别 | ✅ 完整 | 6 |
| **RBAC** | 权限码(wallet:update, block:write, broadcast:manage) / 超级管理员 | ✅ 完整 | 3 |
| **审计日志** | MongoDB + Elasticsearch + 区块链式哈希链 | ✅ 完整 | 1 |
| **在线状态** | 心跳 / 离线 / 批量查询 / 隐私 / WebSocket Presence Gateway | ✅ 完整 | 8 |
| **接待员系统** | 邀请码 / 客户绑定 / 自动加友 | ✅ 完整 | 8 |
| **白名单** | 手机/邮箱准入 + 角色/权限 | ✅ 完整 | 5 |
| **敏感操作验证** | HMAC-SHA256 挑战-应答 / nonce / 操作绑定 | ✅ 完整 | 1 |
| **风控** | 风险评分 / RiskGate 中间件 | ✅ 完整 | 2 |
| **配置中心** | 动态配置 / 热重载 / ETCD 支持 | ✅ 完整 | 6 |
| **应用版本** | 6 平台版本管理 / 强制更新 / 热更新标记 | ✅ 完整 | 4 |
| **Prometheus** | /metrics 端点 | ✅ 完整 | 1 |
| **OpenAPI** | /api-docs/openapi.json 规范 | ✅ 完整 | 1 |

### 2.3 Admin 管理后台（39 页面 · 100+ API 调用）

| 模块 | 功能 | 状态 |
|------|------|------|
| **Dashboard** | 统计概览 / 实时在线数(10s刷新) | ✅ 完整 |
| **用户管理** | 搜索(+IP) / 标签系统 / appRole / 官方认证 / 强制下线 / 批量创建 / 删除 | ✅ 完整 |
| **在线用户** | 实时在线列表 / 平台筛选 | ✅ 完整 |
| **封禁管理** | 封禁/解封 / 搜索 / 原因记录 | ✅ 完整 |
| **群管理** | 搜索 / 禁言 / 解散 / 官方群徽章 | ✅ 完整 |
| **消息管理** | 搜索(sendID/recvID/groupID/keyword) / 手动发送 / 撤回 | ✅ 完整 |
| **广播系统** | 创建/编辑/发送/删除 / 状态跟踪 / DLQ 管理 | ✅ 完整 |
| **管理员** | 添加/删除管理员 / RBAC 权限管理 | ✅ 完整 |
| **2FA** | 启用/禁用 TOTP / QR 码扫描 / 登录二次验证 | ✅ 完整 |
| **白名单** | 手机/邮箱准入 / 角色分配 / 全局开关 | ✅ 完整 |
| **接待员** | 邀请码管理 / 客户绑定 / 解绑 | ✅ 完整 |
| **审计日志** | 按时间/动作/执行者搜索 | ✅ 完整 |
| **钱包管理** | 余额查询 / 调整(2FA) / 交易记录 | ✅ 完整 |
| **IP 封禁** | 添加/删除/搜索封禁 IP | ✅ 完整 |
| **配置中心** | etcd 热重载 / JSON 编辑器 / 重置默认 | ✅ 完整 |
| **版本管理** | 6 平台版本 CRUD / 强制更新 / 热更新 | ✅ 完整 |
| **注册设置** | 邀请码 / 默认好友 / 默认群 | ✅ 完整 |
| **内容过滤** | ⏸ 后端就绪, UI 未实现 | API Only |
| **Feature Toggle** | ⏸ 后端就绪, UI 未实现 | API Only |
| **限流策略** | ⏸ 后端就绪, UI 未实现 | API Only |
| **策略引擎** | ⏸ 后端就绪, UI 未实现 | API Only |

---

## 3. 未完成 / TODO / FIXME

### 3.1 跨项目 TODO/FIXME 汇总

| 优先级 | 文件 | 行号 | 内容 | 影响 |
|--------|------|------|------|------|
| **P0** | [config_controller.dart](openim_flutter_app/lib/core/controllers/config_controller.dart#L72) | 72 | `true; // TODO: 调试完毕后恢复 getBool('use_sdk', defaultValue: false)` | useSDK 硬编码为 true，生产必须恢复远端开关 |
| P2 | open-im-server-main/internal/msggateway/client.go | 223 | `// TODO: callback` | IM 核心服务（非本项目代码） |

### 3.2 Admin Web — 后端就绪但前端 UI 缺失

| 功能 | Admin 路由 | App Status | 影响 |
|------|-----------|------------|------|
| 内容过滤规则管理 | `/system/content-filter` | 路由存在但页面为空 | P2 — 管理员无法通过 UI 管理过滤规则 |
| Feature Toggle 管理 | `/system/feature-toggle` | 路由存在但页面为空 | P2 — 需要直接调 API |
| 限流策略配置 | `/system/ratelimit` | 路由存在但页面为空 | P2 — 需要直接调 API |
| 策略引擎管理 | `/system/policy` | 路由存在但页面为空 | P2 — 需要直接调 API |
| Banner 管理 | `/banner-manage` | 隐藏路由，端口 10011 未部署 | P2 — 非核心功能 |

---

## 4. 生产质量问题

### 4.1 错误处理

#### Flutter — 静默 catch (20+ 处)

| 优先级 | 文件 | 行号 | 问题 |
|--------|------|------|------|
| P1 | [conversation_controller.dart](openim_flutter_app/lib/core/controllers/conversation_controller.dart#L35) | 35 | `catch (_) {}` — 会话加载失败静默swallow |
| P1 | [conversation_controller.dart](openim_flutter_app/lib/core/controllers/conversation_controller.dart#L114) | 114 | `catch (_) {}` — SDK 会话列表失败静默 |
| P1 | [wallet_controller.dart](openim_flutter_app/lib/core/controllers/wallet_controller.dart#L100) | 100 | `catch (_) {}` — 钱包操作失败静默 |
| P1 | [group_controller.dart](openim_flutter_app/lib/core/controllers/group_controller.dart) | 243, 256, 266, 275 | 4 处 `catch (_) {}` — 群操作失败静默 |
| P2 | [mobile_contacts_page.dart](openim_flutter_app/lib/core/../ui/mobile/pages/mobile_contacts_page.dart#L478) | 478 | `catch (_) {}` — 联系人操作失败静默 |
| P2 | [add_friend_page.dart](openim_flutter_app/lib/ui/mobile/pages/add_friend_page.dart) | 62, 72, 87 | 3 处 `catch (_) {}` |
| P2 | [desktop_contacts_page.dart](openim_flutter_app/lib/ui/desktop/pages/desktop_contacts_page.dart) | 319, 372, 388 | 3 处 `catch (_) {}` |
| P2 | [profile_edit_page.dart](openim_flutter_app/lib/shared/pages/profile_edit_page.dart#L68) | 68 | `catch (_) {}` |
| P2 | [forgot_password_page.dart](openim_flutter_app/lib/shared/pages/forgot_password_page.dart) | 76, 108, 147 | 3 处 `catch (_) {}` |
| P2 | [conversation_ip_badge.dart](openim_flutter_app/lib/shared/widgets/conversation_ip_badge.dart#L60) | 60 | `catch (_) {}` |

> **建议**：至少在 catch 块中添加 `debugPrint` 或设置 error state，而非完全静默。

#### Go — 忽略的错误 (20+ 处)

| 优先级 | 文件 | 行号 | 问题 |
|--------|------|------|------|
| P1 | [admin.go](openim-chat/internal/rpc/admin/admin.go#L200) | 200 | `_ = o.Database.UpdateAdmin(...)` — bcrypt 密码迁移写入失败被忽略 |
| P1 | [chat.go](openim-chat/internal/api/chat/chat.go#L170) | 170-173 | `_ = o.imApiCaller.ImportFriend(...)` / `InviteToGroup(...)` — 注册时默认好友/群添加失败静默 |
| P1 | [admin.go](openim-chat/internal/api/admin/admin.go#L893) | 893-896 | 同上，批量注册时 |
| P2 | [admin.go](openim-chat/internal/api/admin/admin.go#L428) | 428 | `_ = o.tokenMgr.RevokeAllSessions(...)` — 删除用户后 token 撤销失败 |
| P2 | [receptionist_handler.go](openim-chat/internal/api/chat/receptionist_handler.go#L247) | 247-248 | `_ = h.imCaller.ImportFriend(...)` — 接待员自动加友失败静默 |
| P2 | [broadcast_worker.go](openim-chat/internal/api/admin/broadcast_worker.go#L258) | 258 | `_ = w.limiter.Wait(ctx)` — 限流等待错误 |
| INFO | [presence_gateway.go](openim-chat/internal/api/chat/presence_gateway.go) | 246-283 | 6 处 `_ = c.conn.Set*Deadline(...)` — WebSocket 超时设定失败（可接受） |

#### Admin Web — 1 处

| 优先级 | 文件 | 行号 | 问题 |
|--------|------|------|------|
| P2 | config-center/index.tsx | ~69 | `catch { // ignore }` — 配置获取失败静默 |

### 4.2 权限与安全

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| ✅ | Admin 认证 | Go middleware | `CheckAdmin` + `CheckSuperAdmin` 完整覆盖 |
| ✅ | RBAC 权限码 | permission_manager.go | `wallet:update`, `block:write`, `broadcast:manage` |
| ✅ | 敏感操作 2FA | sensitive_verify.go | HMAC-SHA256 挑战-应答 + nonce + 操作绑定 |
| ✅ | TOTP 2FA | totp_manager.go | AES-256-GCM 加密密钥存储 |
| ✅ | bcrypt 密码迁移 | admin.go Login() | MD5→bcrypt 渐进式迁移 |
| ✅ | 风控中间件 | risk_control.go | RiskGate IP/行为评分 |
| ✅ | 限流 | AuthRateLimitByIP / RateLimitByBehavior | 登录、注册、敏感操作 |
| ✅ | CSRF | request.ts | X-CSRF-Token 双提交 Cookie |
| ✅ | HttpOnly Cookie | Admin Token | JS 不可读取管理员 Token |
| ✅ | XSS 防护 | Admin Web | Ant Design 自动转义，无 dangerouslySetInnerHTML |
| **P1** | HTTP 明文传输 | [api_client.dart:31-38](openim_flutter_app/lib/core/api/api_client.dart#L31) | 所有 API 使用 `http://` 和 `ws://`，生产需 TLS |
| P2 | Token 刷新竞态 | request.ts:89-105 | 多标签页同时刷新 token 可能状态不一致（SPA 场景低风险） |

### 4.3 资源清理

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| ✅ | Controller dispose | 全部 7 个 Controller | 全部实现 `dispose()` 方法 |
| ✅ | StatefulWidget dispose | 所有页面 | ScrollController/TextEditingController/TabController 全部正确 dispose |
| ✅ | StreamSubscription | chat_controller.dart | `_newMsgSub?.cancel()` 在 dispose 中 |
| ✅ | Timer | contacts_page | 30s 自动刷新 timer 在 dispose 中取消 |
| ✅ | Go 后端 goroutine | broadcast_worker.go | `ctx.Done()` + WaitGroup + ticker.Stop() |
| ✅ | WebSocket 连接 | presence_gateway.go | 读/写循环均有 defer conn.Close() |
| P2 | 调试日志生产残留 | 50+ 处 debugPrint | release 模式下 debugPrint 不输出，但 `[PAGE_INIT]` 等标前缀冗余 |

### 4.4 数据一致性

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| **P1** | MongoDB 无事务 | Go 后端全局 | 所有操作均为单文档 UpdateOne/InsertOne，无 session.StartSession() |
| | | | 钱包余额调整(`wallet_manager.go`)理论上需要事务保证原子性 |
| | | | 当前通过 Redis SETNX 幂等键部分缓解，但非完整 ACID |
| P2 | 广播发送幂等 | broadcast_worker.go | 72h TTL SETNX 幂等键，超时后可能重发（可接受） |

### 4.5 硬编码值

| 优先级 | 文件 | 行号 | 值 | 建议 |
|--------|------|------|-----|------|
| **P0** | [config_controller.dart](openim_flutter_app/lib/core/controllers/config_controller.dart#L72) | 72 | `useSDK = true` 硬编码 | 恢复远端配置：`getBool('use_sdk', defaultValue: false)` |
| P2 | [api_client.dart](openim_flutter_app/lib/core/api/api_client.dart#L22) | 22 | 默认 `127.0.0.1` | 仅开发环境，生产通过 dart-define 注入 ✅ |
| P2 | [api_client.dart](openim_flutter_app/lib/core/api/api_client.dart#L31) | 31-38 | 端口 10001/10002/10008/10009 | 可抽为 dart-define 参数 |
| INFO | broadcast_worker.go | 41-48 | 50 QPS, 100 burst, 500 batch | 已有常量，建议可配置化 |
| INFO | message_manager.go | 39 | `editWindowSeconds = 120` | 可通过 feature_toggle 配置 |

### 4.6 UI/UX 问题

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| P2 | 暗色模式未全覆盖 | colors.dart 定义了暗色色值 + app_theme.dart 定义了 darkTheme | Theme 层完整，但多处页面直接使用 `AppColors.pageBackground` 等亮色常量而非 `Theme.of(context)` |
| P2 | 群转让无 UI | group-manage 页面 | 后端 API 存在 transferGroup，admin-web UI 未暴露按钮 |
| P2 | 撤回消息无 UI | msg-manage/search | 后端 API 存在 revokeMessage，admin-web UI 未暴露按钮 |
| INFO | Web 端窄视口 | web_layout.dart | < 600px 自动切换移动端布局 ✅ |
| INFO | 无障碍支持 | 全局 | 未配置 Semantics label，影响屏幕阅读器 |

### 4.7 安全漏洞

| 优先级 | 问题 | 位置 | 说明 |
|--------|------|------|------|
| **P1** | 无 TLS | Flutter api_client.dart | `http://` 明文传输 token 和消息内容，中间人可嗅探 |
| ✅ | SQL 注入 | N/A | MongoDB 使用 bson.M 参数化查询，无拼接 |
| ✅ | XSS | Admin Web | Ant Design 自动转义，无 dangerouslySetInnerHTML |
| ✅ | CSRF | Admin Web | 双提交 Cookie + X-CSRF-Token |
| ✅ | 密码存储 | Go 后端 | bcrypt 存储 + 渐进迁移 |
| ✅ | TOTP 密钥 | totp_manager.go | AES-256-GCM 加密存储 |
| ✅ | 敏感操作 | sensitive_verify.go | HMAC-SHA256 + nonce + 操作绑定 |
| ✅ | 限流防爆破 | mw/rate_limit.go | IP 级 + 行为级限流 |

---

## 5. 生产就绪评分

### 5.1 模块评分

| 模块 | 功能完整 | 代码质量 | 安全性 | 生产就绪 | 分数 |
|------|---------|---------|--------|---------|------|
| **Flutter 客户端** | 10/10 | 7/10 | 7/10 | 7/10 | **7.8/10** |
| **Go 后端** | 10/10 | 8/10 | 9/10 | 8/10 | **8.8/10** |
| **Admin Web** | 9/10 | 8/10 | 9/10 | 8/10 | **8.5/10** |

### 5.2 评分依据

#### Flutter 客户端 (7.8/10)

**优势：**
- 所有核心 IM 功能完整实现（消息收发、会话、好友、群聊、钱包、在线状态）
- 三端适配（Mobile/Desktop/Web）架构成熟
- SDK 抽象层设计优秀（IMService 接口可无缝切换 SDK/HTTP）
- 设计系统完整（组件库 + 色彩/间距/排版 Token）
- 所有 7 个 Controller 均有 dispose() 实现

**扣分项：**
- **-1.0** — 20+ 处 `catch (_) {}` 静默吞错，影响问题排查
- **-0.5** — `useSDK = true` 硬编码未恢复远端配置（P0）
- **-0.5** — `http://` 明文传输（生产需 TLS）
- **-0.2** — 暗色模式 Theme 存在但部分页面硬引用亮色常量

#### Go 后端 (8.8/10)

**优势：**
- 200+ API 路由全部注册，0 个遗漏处理函数
- 17 个 Manager + 13 个 Handler 全部标记完整
- 安全设计优秀：bcrypt + TOTP(AES-256-GCM) + HMAC-SHA256 + RBAC + RiskGate
- 广播系统 Worker Pool 正确实现优雅关闭（ctx.Done + WaitGroup）
- 规则引擎（字节码 VM + 策略 DSL + 分片）为高级扩展做好准备
- 0 个 TODO/FIXME 注释
- Prometheus 监控 + OpenAPI 文档端点

**扣分项：**
- **-0.5** — 20+ 处 `_ = err` 忽略错误（含 bcrypt 密码迁移写入）
- **-0.5** — MongoDB 无事务，钱包余额调整理论需原子操作
- **-0.2** — 部分常量（QPS、batch size）硬编码

#### Admin Web (8.5/10)

**优势：**
- 39 个页面，35 个完全实现（90%）
- 100+ API 调用覆盖完整
- 0 个 TODO/FIXME，0 个 console.log 残留
- 安全实现优秀：HttpOnly Cookie + CSRF + HMAC-SHA256 敏感操作 + 2FA
- 依赖版本全部最新（React 19, Ant Design 6, TypeScript 5）

**扣分项：**
- **-0.5** — 4 个页面仅有路由无 UI（content-filter, feature-toggle, ratelimit, policy）
- **-0.5** — 群转让/消息撤回等功能后端支持但 UI 未暴露
- **-0.5** — 1 处静默 catch

### 5.3 综合评分

| 维度 | 分数 | 说明 |
|------|------|------|
| 功能完整度 | **9.5/10** | 核心 IM + 管理后台 + 高级功能（广播/规则引擎/RBAC）全部就绪 |
| 代码质量 | **7.5/10** | 架构清晰，但 catch 静默和忽略错误需清理 |
| 安全性 | **8.5/10** | bcrypt/TOTP/HMAC-SHA256/RBAC/限流 全覆盖；TLS 待配置 |
| 可维护性 | **8.0/10** | 模块化清晰，SDK 抽象层可扩展；文档完整 |
| 生产就绪 | **8.0/10** | 需完成：TLS、useSDK 恢复、catch 清理、4 个 Admin 页面 |

### **总分：8.3/10**

---

### 5.4 上线前必做清单 (P0 + P1)

| # | 优先级 | 任务 | 影响范围 |
|---|--------|------|----------|
| 1 | **P0** | 恢复 `useSDK` 为远端配置开关 | Flutter — config_controller.dart:72 |
| 2 | **P1** | 配置 TLS（https:// + wss://） | Flutter — api_client.dart:31-38 |
| 3 | **P1** | 清理 Flutter 20+ 处 `catch (_) {}` | Flutter — 全项目 |
| 4 | **P1** | Go 后端 bcrypt 迁移写入错误必须日志记录 | Go — admin.go:200 |
| 5 | **P1** | Go 后端注册默认好友/群失败必须日志记录 | Go — chat.go:170-173, admin.go:893-896 |
| 6 | P2 | Admin Web 补充 4 个空页面 UI | Admin — content-filter, feature-toggle, ratelimit, policy |
| 7 | P2 | MongoDB 钱包操作增加事务 | Go — wallet_manager.go |
| 8 | P2 | Flutter 暗色模式页面级适配检查 | Flutter — 部分页面直引亮色常量 |

---

*报告结束*
