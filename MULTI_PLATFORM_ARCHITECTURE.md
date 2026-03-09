# OpenIM 多平台架构文档

> **核心理念：多端独立 UI + 统一后端接口**
>
> 每个平台使用各自原生 UI 框架，遵循各平台设计规范，**严禁 UI 混用**（如 Windows 不能出现移动端 UI 模式）。所有平台共享同一套 OpenIM Server / OpenIM Chat 后端 API。

---

## 1. 整体架构图

```
┌──────────────────────────────────────────────────────────────────────┐
│                         客 户 端 (多端独立 UI)                         │
│                                                                      │
│  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  ┌───────────┐  │
│  │  Web 端      │  │  Windows 端   │  │  Android 端   │  │  iOS 端   │  │
│  │  React 18    │  │  Electron     │  │  Kotlin +     │  │  Swift +  │  │
│  │  + Vite      │  │  + React      │  │  Jetpack      │  │  SwiftUI  │  │
│  │              │  │              │  │  Compose      │  │           │  │
│  │  UI: Ant     │  │  UI: Fluent   │  │  UI: Material │  │  UI: HIG  │  │
│  │  Design      │  │  Design /    │  │  Design 3     │  │  (Apple)  │  │
│  │              │  │  自定义       │  │              │  │           │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  └─────┬─────┘  │
│         │                 │                 │                │        │
│         │   @openim/      │   @openim/      │   OpenIM      │ OpenIM │
│         │   wasm-client   │   wasm-client   │   Android     │ iOS    │
│         │   -sdk          │   -sdk          │   SDK         │ SDK    │
│         │                 │                 │               │        │
└─────────┼─────────────────┼─────────────────┼───────────────┼────────┘
          │                 │                 │               │
          ▼                 ▼                 ▼               ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     统 一 后 端 (OpenIM Server + Chat)                │
│                                                                      │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  OpenIM Server (Go)                                           │   │
│  │  - REST API    :10002   (用户/群组/消息/第三方等)              │   │
│  │  - WebSocket   :10001   (消息推送/实时通信)                   │   │
│  │  - Message GW  :10001   (消息网关)                            │   │
│  └───────────────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  OpenIM Chat (Go)                                             │   │
│  │  - Chat API    :10008   (注册/登录/用户业务)                  │   │
│  │  - Admin API   :10009   (管理后台接口)                        │   │
│  └───────────────────────────────────────────────────────────────┘   │
│  ┌───────────────────────────────────────────────────────────────┐   │
│  │  基础设施                                                     │   │
│  │  - MongoDB :37017  - Redis :16379  - Kafka :19094             │   │
│  │  - etcd    :12379  - MinIO :10005                             │   │
│  └───────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 2. 各平台技术栈与设计规范

### 2.1 Web 端

| 项目 | 说明 |
|------|------|
| 框架 | React 18 + TypeScript |
| 构建 | Vite 4 |
| IM SDK | `@openim/wasm-client-sdk` v3.8.x |
| UI 规范 | Ant Design / 自定义 |
| 代码仓库 | `openim-electron-demo/` (Web 模式) |
| 开发端口 | `http://localhost:5173` |

### 2.2 Windows 端

| 项目 | 说明 |
|------|------|
| 框架 | Electron + React 18 + TypeScript |
| 构建 | Vite 4 + electron-builder |
| IM SDK | `@openim/wasm-client-sdk` v3.8.x |
| UI 规范 | Fluent Design / Windows 原生交互 |
| 代码仓库 | `openim-electron-demo/` (Electron 模式) |
| 打包说明 | 与 Web 共享代码但 UI 适配 Windows 交互习惯 |

**Windows 端 UI 要求：**
- 使用 Windows 原生窗口控件（最小化/最大化/关闭）
- 系统托盘图标 + 消息通知
- 支持多窗口（聊天窗口可独立弹出）
- 快捷键遵循 Windows 惯例（Ctrl+C/V、Alt+F4 等）
- **禁止使用移动端底部 Tab 导航**

### 2.3 Android 端（本工作区由 Flutter 统一实现）

本仓库移动端统一使用 **openim_flutter_app**（Flutter）产出 Android APK，不再保留原生 openim-android-demo。以下为原生栈参考（供对外对接或参考用）：

