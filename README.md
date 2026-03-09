# OpenIM 二次开发工作区（v3.8.x）

基于 [OpenIM 二次开发规范手册 v2.0](https://doc.rentsoft.cn/guides/solution/developnewfeatures)，本仓库按 **协议层 → 后端（open-im-server + chat）→ 前端（用户端 Flutter/Web/Electron + 管理端）** 组织，保证多端一致、可维护。

## 1. 仓库结构一览

```
IMCHAT/
├── open-im-server-main/     # [后端] OpenIM 核心服务 (Go)，端口 10001/10002
├── openim-chat/             # [后端] 业务服务 (Go)，端口 10008/10009
├── openim-docker/           # [部署] Docker 编排（MongoDB/Redis/Kafka 等）
├── webhook-server/          # [可选] Webhook 回调服务
│
├── openim_flutter_app/      # [用户端] Flutter（iOS IPA + Android APK）
├── openim-electron-demo/    # [用户端] Web App + Windows .exe（Electron + React）
│
├── openim-admin-web/        # [管理端] 管理后台（UmiJS + Ant Design Pro）
│
├── MULTI_PLATFORM_ARCHITECTURE.md   # 多平台架构与 API 说明
├── REPO_STRUCTURE.md                # 二次开发流程与目录规范
└── README.md                        # 本文件
```

**协议层**：OpenIM 使用独立仓库 [openimsdk/protocol](https://github.com/openimsdk/protocol)。若需改 RPC/消息格式，先 fork 并修改 protocol，执行 `mage GenGo` 后，再在 open-im-server 中通过 `go.mod replace` 指向本地 protocol。

## 2. 开发流程（手册标准步骤）

| 步骤 | 仓库/目录 | 说明 |
|------|-----------|------|
| 3.1 协议层 | protocol（需单独 clone） | 改 proto → `mage GenGo` → 更新 constant/sdkws |
| 3.2 后端 | open-im-server-main + openim-chat | API/RPC + controller → cache → database/model |
| 3.3 前端 | openim_flutter_app / openim-electron-demo / openim-admin-web | 用户端三端 + 管理端，SDK 与 API 基地址统一 |
| 3.4 数据库 | open-im-server pkg/common/storage/model | 仅改模型层，禁止直接 SQL |

## 3. 快速启动（本地）

```bash
# 1. 组件（MongoDB/Redis 等）
cd openim-docker && docker compose up -d

# 2. OpenIM Server + Chat（需先编译或使用已编译二进制）
# 见 open-im-server-main / openim-chat 各自 README

# 3. 用户端 - Flutter（移动端 + 可跑 Web）
cd openim_flutter_app && flutter run -d chrome   # 或 -d <android_id> / windows

# 4. 用户端 - Web / Windows
cd openim-electron-demo && npm install && npm run dev

# 5. 管理后台
cd openim-admin-web && npm install && npm run start
```

## 4. 参考资源

- 二次开发指南：https://doc.rentsoft.cn/guides/solution/developnewfeatures  
- open-im-server：https://github.com/openimsdk/open-im-server（v3.8.x）  
- chat：https://github.com/openimsdk/chat  
- protocol：https://github.com/openimsdk/protocol  
- Flutter Demo 官方：https://github.com/openimsdk/open-im-flutter-demo  
- Electron Demo 官方：https://github.com/openimsdk/openim-electron-demo  

当前工作区兼容版本：**v3.8.x（2026 年 3 月）**。
