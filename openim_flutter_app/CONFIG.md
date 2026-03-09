# OpenIM Flutter App 配置说明（v3.8.x）

## 后端地址（解决 H5/真机「登录失败: Failed to fetch」）

- 登录/注册请求发往 **chat 服务**：`http://<API_HOST>:10008`（如 `/account/login`）。
- 若 H5 或真机报错 `Failed to fetch, uri=http://localhost:10008/account/login`，说明当前环境访问不到 `localhost:10008`。

### 1）本机浏览器跑 H5（flutter run -d chrome）

- **后端在本机**：保证 chat 与 open-im-server 已按 [OpenIM 部署文档](https://doc.rentsoft.cn/guides/getstarted) 启动，且 chat 监听 `10008`。此时默认 `API_HOST=localhost` 即可。
- **后端在其它机器**：编译时指定主机，例如后端在 `192.168.1.100`：
  ```bash
  flutter run -d chrome --dart-define=API_HOST=192.168.1.100
  ```

### 2）真机 / 其它电脑访问

- 必须使用**运行 chat 的那台机器的局域网 IP**，不能使用 `localhost`。例如：
  ```bash
  flutter run -d <device_id> --dart-define=API_HOST=192.168.1.100
  ```

### 3）修改默认主机（不改命令行）

- 在 `lib/core/api/api_client.dart` 中把 `defaultValue: 'localhost'` 改为你的默认主机（如 `'192.168.1.100'`），或保持 `localhost` 在本地开发时使用。

## 多端一致性（OpenIM 二次开发规范 v2.0）

- 用户端：Flutter（iOS/Android）+ Web（H5）+ Electron（Windows .exe）。
- SDK 初始化与 API 基地址按平台统一；当前 Flutter 工程通过 `ApiConfig.apiHost` 统一控制，Web 与真机使用同一套配置（仅主机可配置）。

## 参考

- 二次开发指南：https://doc.rentsoft.cn/guides/solution/developnewfeatures  
- open-im-server：https://github.com/openimsdk/open-im-server（v3.8.x）  
- chat：https://github.com/openimsdk/chat  
