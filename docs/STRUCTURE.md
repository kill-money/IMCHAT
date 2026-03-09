# 项目结构文档

## 顶层目录

```
IMCHAT/
├── .github/
│   └── workflows/            # GitHub Actions CI/CD 流水线
│       ├── flutter-ci.yml
│       ├── go-ci.yml
│       └── node-ci.yml
│
├── docs/                     # 项目文档
│   ├── STRUCTURE.md          # 本文件：目录结构说明
│   └── ARCHITECTURE.md       # 系统架构详述
│
├── open-im-server-main/      # OpenIM 核心消息服务 (Go)
├── openim-chat/              # 业务层服务：注册/登录/用户 (Go)
├── webhook-server/           # Webhook 回调服务 (Go)
├── openim_flutter_app/       # Flutter 多平台客户端 (Dart)
├── openim-electron-demo/     # Electron + React 桌面/Web 端 (TS)
├── openim-admin-web/         # 管理后台 (React + UmiJS)
├── openim-docker/            # Docker Compose 基础设施编排
│
├── .gitignore
├── CLAUDE.md                 # Claude Code 工作指南
└── README.md
```

---

## open-im-server-main/

OpenIM 官方核心服务，负责消息路由、群组管理、关系链等核心 IM 功能。

```
open-im-server-main/
├── cmd/                      # 各微服务入口 (main.go)
├── config/                   # 配置文件模板
├── internal/
│   ├── api/                  # HTTP API handler
│   ├── rpc/                  # gRPC service 实现
│   └── msggateway/           # WebSocket 消息网关
├── pkg/                      # 内部公共包
├── tools/                    # CLI 工具 (imctl)
└── go.mod                    # module: github.com/openimsdk/open-im-server/v3
```

**对外端口：** `:10001` (WebSocket) · `:10002` (HTTP API)

---

## openim-chat/

二次开发核心：用户注册/登录、手机验证、业务级用户信息管理。

```
openim-chat/
├── cmd/                      # api / rpc 入口
├── config/                   # 配置文件
├── internal/
│   ├── api/                  # HTTP API (登录/注册/用户)
│   └── rpc/                  # gRPC 服务
├── pkg/                      # 内部包（model/db 层等）
└── go.mod                    # module: github.com/openimsdk/chat
```

**对外端口：** `:10008` (用户 API) · `:10009` (管理员 API)

---

## webhook-server/

轻量 Go HTTP 服务，接收 OpenIM 推送的回调事件，实现业务自定义逻辑。

```
webhook-server/
├── main.go                   # HTTP server + callback router
└── go.mod                    # module: webhook-server
```

**支持的回调类型：**
- 消息发送前/后拦截（单聊 + 群聊）
- 消息入库后回调
- 用户上线/下线通知
- 用户注册拦截
- 好友申请处理
- 群组创建回调

**对外端口：** `:10006`

---

## openim_flutter_app/

单一 Flutter 代码库，运行时检测平台并路由至不同 Layout。

```
openim_flutter_app/
├── lib/
│   ├── main.dart             # 入口：平台检测 + Provider 注册 + 路由
│   ├── core/
│   │   ├── api/              # HTTP 客户端 (api_client, auth_api, chat_api)
│   │   ├── controllers/      # ChangeNotifier: Auth / Conversation / Chat
│   │   ├── models/           # UserInfo / Message / Conversation
│   │   └── desktop_window.dart  # 桌面窗口初始化 (1100×700)
│   ├── shared/
│   │   ├── pages/            # 跨平台页面 (login, register)
│   │   ├── theme/            # 设计 token (colors, spacing, typography)
│   │   └── widgets/          # 公共组件 + 设计系统 (AppButton, AppCard…)
│   └── ui/
│       ├── mobile/           # 底部导航布局 + 移动端页面
│       ├── desktop/          # 三栏布局 + 系统托盘
│       └── web/              # 响应式 Web 布局
├── android/
├── ios/
├── windows/
├── web/
└── pubspec.yaml
```

**平台路由逻辑（main.dart）：**
```
isWeb  → WebLayout
isDesktop → DesktopLayout   (Windows/macOS/Linux)
else   → MobileLayout       (iOS/Android)
```

**后端 IP 配置：** `--dart-define=API_HOST=<ip>`（默认 `192.168.0.136`）

---

## openim-electron-demo/

React 18 + Vite + Electron，同时支持 Web 部署和 Windows 打包。

```
openim-electron-demo/
├── src/
│   ├── pages/                # 路由页面
│   ├── components/           # UI 组件
│   ├── store/                # Zustand 状态管理
│   ├── api/                  # axios HTTP 封装
│   └── utils/
├── electron/                 # Electron 主进程
├── public/
└── package.json              # React 18 · Vite · Electron · Tailwind · LiveKit
```

---

## openim-admin-web/

UmiJS max + Ant Design Pro v6，企业级管理后台。

```
openim-admin-web/
├── src/
│   ├── pages/                # UmiJS 约定路由页面
│   ├── components/           # 业务组件
│   ├── services/             # API 请求层
│   └── models/               # umi model（数据流）
├── config/                   # UmiJS 配置
└── package.json              # React 19 · UmiJS · AntD Pro v6 · Biome
```

---

## openim-docker/

Docker Compose 一键部署全部基础设施和后端服务。

```
openim-docker/
├── docker-compose.yaml       # 主编排文件（13 个服务）
├── .env                      # 端口/密码/版本配置
└── components/
    ├── prometheus/           # Prometheus 配置
    ├── grafana/              # Grafana 配置
    └── alertmanager/         # AlertManager 配置
```

**服务分组：**
- 基础设施：mongo · redis · kafka · etcd · minio
- 应用服务：openim-server · openim-chat
- 前端容器：openim-web-front · openim-admin-front
- 监控（可选 `--profile m`）：prometheus · grafana · alertmanager · node-exporter

---

## .github/workflows/

| 文件 | 触发条件 | Job |
|------|----------|-----|
| `flutter-ci.yml` | `openim_flutter_app/**` push/PR | flutter analyze, flutter test |
| `go-ci.yml` | Go 模块目录 push/PR | go build, go vet, go test |
| `node-ci.yml` | Node 项目目录 push/PR | npm lint, npm build |
