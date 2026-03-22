# 全栈功能审查报告 v20260319

> 生成时间: 2026-03-19 | 覆盖范围: 用户端(Flutter) + 管理端(React) + 后端(Go)

---

## 目录

1. [全量功能特性清单（总览）](#1-全量功能特性清单)
2. [实现状态分类（核心盘点）](#2-实现状态分类)
3. [路由完整清单](#3-路由完整清单)
4. [前后端对接缺口分析](#4-前后端对接缺口分析)
5. [优先级建议](#5-优先级建议)

---

## 1. 全量功能特性清单

### 1.1 用户端（Flutter App）功能清单

| # | 功能名称 | 业务描述 | 状态 |
|---|---------|---------|------|
| U01 | 登录/注册 | 手机号+密码登录，SMS验证码注册，邀请码 | ✅ 已闭环 |
| U02 | 忘记密码 | 短信验证码重置密码 | ✅ 已闭环 |
| U03 | 会话列表 | 排序、未读计数、置顶、免打扰、删除 | ✅ 已闭环 |
| U04 | 单聊消息 | 文本/图片/视频/文件/语音/引用/表情回应 | ✅ 已闭环 |
| U05 | 群聊消息 | 同上 + 群成员角色、内容过滤前校验 | ✅ 已闭环 |
| U06 | 消息编辑 | 2分钟内编辑已发消息 | ✅ 已闭环 |
| U07 | 消息撤回 | 2分钟内撤回 | ✅ 已闭环 |
| U08 | 删除消息 | 仅自己可见删除 / 群管删除 | ✅ 已闭环 |
| U09 | 合并转发 | 多选消息合并转发 | ✅ 已闭环 |
| U10 | 消息置顶(群) | 群内Pin消息 | ✅ 已闭环 |
| U11 | 收藏消息 | 星标消息(本地 SharedPreferences) | ✅ 已闭环 |
| U12 | 联系人列表 | 好友列表 + 在线状态 | ✅ 已闭环 |
| U13 | 好友请求 | 发送/接受/拒绝好友申请 | ✅ 已闭环 |
| U14 | 添加好友 | 搜索用户ID/手机号并发起申请 | ✅ 已闭环 |
| U15 | 创建群组 | 选择好友创建群组 | ✅ 已闭环 |
| U16 | 群组管理 | 修改群名/公告/头像、踢人、转让、解散、禁言 | ✅ 已闭环 |
| U17 | 群成员管理 | 查看成员、设置角色、禁言单人 | ✅ 已闭环 |
| U18 | 群人数上限 | 群主设置最大成员数 | ✅ 已闭环 |
| U19 | 个人资料 | 查看/编辑昵称 | ✅ 已闭环 |
| U20 | 修改密码 | 已登录状态修改密码 | ✅ 已闭环 |
| U21 | 用户详情页 | 查看他人资料 + 在线状态 + IP(管理员可见) | ✅ 已闭环 |
| U22 | 隐私设置 | 最后在线时间可见性(所有人/联系人/无) | ✅ 已闭环 |
| U23 | 钱包系统 | 余额查看、银行卡管理、提现(后端拒绝) | ✅ 已闭环 |
| U24 | 文件上传 | 3步 im-server 对象存储上传 | ✅ 已闭环 |
| U25 | 首页动态内容 | Banner轮播+公告+新闻(client_config API) | ✅ 已闭环 |
| U26 | 白名单校验 | 登录前预检白名单状态 | ✅ 已闭环 |
| U27 | 群官方标识 | 查询群是否为官方群 | ✅ 已闭环 |
| U28 | 接待员系统 | 生成邀请码/查看客户/查看接待员 | ✅ 已闭环 |
| U29 | 官方账号标识 | V标展示 | ✅ 已闭环 |
| U30 | WebSocket状态 | 实时在线状态推送 | ✅ 已闭环 |
| U31 | 设置-消息提醒 | 声音/震动/预览 三开关(SharedPreferences) | ✅ 已闭环 |
| U32 | 清除缓存 | 平台条件实现(native实际清除/web stub) | ✅ 已闭环 |
| U33 | 已登录设备 | 查看当前登录设备 | ⛔ 占位符 |
| U34 | 语言切换 | 多语言切换 | ⛔ 占位符 |
| U35 | 主题切换 | 暗色/亮色主题 | ⛔ 占位符(Desktop/Web) |
| U36 | 通知设置(Desktop/Web) | 桌面/Web端通知设置 | ⛔ 占位符 |
| U37 | 位置分享 | 发送地理位置 | ⛔ 占位符 |
| U38 | 扫码 | 二维码扫描功能 | ⛔ 占位符 |
| U39 | 首页-公告 | 公告详情页 | ⛔ 占位符(仅首页卡片) |
| U40 | 首页-活动 | 活动列表/详情 | ⛔ 占位符 |
| U41 | 首页-帮扶 | 帮扶功能 | ⛔ 占位符 |
| U42 | 首页-商城 | 商城入口 | ⛔ 占位符 |
| U43 | 首页-报表 | 报表功能 | ⛔ 占位符 |
| U44 | 首页-任务 | 任务系统 | ⛔ 占位符 |
| U45 | 用户服务协议 | 协议页面 | ⛔ 占位符 |
| U46 | 隐私政策 | 政策页面 | ⛔ 占位符 |
| U47 | 检查更新 | 查询最新版本并提示更新 | ⛔ 存根(总是显示"最新") |
| U48 | 小程序商店 | 发现/使用小程序 | ⛔ 无UI |

### 1.2 管理端（Admin Web）功能清单

| # | 功能名称 | 业务描述 | 状态 |
|---|---------|---------|------|
| A01 | 管理员登录 | MD5密码 + 2FA/TOTP | ✅ 已闭环 |
| A02 | 数据概览 | 新增用户/登录用户/群组统计(7日图表) | ✅ 已闭环 |
| A03 | 用户列表 | 搜索、创建、编辑、删除、封禁、角色设置、IP历史 | ✅ 已闭环 |
| A04 | 在线用户 | 实时在线监控 | ✅ 已闭环 |
| A05 | 封禁管理 | 查看/解除封禁 | ✅ 已闭环 |
| A06 | 批量用户 | JSON/XLSX导入、模板下载、批量创建 | ✅ 已闭环 |
| A07 | 群组管理 | 搜索、解散、禁言、踢人、转让 | ✅ 已闭环 |
| A08 | 消息搜索 | 按发送者/接收者/类型/时间搜索 | ✅ 已闭环 |
| A09 | 消息发送 | 管理员强制发送消息 | ✅ 已闭环 |
| A10 | 管理员账号 | CRUD管理员、超级管理员权限 | ✅ 已闭环 |
| A11 | IP黑名单 | 禁止IP登录/注册 | ✅ 已闭环 |
| A12 | 用户IP限制 | 限制用户仅限特定IP登录 | ✅ 已闭环 |
| A13 | 用户管理员 | App层用户管理员(appRole=1) + 推荐关系 | ✅ 已闭环 |
| A14 | 钱包管理 | 查询余额、调整余额(敏感操作)、交易记录 | ✅ 已闭环 |
| A15 | 配置中心 | etcd配置查看/编辑/重置、重启服务 | ✅ 已闭环 |
| A16 | 白名单管理 | 手机号/邮箱白名单CRUD | ✅ 已闭环 |
| A17 | 接待员管理 | 邀请码管理、客户绑定关系 | ✅ 已闭环 |
| A18 | 安全审计日志 | 管理员操作+敏感操作日志 | ✅ 已闭环 |
| A19 | 邀请码管理 | 生成/搜索/删除邀请码 | ✅ 已闭环 |
| A20 | 默认好友 | 新用户注册自动添加好友 | ✅ 已闭环 |
| A21 | 默认群组 | 新用户注册自动加群 | ✅ 已闭环 |
| A22 | 客户端配置 | Feature flag 键值对管理 | ✅ 已闭环 |
| A23 | 注册开关 | 全局开放/关闭注册 | ✅ 已闭环 |
| A24 | 客户端日志 | 搜索/删除客户端debug日志 | ✅ 已闭环 |
| A25 | 强制下线 | 踢用户下线(按平台) | ✅ 已闭环 |
| A26 | 应用版本 | 发布/编辑/删除App版本 | ✅ 已闭环 |
| A27 | 2FA管理 | 设置/启用/禁用TOTP双因素认证 | ✅ 已闭环 |
| A28 | 风险评分 | 查询IP/管理员风险分数 | ✅ 已闭环 |
| A29 | WebSocket认证 | 管理端WS实时推送票据 | ✅ 已闭环 |
| A30 | 官方账号(V标) | 设置用户为官方账号 | ✅ 已闭环 |
| A31 | Banner管理 | 首页Banner CRUD | ⛔ 隐藏(服务未部署) |
| A32 | 小程序管理 | 小程序CRUD | ⛔ 无UI页面 |
| A33 | 官方群管理 | 设置/取消群官方标识 | ⛔ 无UI页面 |
| A34 | 内容过滤规则 | 敏感词/正则过滤规则管理 | ⛔ 无UI页面 |
| A35 | 功能开关 | Feature Toggle 管理UI | ⛔ 无UI页面 |
| A36 | 群限制管理 | 群级别限制策略 | ⛔ 无UI页面 |
| A37 | 策略引擎管理 | 规则评估/热加载/回滚 | ⛔ 无UI页面 |
| A38 | 限流管理 | 速率限制配置与监控 | ⛔ 无UI页面 |
| A39 | 分片管理 | 多租户分片策略 | ⛔ 无UI页面 |
| A40 | 消息管理(Admin) | 管理端消息编辑/撤回/删群消息/Pin | ⛔ 无UI页面 |

---

## 2. 实现状态分类

### 2.1 功能已存在但未实现（占位符/存根）

| 功能 | 所属端 | 当前状态 | 具体表现 | 优先级 |
|------|--------|---------|---------|--------|
| 已登录设备 | 用户端 | 前端占位 | 点击显示"功能开发中，敬请期待" | 中 |
| 语言切换 | 用户端 | 前端占位 | 点击显示"功能开发中，敬请期待" | 中 |
| 主题切换 | 用户端(Desktop/Web) | 前端占位 | 点击显示"即将上线" | 低 |
| 通知设置 | 用户端(Desktop/Web) | 前端占位 | 点击显示"即将上线" | 低 |
| 位置分享 | 用户端 | 前端占位 | 点击显示"位置分享功能即将上线" | 低 |
| 扫码 | 用户端 | 前端占位 | 点击显示"扫码功能即将上线" | 低 |
| 检查更新 | 用户端 | 存根 | 总是显示"当前已是最新版本" | 中 |
| 首页网格(公告/活动/帮扶/商城/报表/任务/更多) | 用户端 | 前端占位 | 共7项点击显示"功能开发中，敬请期待" | 低 |
| 用户服务协议 | 用户端 | 前端占位 | 显示"暂未上线，敬请期待" | 高 |
| 隐私政策 | 用户端 | 前端占位 | 显示"暂未上线，敬请期待" | 高 |
| Banner管理 | 管理端 | 路由隐藏 | hideInMenu:true, 服务端口10011未部署 | 低 |

### 2.2 后端API已注册但无前端UI

| 后端路由组 | 端口 | 路由数 | 描述 | 优先级 |
|-----------|------|--------|------|--------|
| `/applet/*` | 10009 | 4 | 小程序CRUD (add/del/update/search) | 低 |
| `/official_group/*` | 10009 | 2 | 官方群设置(set/status) — 仅用户端有查询 | 中 |
| `/chat_msg/*` (admin端) | 10009 | 7 | 管理端消息编辑/撤回/删群消息/合并转发/内容检查 | 中 |
| `/group_msg/*` (admin端) | 10009 | 4 | 管理端Pin消息管理 | 低 |
| `/feature_toggle/*` | 10009 | 3 | 功能开关管理(set/list/check) | 中 |
| `/group_restriction/*` | 10009 | 4 | 群限制策略(set/get/delete/check) | 低 |
| `/content_filter/*` | 10009 | 3 | 内容过滤规则管理(upsert/delete/list) | 高 |
| `/rule/*` | 10009 | 2 | 规则版本/快照查询 | 低 |
| `/policy/*` | 10009 | 6 | 策略引擎(eval/rules/reload/validate/rollback/history) | 低 |
| `/shard/*` | 10009 | 4 | 分片管理(eval/reload/rollback/list) | 低 |
| `/ratelimit/*` | 10009 | 3 | 限流配置与统计 | 低 |
| `/dist_ratelimit/*` | 10009 | 3 | 分布式限流 | 低 |
| `/applet/find` | 10008 | 1 | 用户端小程序发现 | 低 |
| `/jssdk/*` | 10002 | 1 | JS SDK专用 | 低 |

### 2.3 前后端对接已完成但流程有缺口

| 功能 | 断点描述 | 影响 | 优先级 |
|------|---------|------|--------|
| 提现功能 | 后端 `wallet_handler.go` 永远返回拒绝消息 | 用户可操作但永不成功 | 中 |
| 检查更新 | Flutter端 `about_page.dart` 硬编码"已是最新"，后端已有 `/application/latest_version` | 永远不会触发更新提示 | 中 |
| 官方群管理 | 管理端无设置UI，用户端只能查询不能设置 | 无法通过UI操作设管群官方 | 中 |
| Web端钱包 | Web端 `web_layout.dart` 无钱包Tab | Web用户无法使用钱包 | 低 |
| Web端缓存清除 | stub实现返回0 | Web用户"清除缓存"无实际效果 | 低(合理) |

### 2.4 前后端路由/参数不一致

经全面比对，**当前无前后端参数格式不一致的问题**。上一轮修复已解决所有已知的不一致点：
- ✅ MediaApi 已对齐 im-server 3步上传协议
- ✅ GroupApi.setMaxMemberCount 已切换至 im-server `/group/set_group_info`
- ✅ 首页数据已从硬编码切换至 `client_config` API
- ✅ 设置页开关已接入 SharedPreferences 持久化
- ✅ 星标消息已接入 SharedPreferences 持久化

---

## 3. 路由完整清单

### 3.1 用户端前端路由（Flutter）

| 路由 | 组件 | 权限 | 功能 |
|------|------|------|------|
| `/splash` | `SplashPage` | 无(公开) | 启动页+会话恢复 |
| `/login` | `AuthPage` | 无(公开) | 登录/注册Tab切换 |
| `/home` | 平台自适应Layout | 需登录 | 主界面(Desktop:3列/Mobile:底部Tab/Web:响应式) |
| `/forgot-password` | `ForgotPasswordPage` | 无(公开) | 短信重置密码 |
| `/about` | `MobileAboutPage` | 需登录 | 关于页面 |
| `/settings` | `MobileSettingsPage` | 需登录 | 设置页面 |
| `/privacy-settings` | `PrivacySettingsPage` | 需登录 | 最后在线隐私设置 |
| `/chat` | `MobileChatPage` | 需登录 | 聊天页(参数:conversationID) |

### 3.2 管理端前端路由（Admin Web）

| 路由 | 组件 | 是否隐藏 | 功能 |
|------|------|---------|------|
| `/user/login` | `./user/login` | 独立布局 | 管理员登录 |
| `/dashboard` | `./dashboard` | ❌ | 数据概览仪表盘 |
| `/user-manage/list` | `./user-manage/list` | ❌ | 用户列表管理 |
| `/user-manage/online` | `./user-manage/online` | ❌ | 在线用户监控 |
| `/user-manage/block` | `./user-manage/block` | ❌ | 封禁列表管理 |
| `/user-manage/batch` | `./user-manage/batch` | ❌ | 批量创建用户 |
| `/group-manage` | `./group-manage` | ❌ | 群组管理 |
| `/msg-manage/search` | `./msg-manage/search` | ❌ | 消息搜索审计 |
| `/msg-manage/send` | `./msg-manage/send` | ❌ | 管理员发消息 |
| `/system/admin` | `./system/admin` | ❌ | 管理员账号管理 |
| `/system/ip-forbidden` | `./system/ip-forbidden` | ❌ | IP黑名单 |
| `/system/ip-user-limit` | `./system/ip-user-limit` | ❌ | 用户IP限制 |
| `/system/user-admin` | `./system/user-admin` | ❌ | 用户管理员(推荐系统) |
| `/system/wallet` | `./system/wallet` | ❌ | 钱包管理 |
| `/system/config-center` | `./system/config-center` | ❌ | 配置中心(etcd) |
| `/security/whitelist` | `./security/whitelist` | ❌ | 注册白名单 |
| `/security/receptionist` | `./security/receptionist` | ❌ | 接待员管理 |
| `/security/logs` | `./security/logs` | ❌ | 安全审计日志 |
| `/banner-manage` | `./banner-manage` | ✅ 隐藏 | Banner管理(未部署) |
| `/register-setting/invitation` | `./register-setting/invitation` | ❌ | 邀请码管理 |
| `/register-setting/default-friend` | `./register-setting/default-friend` | ❌ | 默认好友 |
| `/register-setting/default-group` | `./register-setting/default-group` | ❌ | 默认群组 |

### 3.3 后端路由 — Admin-API（端口 10009）

#### 账号管理 `/account`

| 方法 | 路径 | 中间件 | 处理函数 | 功能 |
|------|------|--------|---------|------|
| POST | `/account/login` | AuthRateLimitByIP | AdminLogin | 管理员登录 |
| POST | `/account/update` | CheckAdmin | AdminUpdateInfo | 更新管理员信息 |
| POST | `/account/info` | CheckAdmin | AdminInfo | 获取管理员信息 |
| POST | `/account/parse_token` | CheckAdmin | ParseToken | 解析Token |
| POST | `/account/change_password` | CheckAdmin, SensitiveVerify, Audit | ChangeAdminPassword | 修改密码(2FA) |
| POST | `/account/add_admin` | CheckAdmin, CheckSuperAdmin, Audit | AddAdminAccount | 添加管理员 |
| POST | `/account/del_admin` | CheckAdmin, CheckSuperAdmin, SensitiveVerify, Audit | DelAdminAccount | 删除管理员 |
| POST | `/account/search` | CheckAdmin | SearchAdminAccount | 搜索管理员 |
| POST | `/account/token/refresh` | — | RefreshAdminToken | 刷新Token |
| POST | `/account/confirm/challenge` | CheckAdmin | GetConfirmChallenge | 敏感操作挑战 |
| POST | `/account/add_user` | CheckAdmin, Audit | AddUserAccount | 添加用户 |
| POST | `/account/2fa/setup` | CheckAdmin | Setup2FA | 设置TOTP |
| POST | `/account/2fa/verify` | CheckAdmin | Verify2FA | 验证TOTP |
| POST | `/account/2fa/status` | CheckAdmin | Get2FAStatus | 2FA状态 |
| POST | `/account/2fa/disable` | CheckAdmin, SensitiveVerify | Disable2FA | 禁用2FA |
| POST | `/account/login/2fa` | — | Login2FAComplete | 2FA登录完成 |
| POST | `/account/permissions` | CheckAdmin | GetMyPermissions | 查询权限 |
| POST | `/account/admin_permissions/set` | CheckAdmin, CheckSuperAdmin, Audit | SetAdminPermissions | 设置权限 |
| POST | `/account/admin_permissions/get` | CheckAdmin, CheckSuperAdmin, Audit | GetAdminPermissions | 获取权限 |

#### 用户管理 `/user`

| 方法 | 路径 | 中间件 | 处理函数 | 功能 |
|------|------|--------|---------|------|
| POST | `/user/batch_register` | CheckAdmin | BatchRegisterUsers | 批量注册 |
| POST | `/user/import/json` | CheckAdmin | ImportUserByJson | JSON导入 |
| POST | `/user/import/xlsx` | CheckAdmin | ImportUserByXlsx | Excel导入 |
| GET  | `/user/import/xlsx` | CheckAdmin | BatchImportTemplate | 下载模板 |
| POST | `/user/allow_register/get` | CheckAdmin | GetAllowRegister | 获取注册开关 |
| POST | `/user/allow_register/set` | CheckAdmin | SetAllowRegister | 设置注册开关 |
| POST | `/user/password/reset` | CheckAdmin, SensitiveVerify, Audit | ResetUserPassword | 重置密码 |
| POST | `/user/set_app_role` | CheckAdmin, SensitiveVerify, Audit | SetAppRole | 设置角色 |
| POST | `/user/set_official` | CheckAdmin, Audit | SetOfficialStatus | 设置官方标识 |
| POST | `/user/ip_logs` | CheckAdmin, Audit | GetUserIPLogs | IP日志 |
| POST | `/user/search` | CheckAdmin, Audit | SearchUserInfo | 搜索用户 |
| POST | `/user/batch_create` | CheckAdmin, Audit | BatchCreate | 批量创建 |
| POST | `/user/delete_users` | CheckAdmin, SensitiveVerify, Audit | DeleteUsers | 删除用户 |

#### 默认好友/群组

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/default/user/add` | CheckAdmin, Audit | 添加默认好友 |
| POST | `/default/user/del` | CheckAdmin, Audit | 删除默认好友 |
| POST | `/default/user/find` | CheckAdmin, Audit | 查找默认好友 |
| POST | `/default/user/search` | CheckAdmin, Audit | 搜索默认好友 |
| POST | `/default/group/add` | CheckAdmin, Audit | 添加默认群组 |
| POST | `/default/group/del` | CheckAdmin, Audit | 删除默认群组 |
| POST | `/default/group/find` | CheckAdmin, Audit | 查找默认群组 |
| POST | `/default/group/search` | CheckAdmin, Audit | 搜索默认群组 |

#### 邀请码 `/invitation_code`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/invitation_code/add` | CheckAdmin, Audit | 添加邀请码 |
| POST | `/invitation_code/gen` | CheckAdmin, Audit | 生成邀请码 |
| POST | `/invitation_code/del` | CheckAdmin, Audit | 删除邀请码 |
| POST | `/invitation_code/search` | CheckAdmin, Audit | 搜索邀请码 |

#### IP管理

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/forbidden/ip/add` | CheckAdmin, Audit | 添加IP黑名单 |
| POST | `/forbidden/ip/del` | CheckAdmin, Audit | 删除IP黑名单 |
| POST | `/forbidden/ip/search` | CheckAdmin, Audit | 搜索IP黑名单 |
| POST | `/forbidden/user/add` | CheckAdmin, Audit | 添加用户IP限制 |
| POST | `/forbidden/user/del` | CheckAdmin, Audit | 删除用户IP限制 |
| POST | `/forbidden/user/search` | CheckAdmin, Audit | 搜索用户IP限制 |

#### 小程序 `/applet` ⚠️ 无前端

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/applet/add` | CheckAdmin, Audit | 添加小程序 |
| POST | `/applet/del` | CheckAdmin, Audit | 删除小程序 |
| POST | `/applet/update` | CheckAdmin, Audit | 更新小程序 |
| POST | `/applet/search` | CheckAdmin, Audit | 搜索小程序 |

#### 封禁 `/block`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/block/add` | CheckAdmin, RiskGate, CheckPermission("block:write"), Audit | 封禁用户 |
| POST | `/block/del` | CheckAdmin, RiskGate, CheckPermission("block:write"), Audit | 解封用户 |
| POST | `/block/search` | CheckAdmin, RiskGate, CheckPermission("block:write"), Audit | 搜索封禁 |

#### 白名单 `/whitelist`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/whitelist/add` | CheckAdmin, CheckSuperAdmin, Audit | 添加白名单 |
| POST | `/whitelist/del` | CheckAdmin, CheckSuperAdmin, Audit | 删除白名单 |
| POST | `/whitelist/update` | CheckAdmin, CheckSuperAdmin, Audit | 更新白名单 |
| POST | `/whitelist/search` | CheckAdmin, CheckSuperAdmin, Audit | 搜索白名单 |
| POST | `/whitelist/check` | — | 白名单检查(公开) |

#### 接待员 `/receptionist`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/receptionist/invite_codes/search` | CheckAdmin | 搜索邀请码 |
| POST | `/receptionist/invite_codes/update_status` | CheckAdmin | 更新状态 |
| POST | `/receptionist/invite_codes/delete` | CheckAdmin | 删除邀请码 |
| POST | `/receptionist/bindings/get` | CheckAdmin | 获取绑定 |
| POST | `/receptionist/bindings/list` | CheckAdmin | 列表绑定 |
| POST | `/receptionist/bindings/delete` | CheckAdmin | 删除绑定 |

#### 用户管理员 `/user_admin`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/user_admin/add` | CheckAdmin | 添加管理员 |
| POST | `/user_admin/remove` | CheckAdmin | 移除管理员 |
| POST | `/user_admin/search` | CheckAdmin | 搜索管理员 |
| POST | `/user_admin/referral/users` | CheckAdmin | 推荐用户 |

#### 钱包 `/wallet`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/wallet/user` | CheckAdmin, RiskGate, CheckPermission, Audit | 查询钱包 |
| POST | `/wallet/adjust` | CheckAdmin, RiskGate, CheckPermission, SensitiveVerify, Audit | 调整余额 |
| POST | `/wallet/transactions` | CheckAdmin, RiskGate, CheckPermission, Audit | 交易记录 |

#### 安全审计 `/security_log` + `/security`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/security_log/search` | CheckAdmin | 搜索审计日志 |
| POST | `/security/risk/score` | CheckAdmin | 风险评分 |

#### WebSocket `/ws`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/ws/auth` | CheckAdmin | 签发WS票据 |

#### 官方群 `/official_group` ⚠️ 无管理端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/official_group/set` | CheckAdmin | 设置官方群 |
| POST | `/official_group/status` | CheckAdmin | 查询状态 |

#### 消息管理 `/chat_msg` ⚠️ 无管理端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/chat_msg/edit` | — | 编辑消息 |
| POST | `/chat_msg/edits` | — | 编辑历史 |
| POST | `/chat_msg/recall` | — | 撤回消息 |
| POST | `/chat_msg/delete_group` | — | 删除群消息 |
| POST | `/chat_msg/delete_self` | — | 自己删除 |
| POST | `/chat_msg/merge_forward` | — | 合并转发 |
| POST | `/chat_msg/check_content` | — | 内容检查 |

#### Pin消息 `/group_msg` ⚠️ 无管理端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/group_msg/pin` | — | Pin消息 |
| POST | `/group_msg/unpin` | — | 取消Pin |
| POST | `/group_msg/pin/list` | — | Pin列表 |
| POST | `/group_msg/pin/check` | — | 检查Pin |

#### 群配置 `/group_config`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/group_config/set_max_member` | CheckAdmin | 设置群上限 |
| POST | `/group_config/member_role` | — | 查询角色 |

#### 功能开关 `/feature_toggle` ⚠️ 无前端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/feature_toggle/set` | CheckAdmin | 设置开关 |
| POST | `/feature_toggle/list` | CheckAdmin | 列表开关 |
| POST | `/feature_toggle/check` | CheckAdmin | 检查开关 |

#### 群限制 `/group_restriction` ⚠️ 无前端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/group_restriction/set` | CheckAdmin | 设置限制 |
| POST | `/group_restriction/get` | CheckAdmin | 获取限制 |
| POST | `/group_restriction/delete` | CheckAdmin | 删除限制 |
| POST | `/group_restriction/check` | CheckAdmin | 检查限制 |

#### 内容过滤 `/content_filter` ⚠️ 无前端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/content_filter/upsert` | CheckAdmin | 创建/更新规则 |
| POST | `/content_filter/delete` | CheckAdmin | 删除规则 |
| POST | `/content_filter/list` | CheckAdmin | 列表规则 |

#### 规则引擎 `/rule` `/policy` ⚠️ 无前端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/rule/version` | CheckAdmin | 规则版本 |
| POST | `/rule/snapshots` | CheckAdmin | 变更快照 |
| POST | `/policy/eval` | CheckAdmin | 策略评估 |
| POST | `/policy/rules` | CheckAdmin | 查看规则 |
| POST | `/policy/reload` | CheckAdmin | 热加载 |
| POST | `/policy/validate` | CheckAdmin | 语法验证 |
| POST | `/policy/rollback` | CheckAdmin | 回滚 |
| POST | `/policy/history` | CheckAdmin | 版本历史 |

#### 限流 `/ratelimit` `/dist_ratelimit` ⚠️ 无前端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/ratelimit/config` | CheckAdmin | 限流配置 |
| POST | `/ratelimit/stats` | CheckAdmin | 限流统计 |
| POST | `/ratelimit/check` | CheckAdmin | 限流检查 |
| POST | `/dist_ratelimit/config` | CheckAdmin | 分布式限流配置 |
| POST | `/dist_ratelimit/stats` | CheckAdmin | 分布式限流统计 |
| POST | `/dist_ratelimit/check` | CheckAdmin | 分布式限流检查 |

#### 分片 `/shard` ⚠️ 无前端UI

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/shard/eval` | CheckAdmin | 分片评估 |
| POST | `/shard/reload` | CheckAdmin | 分片重载 |
| POST | `/shard/rollback` | CheckAdmin | 分片回滚 |
| POST | `/shard/list` | CheckAdmin | 分片列表 |

#### 客户端配置 `/client_config`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/client_config/get` | CheckAdmin | 获取配置 |
| POST | `/client_config/set` | CheckAdmin | 设置配置 |
| POST | `/client_config/del` | CheckAdmin | 删除配置 |

#### 统计 `/statistic`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/statistic/new_user_count` | CheckAdmin | 新增用户数 |
| POST | `/statistic/login_user_count` | CheckAdmin | 登录用户数 |

#### 应用版本 `/application`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/application/add_version` | CheckAdmin | 添加版本 |
| POST | `/application/update_version` | CheckAdmin | 更新版本 |
| POST | `/application/delete_version` | CheckAdmin | 删除版本 |
| POST | `/application/latest_version` | — | 最新版本(公开) |
| POST | `/application/page_versions` | — | 版本分页(公开) |

#### 配置 `/config`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/config/get_config_list` | CheckAdmin | 配置列表 |
| POST | `/config/get_config` | CheckAdmin | 获取配置 |
| POST | `/config/set_config` | CheckAdmin | 设置配置 |
| POST | `/config/set_configs` | CheckAdmin | 批量设置 |
| POST | `/config/reset_config` | CheckAdmin | 重置配置 |
| POST | `/config/get_enable_config_manager` | CheckAdmin | 获取开关 |
| POST | `/config/set_enable_config_manager` | CheckAdmin | 设置开关 |

#### 重启 `/restart`

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/restart` | CheckAdmin, CheckSuperAdmin, Audit | 重启服务 |

### 3.4 后端路由 — Chat-API（端口 10008）

| 方法 | 路径 | 中间件 | 功能 |
|------|------|--------|------|
| POST | `/account/code/send` | AuthRateLimitByIP | 发送验证码 |
| POST | `/account/code/verify` | — | 验证码校验 |
| POST | `/account/register` | AuthRateLimitByIP, CheckAdminOrNil | 用户注册 |
| POST | `/account/login` | AuthRateLimitByIP | 用户登录 |
| POST | `/account/password/reset` | AuthRateLimitByIP | 重置密码 |
| POST | `/account/password/change` | CheckToken | 修改密码 |
| POST | `/user/update` | CheckToken | 更新资料 |
| POST | `/user/find/public` | CheckToken | 公开资料 |
| POST | `/user/find/full` | CheckToken | 完整资料 |
| POST | `/user/search/full` | CheckToken | 搜索(完整) |
| POST | `/user/search/public` | CheckToken | 搜索(公开) |
| POST | `/user/rtc/get_token` | CheckToken | 视频会议Token |
| POST | `/user/ip_info` | CheckToken | 用户IP信息 |
| POST | `/user/search` | CheckToken | 搜索用户 |
| POST | `/user/status` | CheckToken | 在线状态 |
| POST | `/user/status/batch` | CheckToken | 批量状态 |
| POST | `/user/privacy/get` | CheckToken | 隐私设置 |
| POST | `/user/privacy/set` | CheckToken | 设置隐私 |
| POST | `/friend/search` | CheckToken | 搜索好友 |
| POST | `/friend/can_add` | CheckToken | 可否加友 |
| POST | `/friend/can_view_profile` | CheckToken | 可否查看 |
| POST | `/applet/find` | CheckToken | 查找小程序 |
| POST | `/client_config/get` | — | 客户端配置(公开) |
| POST | `/application/latest_version` | — | 最新版本(公开) |
| POST | `/application/page_versions` | — | 版本分页(公开) |
| POST | `/callback/open_im` | — | OpenIM回调 |
| POST | `/receptionist/my_code` | CheckToken | 生成邀请码 |
| POST | `/customer/my_receptionist` | CheckToken | 我的接待员 |
| POST | `/receptionist/my_customers` | CheckToken | 我的客户 |
| POST | `/wallet/info` | CheckToken | 钱包信息 |
| POST | `/wallet/cards` | CheckToken | 银行卡列表 |
| POST | `/wallet/card/add` | CheckToken | 添加银行卡 |
| POST | `/wallet/card/remove` | CheckToken | 删除银行卡 |
| POST | `/wallet/withdraw` | CheckToken | 提现(总拒绝) |
| POST | `/group/official/status` | CheckToken | 官方群状态 |
| POST | `/chat_msg/edit` | CheckToken | 编辑消息 |
| POST | `/chat_msg/edits` | CheckToken | 编辑历史 |
| POST | `/chat_msg/recall` | CheckToken | 撤回消息 |
| POST | `/chat_msg/delete_group` | CheckToken | 删群消息 |
| POST | `/chat_msg/delete_self` | CheckToken | 自删消息 |
| POST | `/chat_msg/merge_forward` | CheckToken | 合并转发 |
| POST | `/chat_msg/check_content` | CheckToken | 内容检查 |
| POST | `/group_msg/pin` | CheckToken | Pin消息 |
| POST | `/group_msg/unpin` | CheckToken | 取消Pin |
| POST | `/group_msg/pin/list` | CheckToken | Pin列表 |
| POST | `/group_config/member_role` | CheckToken | 成员角色 |
| GET  | `/ws/presence` | 内部认证 | 在线状态WS |

### 3.5 后端路由 — IM-Server（端口 10002）— 主要路由组

| 路由组 | 端点数 | 关键端点 |
|--------|--------|---------|
| `/user/*` | 26+ | get_users_info, update_user_info, get_users_online_status 等 |
| `/friend/*` | 20+ | add_friend, get_friend_list, add_friend_response 等 |
| `/group/*` | 30+ | create_group, set_group_info, get_group_member_list 等 |
| `/auth/*` | 4 | get_admin_token, get_user_token, parse_token, force_logout |
| `/msg/*` | 16+ | send_msg, pull_msg_by_seq, revoke_msg, search_msg 等 |
| `/conversation/*` | 12+ | get_sorted_conversation_list, set_conversations 等 |
| `/third/*` + `/object/*` | 10+ | 文件上传(form_data流程), FCM推送, 日志 |
| `/wallet/*` | 15+ | 完整钱包系统(用户+管理员) |
| `/receptionist/*` | 10+ | 邀请码, 绑定, 问候语 |
| `/jssdk/*` | 1 | JS SDK专用 |

---

## 4. 前后端对接缺口分析

### 4.1 后端有API → 前端无UI（需开发管理端页面）

| 后端路由 | 功能 | 建议页面路径 | 优先级 |
|---------|------|------------|--------|
| `/content_filter/*` | 内容过滤规则CRUD | `/system/content-filter` | **高** |
| `/official_group/*` | 官方群设置管理 | `/group-manage` 中添加Tab | **中** |
| `/feature_toggle/*` | 功能开关管理 | `/system/feature-toggle` | **中** |
| `/chat_msg/*`(admin) | 管理端消息操作 | `/msg-manage` 中扩展 | **中** |
| `/group_msg/*`(admin) | 管理端Pin消息 | `/group-manage` 中添加Tab | **低** |
| `/group_restriction/*` | 群限制策略 | `/group-manage` 中添加Tab | **低** |
| `/applet/*` | 小程序管理 | `/system/applet` | **低** |
| `/rule/*` `/policy/*` | 策略引擎/规则版本 | `/system/policy-engine` | **低** |
| `/ratelimit/*` `/dist_ratelimit/*` | 限流监控 | `/system/rate-limit` | **低** |
| `/shard/*` | 分片管理 | `/system/shard` | **低** |

### 4.2 前端有UI → 未接入后端API

| 功能 | 所属端 | 当前状态 | 缺少的后端 | 优先级 |
|------|--------|---------|-----------|--------|
| 已登录设备 | 用户端 | 占位符 | 无对应后端API | **中** |
| 语言切换 | 用户端 | 占位符 | 纯前端(i18n)，无需后端 | **中** |
| 检查更新 | 用户端 | 硬编码 | 后端已有 `/application/latest_version`，需接入 | **中** |
| 位置分享 | 用户端 | 占位符 | 需地图SDK + 后端消息类型扩展 | **低** |
| 扫码 | 用户端 | 占位符 | 需相机权限 + 解析逻辑 | **低** |
| 首页网格菜单 (7项) | 用户端 | 全占位符 | 需完整业务系统 | **低** |
| 用户服务协议 | 用户端 | 占位符 | 需静态页面或CMS | **高** |
| 隐私政策 | 用户端 | 占位符 | 需静态页面或CMS | **高** |
| Banner管理 | 管理端 | 路由隐藏 | 需 :10011 Banner服务 | **低** |

### 4.3 完整性已确认的对接

| 功能 | 用户端API | 后端路由 | 管理端API | 状态 |
|------|----------|---------|----------|------|
| 登录 | `ChatApi /account/login` | ✅ chat-api | `adminLogin` → `:10009/account/login` | ✅ 双端闭环 |
| 注册 | `ChatApi /account/register` | ✅ chat-api | `addSingleUser` → `:10009/account/add_user` | ✅ 双端闭环 |
| 会话列表 | `ImApi /conversation/*` | ✅ im-server | — | ✅ 用户端闭环 |
| 消息收发 | `ImApi /msg/send_msg` | ✅ im-server | `sendMessage` → `:10002/msg/send_msg` | ✅ 双端闭环 |
| 好友管理 | `ImApi /friend/*` | ✅ im-server | — | ✅ 用户端闭环 |
| 群组管理 | `ImApi /group/*` | ✅ im-server | `getGroups` → `:10002/group/get_groups` | ✅ 双端闭环 |
| 文件上传 | `ImApi /object/*` (3步) | ✅ im-server | — | ✅ 用户端闭环 |
| 封禁管理 | — | ✅ admin-api | `blockUser/unblockUser/searchBlockUsers` | ✅ 管理端闭环 |
| IP黑名单 | — | ✅ admin-api | `searchForbiddenIPs/*` | ✅ 管理端闭环 |
| 白名单 | `AdminApi /whitelist/check` | ✅ admin-api | `searchWhitelist/*` | ✅ 双端闭环 |
| 钱包 | `ChatApi /wallet/*` | ✅ chat-api | `getUserWallet/adjustWalletBalance` | ✅ 双端闭环 |
| 接待员 | `ChatApi /receptionist/*` | ✅ chat-api | `searchReceptionistInviteCodes/*` | ✅ 双端闭环 |
| 在线状态 | `ChatApi /user/status/*` | ✅ chat-api | `getUsersOnlineStatus` → `:10002` | ✅ 双端闭环 |
| 隐私设置 | `ChatApi /user/privacy/*` | ✅ chat-api | — | ✅ 用户端闭环 |
| 消息编辑 | `ChatApi /chat_msg/edit` | ✅ chat-api | — | ✅ 用户端闭环 |
| Pin消息 | `ChatApi /group_msg/pin*` | ✅ chat-api | — | ✅ 用户端闭环 |
| 官方群查询 | `ChatApi /group/official/status` | ✅ chat-api | — | ✅ 用户端闭环 |
| 内容检查 | `ChatApi /chat_msg/check_content` | ✅ chat-api | — | ✅ 用户端闭环 |
| 首页配置 | `ChatApi /client_config/get` | ✅ chat-api | `getClientConfig/setClientConfig` | ✅ 双端闭环 |
| 统计仪表盘 | — | ✅ admin-api + im-server | `getNewUserCount/getLoginUserCount/getGroupCreateStats` | ✅ 管理端闭环 |
| 管理员2FA | — | ✅ admin-api | `setup2FA/verify2FA/get2FAStatus/disable2FA` | ✅ 管理端闭环 |
| 审计日志 | — | ✅ admin-api | `searchSecurityLogs` | ✅ 管理端闭环 |
| 配置中心 | — | ✅ admin-api | `getConfigList/getConfig/setConfig/*` | ✅ 管理端闭环 |
| 应用版本 | — | ✅ admin-api | `pageApplicationVersions/addApplicationVersion/*` | ✅ 管理端闭环 |

---

## 5. 优先级建议

### 🔴 高优先级（阻塞上线）

| # | 任务 | 端 | 说明 |
|---|------|---|------|
| 1 | 用户协议 & 隐私政策页面 | 用户端 | 法规要求，必须上线前完成 |
| 2 | 内容过滤规则管理页 | 管理端 | `/content_filter/*` 后端已就绪，缺管理UI |
| 3 | 检查更新接入 `/application/latest_version` | 用户端 | 后端已有，Flutter硬编码需改为API调用 |

### 🟡 中优先级

| # | 任务 | 端 | 说明 |
|---|------|---|------|
| 4 | 官方群管理UI | 管理端 | `/official_group/set` 后端已有 |
| 5 | 功能开关管理页 | 管理端 | `/feature_toggle/*` 后端已有 |
| 6 | 语言切换(i18n) | 用户端 | 纯前端国际化，不涉及后端 |
| 7 | 已登录设备页 | 用户端 | 需后端配合(im-server有token detail接口) |
| 8 | 管理端消息操作扩展 | 管理端 | `/chat_msg/*` admin端路由已注册 |
| 9 | 提现功能完善 | 后端 | `wallet_handler.go` 目前永远拒绝 |

### 🟢 低优先级

| # | 任务 | 端 | 说明 |
|---|------|---|------|
| 10 | 小程序管理页 | 管理端 | `/applet/*` 后端已有 |
| 11 | 群限制策略管理页 | 管理端 | `/group_restriction/*` 后端已有 |
| 12 | 限流监控页 | 管理端 | `/ratelimit/*` `dist_ratelimit/*` |
| 13 | 策略引擎管理页 | 管理端 | `/policy/*` `/rule/*` |
| 14 | 分片管理页 | 管理端 | `/shard/*` |
| 15 | 位置分享 | 用户端 | 需地图SDK集成 |
| 16 | 扫码功能 | 用户端 | 需相机权限 |
| 17 | 首页网格菜单(7项) | 用户端 | 需完整业务后端 |
| 18 | 主题切换 | 用户端 | 前端ThemeData |
| 19 | Web端钱包Tab | 用户端(Web) | 补充web_layout |
| 20 | Banner服务 | 全栈 | 需新建:10011微服务 |

---

## 附录：路由数量统计

| 层 | 组件 | 路由数 |
|----|------|--------|
| 用户端前端 | Flutter Routes | 8 |
| 管理端前端 | Admin Web Routes | 23 |
| Admin-API | openim-chat :10009 | ~130 |
| Chat-API | openim-chat :10008 | ~45 |
| IM-Server | open-im-server :10002 | ~130+ |
| **总计** | | **~336+** |

| 分类 | 数量 |
|------|------|
| ✅ 前后端完整闭环功能 | 30+ |
| ⛔ 前端占位符/存根 | 15 |
| ⚠️ 后端有API无管理端UI | 10组(~45个路由) |
| ⚠️ 流程有缺口 | 5 |
