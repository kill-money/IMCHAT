# OpenIM 工作区目录与二次开发规范

本文档说明本仓库如何对应 **OpenIM 二次开发规范手册 v2.0** 的「协议层 → 后端 → 前端」流程，以及各目录职责。

---

## 一、目录与手册对应关系

| 手册章节 | 本仓库位置 | 说明 |
|----------|------------|------|
| **3.1 协议层** | 需单独 clone [openimsdk/protocol](https://github.com/openimsdk/protocol) | 修改 proto、GenGo、constant/sdkws。open-im-server 的 go.mod 可 replace 指向本地 protocol |
| **3.2 后端** | `open-im-server-main/` | IM 核心：msggateway、api、RPC、storage。仅改 model + controller/cache/database |
| **3.2 后端** | `openim-chat/` | 用户注册/登录、管理 REST。新增接口参考 HOW_TO_ADD_REST_RPC_API，权限 authverify.CheckAccessV3 |
| **3.3 用户端前端** | `openim_flutter_app/` | Flutter：iOS + Android + Web（同一工程多端）。SDK 初始化与 API 基地址统一（见 CONFIG.md） |
| **3.3 用户端前端** | `openim-electron-demo/` | Web App + Windows .exe（Electron + React），与 Flutter 共享后端 API |
| **3.3 管理端前端** | `openim-admin-web/` | 管理后台，调用 chat Admin API (10009) 等 |
| **部署/基础设施** | `openim-docker/` | Docker Compose：MongoDB、Redis、Kafka、etcd、MinIO 等 |
| **可选** | `webhook-server/` | Webhook 回调服务，按需使用 |

---

## 二、已移除的目录（保持工作区整洁）

以下目录已从根目录移除，避免与手册推荐技术栈重复或无关：

- `openim-android-demo`：移动端统一使用 **openim_flutter_app**（Flutter）构建 Android/iOS。
- `openim-ios-demo`：同上，由 Flutter 工程产出 IPA/APK。
- `openim-h5-demo`：Web 用户端由 **openim-electron-demo**（Web 模式）覆盖。
- `openim-admin-front`：管理端仅保留 **openim-admin-web**，避免双后台并存。
- `openim-banner-service`：非 OpenIM 核心/手册规定组件，已移出主工作区。
- 根目录临时文件 `_cmake2.txt`、`_cmake_check.txt`：已删除。

若需参考官方原生 Android/iOS/ H5 Demo，可从 GitHub 单独 clone 到工作区外。

---

## 三、二次开发新增功能时的顺序

1. **协议层（若有新 RPC/消息类型）**  
   在 protocol 仓库中改 proto → `mage GenGo` → 在 open-im-server 的 go.mod 中 replace 到本地 protocol，再 `mage build`。

2. **后端**  
   - open-im-server：新增 API/RPC、在 pkg/common/storage/model 增字段、controller/cache/database 三层。  
   - openim-chat：新增 REST/RPC 按官方 HOW_TO_ADD 文档，权限校验用 authverify。

3. **前端**  
   - 用户端：Flutter（openim_flutter_app）与 Web/Windows（openim-electron-demo）同步改，API 基地址统一用 ApiConfig（Flutter 见 openim_flutter_app/CONFIG.md）。  
   - 管理端：openim-admin-web 调用 chat Admin API。

4. **数据库**  
   仅改 model 定义与 controller 内事务/缓存，禁止直接写 SQL。

---

## 四、多端一致性检查（手册强制）

- [ ] Flutter：iOS/Android/Web 三端均能登录、收发消息、配置一致。  
- [ ] Electron：Web 与 Windows 构建均通过，API 与 Flutter 使用同一后端。  
- [ ] 管理端：openim-admin-web 与 chat 10009 互通。  
- [ ] 打包命令可复现：`flutter build apk/ipa`、`npm run build:electron`、管理端 build。

以上为当前工作区整理与规范说明，后续开发请严格按手册 v2.0 与本文档执行。
