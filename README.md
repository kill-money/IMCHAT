# IMCHAT — OpenIM v3.8.x 二次开发工作区

基于 [OpenIM](https://github.com/openimsdk/open-im-server) 官方协议层构建的全平台即时通讯系统，覆盖 iOS / Android / Web / Windows / macOS 多端，后端采用 Go 微服务架构。

---

## 架构总览

```
┌──────────────────────────────────────────────────────────────────────┐
│                            客户端层                                   │
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────────┐  │
│  │  Flutter App    │  │  Electron App   │  │    Admin Web        │  │
│  │ iOS/Android/Web │  │  Web / Windows  │  │   (UmiJS + AntD)    │  │
│  │  (Dart/Flutter) │  │ (React+Vite+TS) │  │     React 19        │  │
│  └────────┬────────┘  └────────┬────────┘  └──────────┬──────────┘  │
└───────────┼────────────────────┼──────────────────────┼─────────────┘
            │  HTTP / WebSocket  │                      │ HTTP
┌───────────▼────────────────────▼──────────────────────▼─────────────┐
│                           后端服务层                                  │
│                                                                      │
│  ┌──────────────────────────┐   ┌──────────────────────────────┐    │
│  │     OpenIM Server        │   │        OpenIM Chat           │    │
│  │  :10001  WebSocket 网关   │   │   :10008  用户/登录 HTTP API  │    │
│  │  :10002  消息/群组 API    │   │   :10009  管理员 API         │    │
│  │  (Go · Gin · gRPC)       │   │   (Go · Gin · gRPC · GORM)  │    │
│  └──────────────────────────┘   └──────────────────────────────┘    │
│                                                                      │
│  ┌──────────────────────────────────────────────┐                   │
│  │           Webhook Server  :10006              │                   │
│  │  消息拦截 / 用户注册回调 / 敏感词过滤 (Go)       │                   │
│  └──────────────────────────────────────────────┘                   │
└───────────────────────────────────┬──────────────────────────────────┘
                                    │
┌───────────────────────────────────▼──────────────────────────────────┐
│                          基础设施层 (Docker)                          │
│                                                                      │
│   MongoDB      Redis       Kafka (KRaft)    etcd       MinIO        │
│   (消息存储)   (缓存/会话)   (消息队列)     (服务发现)  (文件存储)      │
│                                                                      │
│   Prometheus + Grafana + AlertManager  (可选监控, --profile m)       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 模块说明

| 目录 | 语言/框架 | 作用 |
|------|-----------|------|
| `open-im-server-main/` | Go 1.22 · Gin · gRPC · Kafka | OpenIM 核心服务，处理消息收发、群组、关系链 |
| `openim-chat/` | Go 1.22 · Gin · gRPC · GORM | 业务层服务，负责注册/登录/用户管理 |
| `webhook-server/` | Go 1.26 · net/http | 轻量 Webhook 回调服务，消息拦截与敏感词过滤 |
| `openim_flutter_app/` | Flutter 3 · Dart · Provider | 统一多平台客户端 (iOS/Android/Web/Windows/macOS) |
| `openim-electron-demo/` | React 18 · Vite · Electron · TS | Web + Windows 桌面端，支持音视频 (LiveKit) |
| `openim-admin-web/` | React 19 · UmiJS · Ant Design Pro v6 | 管理后台，用户/群组/消息/系统管理 |
| `openim-docker/` | Docker Compose | 一键启动全部基础设施 + 服务 |

---

## 端口速查

| 端口 | 服务 | 说明 |
|------|------|------|
| `10001` | open-im-server | WebSocket 长连接网关 |
| `10002` | open-im-server | HTTP REST API |
| `10008` | openim-chat | 用户注册/登录 API |
| `10009` | openim-chat | 管理员 API |
| `10006` | webhook-server | Webhook 回调接收 |
| `27017` | MongoDB | 数据库 |
| `6379` | Redis | 缓存 |
| `9092` | Kafka | 消息队列 |
| `12379` | etcd | 服务注册发现 |
| `10005` | MinIO | 对象存储 |

---

## 快速启动

### 前置要求

- Docker Desktop 4.x+
- Go 1.22+
- Flutter 3.x（含 Dart 3.6+）
- Node.js 18+

### 1. 启动基础设施 + 后端服务

```bash
cd openim-docker
docker compose up -d
```

### 2. 启动 Webhook 服务（可选）

```bash
cd webhook-server
go run main.go
```

### 3. Flutter 客户端

```bash
cd openim_flutter_app
flutter pub get

# 使用默认后端 IP (192.168.0.136)
flutter run -d windows

# 指定后端 IP（真机/远程部署必须）
flutter run -d android --dart-define=API_HOST=192.168.1.100
flutter run -d chrome  --dart-define=API_HOST=192.168.1.100
```

### 4. Electron / Web 客户端

```bash
cd openim-electron-demo
npm install && npm run dev
```

### 5. 管理后台

```bash
cd openim-admin-web
npm install && npm run dev
```

---

## 开发命令

### Flutter

```bash
flutter pub get          # 安装依赖
flutter analyze          # 静态分析
flutter test             # 全量测试
flutter test test/widget_test.dart   # 单个测试文件
flutter build apk        # Android APK
flutter build web        # Web
flutter build windows    # Windows 桌面
```

### Go（适用于各 Go 模块目录）

```bash
go build ./...
go test ./...
go vet ./...
```

### Node（electron-demo / admin-web）

```bash
npm install
npm run dev      # 开发模式
npm run build    # 生产构建
npm run lint     # 代码检查
```

---

## 环境配置

Flutter 客户端通过 `--dart-define` 编译时注入（见 `openim_flutter_app/lib/core/api/api_client.dart`）：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `API_HOST` | `192.168.0.136` | 后端服务主机 IP |

Docker 基础设施端口/密码配置见 `openim-docker/.env`。

---

## CI/CD

GitHub Actions 自动化流水线（见 `.github/workflows/`）：

| 工作流 | 触发路径 | 检查内容 |
|--------|----------|---------|
| `flutter-ci.yml` | `openim_flutter_app/**` | analyze + test |
| `go-ci.yml` | `open-im-server-main/**`, `openim-chat/**`, `webhook-server/**` | build + vet + test |
| `node-ci.yml` | `openim-electron-demo/**`, `openim-admin-web/**` | lint + build |

---

## 技术栈

| 层次 | 技术 |
|------|------|
| 后端 | Go · Gin · gRPC · MongoDB · Redis · Kafka · etcd · MinIO |
| Flutter | Dart · Provider · http · window_manager · system_tray |
| Web/Electron | React 18/19 · TypeScript · Vite · Ant Design · Zustand · LiveKit |
| 管理台 | UmiJS max · Ant Design Pro v6 · React 19 |
| 基础设施 | Docker Compose · Prometheus · Grafana |