| 项目 | 说明 |
|------|------|
| 语言 | Kotlin + Java (兼容) |
| UI 框架 | Jetpack Compose + Material Design 3 |
| IM SDK | OpenIM Android SDK |
| 代码仓库 | 官方 [openim-android-demo](https://github.com/openimsdk/open-im-android-demo)（工作区外） |

**本工作区 Android 配置**：在 `openim_flutter_app` 中通过 `lib/core/api/api_client.dart` 的 `ApiConfig.apiHost`（或编译参数 `--dart-define=API_HOST=...`）统一配置后端地址，详见 openim_flutter_app/CONFIG.md。

### 2.4 iOS 端（本工作区由 Flutter 统一实现）

本仓库移动端统一使用 **openim_flutter_app**（Flutter）产出 iOS IPA，不再保留原生 openim-ios-demo。以下为原生栈参考：

| 项目 | 说明 |
|------|------|
| 语言 | Swift 5 |
| UI 框架 | UIKit + SwiftUI (混合) |
| IM SDK | OpenIM iOS SDK (CocoaPods) |
| 代码仓库 | 官方 [openim-ios-demo](https://github.com/openimsdk/open-im-ios-demo)（工作区外） |

**本工作区 iOS 配置**：同 Android，使用 `openim_flutter_app` 的 `ApiConfig.apiHost` 与 CONFIG.md。

### 2.5 Flutter 用户端（本工作区移动端 + Web 统一入口）

| 项目 | 说明 |
|------|------|
| 框架 | Flutter 3.24+ / Dart 3 |
| 产出 | iOS IPA、Android APK、Web（H5）、Windows 桌面 |
| 代码仓库 | `openim_flutter_app/` |
| API 配置 | `lib/core/api/api_client.dart` 中 `ApiConfig.apiHost`，支持 `--dart-define=API_HOST=<ip>` |
| 说明 | 符合 OpenIM 二次开发手册 v2.0：用户端移动端统一由此工程构建，与 Electron（Web/Windows）共享后端 API |

---

## 3. 管理后台

| 项目 | 说明 |
|------|------|
| 框架 | UmiJS max + Ant Design Pro v6 + React 19 |
| UI 组件 | Ant Design 6 + ProComponents |
| 代码仓库 | `openim-admin-web/` |
| 开发端口 | `http://localhost:8000` |
| API 代理 | `/admin_api/` → `:10009`, `/chat_api/` → `:10008`, `/im_api/` → `:10002` |
| 认证方式 | 双 Token (adminToken + imToken) |

**管理后台功能模块：**
- 数据概览（注册统计、活跃统计、群组统计）
- 用户管理（搜索、在线状态、封禁/解封、强制下线）
- 群组管理（列表、解散、禁言）
- 消息管理（搜索、管理员代发）
- 系统管理（管理员账号、IP 封禁）
- 注册设置（邀请码、默认好友/群组）

---

## 4. 统一后端 API 接口说明

所有客户端通过以下三个端口与后端通信：

| 端口 | 服务 | 说明 | 协议 |
|------|------|------|------|
| 10001 | OpenIM MsgGateway | 消息推送 / 实时通信 | WebSocket |
| 10002 | OpenIM API | 用户/群组/消息/第三方 | HTTP REST |
| 10008 | OpenIM Chat API | 注册/登录/业务 | HTTP REST |
| 10009 | OpenIM Admin API | 管理后台专用 | HTTP REST |

### 4.1 核心 API 分类

**IM API (Port 10002)**
```
/user/get_users              # 搜索用户
/user/get_users_info         # 获取用户详情
/user/get_users_online_status # 在线状态
/group/get_groups            # 群组列表
/group/dismiss_group         # 解散群组
/group/mute_group            # 群组禁言
/msg/send_msg                # 发送消息
/msg/search_msg              # 搜索消息
/msg/revoke_msg              # 撤回消息
/auth/force_logout           # 强制下线
/third/logs/search           # 日志搜索
/statistics/user/register    # 注册统计
/statistics/user/active      # 活跃统计
```

**Chat API (Port 10008)**
```
/account/login               # 用户登录
/account/register            # 用户注册
/account/reset_password      # 重置密码
```

**Admin API (Port 10009)**
```
/account/login               # 管理员登录
/account/info                # 管理员信息
/account/search              # 搜索管理员
/block/add                   # 封禁用户
/block/del                   # 解封用户
/block/search                # 搜索封禁
/forbidden/ip/add            # IP 封禁
/invitation_code/gen         # 生成邀请码
/default/user/add            # 添加默认好友
/default/group/add           # 添加默认群组
/statistic/new_user_count    # 新增用户统计
/statistic/login_user_count  # 登录用户统计
```

---

## 5. 项目目录结构总览（已按二次开发规范手册 v2.0 整理）

```
D:\procket\IMCHAT\
├── open-im-server-main/      # [后端] OpenIM Server 源码 (Go)，端口 10001/10002
├── openim-chat/              # [后端] OpenIM Chat 服务 (Go)，端口 10008/10009
├── openim-docker/             # [部署] Docker 编排
├── webhook-server/            # [可选] Webhook 服务
│
├── openim_flutter_app/       # [用户端] Flutter（iOS + Android + Web），统一 UI 与 API 配置
├── openim-electron-demo/     # [用户端] Web App + Windows .exe (React + Electron)
│
├── openim-admin-web/         # [管理端] 管理后台 (UmiJS + Ant Design Pro)
│
├── README.md                 # 工作区说明与快速启动
├── REPO_STRUCTURE.md         # 协议→后端→前端 流程与目录规范
└── MULTI_PLATFORM_ARCHITECTURE.md   # 本文件（多平台架构与 API）
```

说明：移动端统一由 **openim_flutter_app** 产出 IPA/APK；Web/Windows 由 **openim-electron-demo** 覆盖。冗余的 openim-android-demo、openim-ios-demo、openim-h5-demo、openim-admin-front、openim-banner-service 已移出工作区以保持整洁，详见 REPO_STRUCTURE.md。

---

## 6. UI 混用禁止规则

| 规则编号 | 规则描述 |
|----------|----------|
| R1 | **Windows 端禁止使用移动端 Tab Bar 导航模式**，应使用侧边栏 + 顶部工具栏 |
| R2 | **Android 端禁止使用 iOS 风格控件**（如 iOS 开关、iOS 导航栏样式） |
| R3 | **iOS 端禁止使用 Material Design 控件**（如 FAB 浮动按钮、Snackbar） |
| R4 | **Web 端不得直接嵌入移动端 WebView 页面作为桌面功能** |
| R5 | 各端弹窗、Toast、Dialog 必须使用各自平台原生实现方式 |
| R6 | 导航手势必须遵循各平台标准（iOS 左滑返回、Android 系统返回、Windows Alt+Left） |

---

## 7. 开发与部署流程

### 7.1 本地开发环境

```bash
# 1. 启动后端依赖服务
cd openim-docker && docker compose up -d

# 2. 启动 OpenIM Server（见 open-im-server-main 文档）
# 3. 启动 OpenIM Chat（见 openim-chat 文档）

# 4. 用户端 - Flutter（移动端 + Web）
cd openim_flutter_app && flutter pub get
flutter run -d chrome          # Web (H5)
flutter run -d <android_id>    # Android
flutter run -d windows         # Windows 桌面

# 5. 用户端 - Web / Windows (Electron)
cd openim-electron-demo && npm install && npm run dev

# 6. 管理后台
cd openim-admin-web && npm install && npm run start
```

### 7.2 各平台构建打包

| 平台 | 构建命令 / 工具 | 产出物 |
|------|----------------|--------|
| Flutter Android | `cd openim_flutter_app && flutter build apk` | `.apk` |
| Flutter iOS | `cd openim_flutter_app && flutter build ipa` | `.ipa` |
| Flutter Web | `cd openim_flutter_app && flutter build web` | `build/web/` |
| Web (Electron 模式) | `cd openim-electron-demo && npm run build` | `dist/` 静态文件 |
| Windows | `cd openim-electron-demo && npm run build:electron` | `.exe` 安装包 |
| Admin | `cd openim-admin-web && npm run build` | `dist/` 静态文件 |

---

## 8. 后续开发计划

- [ ] Web/Windows 客户端 UI 优化与功能增强
- [ ] Android 端 Jetpack Compose 改造（官方 Demo 基于 Java XML，逐步迁移）
- [ ] iOS 端 SwiftUI 改造（官方 Demo 基于 UIKit，逐步迁移）
- [ ] 管理后台完善（数据统计图表、操作日志、系统配置等）
- [ ] 统一消息推送方案（FCM / 个推 / APNs）
- [ ] 音视频通话集成
- [ ] 国际化 (i18n) 多语言支持
