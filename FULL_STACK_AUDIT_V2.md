# 全栈生产就绪审计报告 V2

> **审计范围**: openim-admin-web · openim_flutter_app · openim-chat (Go) · MongoDB · Redis · Docker  
> **生成时间**: Phase 11 综合审计  
> **评级体系**: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low

---

## 执行摘要

| 维度 | 评分 | 关键发现 |
|------|------|----------|
| **Admin Web 前端** | ⭐⭐⭐⭐ | 功能完整，安全需加固（localStorage token、CSP 缺失） |
| **Flutter 客户端** | ⭐⭐⭐⭐ | 架构清晰，明文 token 存储是唯一 Critical |
| **Go 后端** | ⭐⭐⭐⭐ | 安全体系优秀，HTTP 200 全返是最大问题 |
| **数据库层** | ⭐⭐⭐⭐ | 索引合理，verify_code 缺 TTL 索引 |
| **跨层集成** | ⭐⭐⭐⭐ | API 契约一致，Docker 需资源限制 |
| **总评** | ⭐⭐⭐⭐ | **可上线，需修复 5 个 Critical + 8 个 High** |

---

## 🔴 CRITICAL 问题 (共 5 项 — 上线前必须修复)

### C1. Flutter Token 明文存储
- **位置**: `openim_flutter_app/lib/core/services/auth_storage_service.dart`
- **问题**: imToken、chatToken 以明文 JSON 写入本地文件 `.auth_session`，无加密、无文件权限控制
- **风险**: 恶意 App / root 设备可直接读取 token，导致会话劫持
- **修复**: 使用 `flutter_secure_storage`（mobile）或平台加密 API（desktop）

### C2. Go 后端 HTTP 状态码全部返回 200
- **位置**: `openim-chat/internal/api/admin/admin.go` 及所有 handler
- **问题**: 无论成功/失败，`apiresp.GinError()` 和 `apiresp.GinSuccess()` 均返回 HTTP 200
- **风险**: 违反 REST 语义，前端无法通过 HTTP 状态码区分错误，监控/WAF/CDN 无法正确识别错误
- **修复**: 修改 `apiresp` 包，成功 200、参数错误 400、认证失败 401、权限不足 403、服务端错误 500

### C3. verify_code 集合缺失 TTL 索引
- **位置**: `openim-chat/pkg/common/db/model/chat/verify_code.go`
- **问题**: 验证码集合无 TTL 索引，过期验证码永不自动删除
- **风险**: 集合无限增长 → 查询变慢 → 磁盘占满
- **修复**: 添加 `create_time` 字段的 TTL 索引（24h 过期）

### C4. Admin Web Token 存储在 localStorage
- **位置**: `openim-admin-web/src/services/openim/request.ts` L41-43
- **问题**: `openim_admin_token`、`openim_im_token`、`openim_refresh_token` 均存于 localStorage
- **风险**: XSS 攻击可窃取所有 token，refresh_token 长期有效风险更大
- **修复**: 改用 sessionStorage（减少窗口） 或 httpOnly Cookie + CSRF token

### C5. Docker 缺少容器资源限制
- **位置**: `openim-docker/docker-compose.yaml`
- **问题**: 所有服务均未设置 CPU/内存限制
- **风险**: 单个服务 OOM 或 CPU 暴涨可拖垮整个宿主机
- **修复**: 为每个服务添加 `deploy.resources.limits`

---

## 🟠 HIGH 问题 (共 8 项 — 本迭代修复)

### H1. Flutter 内存泄漏 — TextEditingController 未释放
- **位置**: `openim_flutter_app/lib/ui/mobile/pages/mobile_chat_page.dart` L442
- **问题**: `controller.dispose;`（缺少括号 `()`），导致 dispose 从未执行
- **影响**: 每次编辑消息泄漏一个 TextEditingController
- **修复**: `controller.dispose();`

### H2. Go 后端文件上传无大小限制
- **位置**: `openim-chat/internal/api/admin/admin.go` `ImportUserByXlsx` handler
- **问题**: Excel 导入未检查 `ContentLength`，可上传任意大小文件
- **影响**: DoS 攻击 — 上传超大文件耗尽内存
- **修复**: 添加 `c.Request.ContentLength > 10*1024*1024` 检查

### H3. TOTP 密钥明文存储在 MongoDB
- **位置**: `openim-chat/internal/api/mw/totp_manager.go`
- **问题**: TOTP base32 密钥以明文存储，数据库泄露即全部暴露
- **修复**: 使用 `nacl/secretbox` 加密后存储

### H4. N+1 查询 — 用户管理批量操作
- **位置**: `openim-chat/internal/api/admin/admin.go` L418
- **问题**: 循环逐个获取用户信息 `for _, uid := range req.UserIDs`
- **影响**: 100 个用户 = 100 次数据库查询
- **修复**: 使用 `$in` 批量查询

### H5. Admin Web 缺失 CSP 头
- **位置**: nginx 配置 + 前端部署
- **问题**: 无 Content-Security-Policy 响应头
- **影响**: XSS 攻击无额外防线
- **修复**: nginx 添加 `Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline'`

### H6. Admin 密码使用 MD5
- **位置**: `openim-chat/internal/api/admin/admin.go` + 前端 `api.ts`
- **问题**: 管理员密码前端 MD5 → 后端直接存储，MD5 已被彩虹表攻破
- **缓解**: SensitiveVerify v2 已在验证层使用 bcrypt 渐进式迁移（只要完成迁移）
- **修复**: 完成 bcrypt 全量迁移，前端改用安全传输（HTTPS + 原文 → 后端 bcrypt）

### H7. 消息搜索 groupID 传参不当
- **位置**: `openim-admin-web/src/services/openim/api.ts` L283
- **问题**: `groupID` 参数在单聊场景不应传递（后端 proto 不支持同时 recvID + groupID）
- **修复**: 前端根据 sessionType 条件传参

### H8. Docker 数据库端口绑定 0.0.0.0
- **位置**: `openim-docker/docker-compose.yaml`
- **问题**: MongoDB(37017)、Redis(16379)、etcd(12379) 绑定所有接口
- **修复**: 生产环境绑定 `127.0.0.1:37017:27017`，或通过防火墙限制

---

## 🟡 MEDIUM 问题 (共 14 项)

| # | 问题 | 位置 | 说明 |
|---|------|------|------|
| M1 | Token 刷新无限循环风险 | admin-web `request.ts` L60-82 | refresh 失败后无日志，重试链中断 |
| M2 | Admin Web 权限仅单维度 | `access.ts` | 只有 `canAdmin`，无细粒度权限检查 |
| M3 | 广播内容无 XSS 过滤 | admin-web broadcast 页面 | 若支持 Markdown 需 DOMPurify |
| M4 | 分页参数无上限校验 | 后端 search 类 handler | showNum=100000 可导致内存爆 |
| M5 | CheckPermission 每次 gRPC 调用 | `rbac.go` L67 | 高频端点应缓存 admin info |
| M6 | broadcast_worker 无操作超时 | `broadcast_worker.go` processJob | IM API hang 导致 worker 永久阻塞 |
| M7 | 错误静默吞掉（`_ =`） | `broadcast_worker.go` + `totp_manager.go` | json.Marshal 等错误未记录 |
| M8 | token refresh 端点无限速 | `admin.go` RefreshAdminToken | 可被暴力刷新 |
| M9 | Flutter Image.network 无 errorBuilder | `chat_bubble.dart` L71 等 15 处 | 图片加载失败显示空白 |
| M10 | Flutter ~30% widget 缺 const | 散布各处 | 不必要的重建 |
| M11 | 时间戳字段命名不一致 | DB 层 | `create_time` vs `created_at` 混用 |
| M12 | 无软删除模式 | DB 全表硬删除 | 合规/审计需要 |
| M13 | Redis rate limit 不含操作类型 | `rate_limit.go` L121 | 不同 API 共享限速桶 |
| M14 | Flutter Web 平台功能不完整 | `ui/web/` | Settings/Groups 仅 stub |

---

## 🟢 LOW 问题 (共 8 项)

| # | 问题 | 位置 |
|---|------|------|
| L1 | Flutter 离线草稿不持久化 | chat_page |
| L2 | Flutter 轮询间隔 10s 偏大 | im_polling_service.dart |
| L3 | 后端 Goroutine 日志无 correlationID | broadcast_worker.go |
| L4 | Admin Web user tag 写 localStorage 无节流 | user-manage/list |
| L5 | Admin Web 缺 Skeleton 加载组件 | 全站仅 Spin |
| L6 | Banner 管理隐藏（port 10011 未部署） | routes.ts |
| L7 | verify_code 索引非 unique | verify_code.go |
| L8 | 广播 worker 配置硬编码（batch=500, cooldown=200ms） | broadcast_worker.go |

---

## 各层详细评分

### 一、Admin Web 前端

| 子项 | 评分 | 要点 |
|------|------|------|
| 路由注册 | ⭐⭐⭐⭐⭐ | 30+ 路由全注册，404 兜底，懒加载 |
| API 层 | ⭐⭐⭐⭐ | 三端请求函数 + SensitiveVerify v2，类型覆盖好 |
| 功能完整性 | ⭐⭐⭐⭐ | 44+ API 函数，广播/DLQ/白名单/数据统计全覆盖 |
| 状态管理 | ⭐⭐⭐⭐ | UMI Model + useState，简洁实用 |
| 安全性 | ⭐⭐⭐ | HMAC-SHA256 优秀，但 localStorage token + 无 CSP 拉低 |
| 组件质量 | ⭐⭐⭐⭐ | ProTable 统一，仅 3 个共享组件偏少 |
| 性能 | ⭐⭐⭐⭐ | UMI 代码分割，但缺 React.memo / useCallback |

### 二、Flutter 客户端

| 子项 | 评分 | 要点 |
|------|------|------|
| 路由导航 | ⭐⭐⭐⭐⭐ | 命名路由 + 平台感知 + 深链接 |
| API 层 | ⭐⭐⭐⭐ | 统一 HTTP 客户端 + token 注入 + 错误拦截 |
| 功能完整性 | ⭐⭐⭐⭐ | Mobile/Desktop 完整，Web 部分 stub |
| 状态管理 | ⭐⭐⭐⭐ | 7 个 ChangeNotifier，dispose 规范（除 1 个 bug） |
| 安全性 | ⭐⭐⭐ | 明文 token 存储是最大短板 |
| 性能 | ⭐⭐⭐⭐ | ListView.builder + IndexedStack，部分 const 缺失 |
| 跨平台一致性 | ⭐⭐⭐⭐ | Desktop/Mobile 完整，Web 为二等公民 |

### 三、Go 后端

| 子项 | 评分 | 要点 |
|------|------|------|
| 路由覆盖 | ⭐⭐⭐⭐⭐ | 全部注册，无遗漏（ParseToken 已注册） |
| API 设计 | ⭐⭐⭐⭐ | 一致的请求/响应格式，HTTP 200 全返是扣分项 |
| 认证授权 | ⭐⭐⭐⭐⭐ | 2FA + 双 Token + 设备绑定 + 风控 + RBAC |
| 业务逻辑 | ⭐⭐⭐⭐⭐ | 广播系统生产级：MQ + Worker Pool + DLQ + 幂等 |
| 安全性 | ⭐⭐⭐⭐ | 无注入漏洞，响应脱敏，安全头完整 |
| 日志观测 | ⭐⭐⭐⭐ | 结构化日志，少量错误静默吞掉 |

### 四、数据库层

| 子项 | 评分 | 要点 |
|------|------|------|
| Schema 设计 | ⭐⭐⭐⭐ | 字段合理，时间戳命名不一致 |
| 索引策略 | ⭐⭐⭐⭐ | 核心索引到位，verify_code 缺 TTL |
| 查询模式 | ⭐⭐⭐ | 存在 N+1，分页用 skip/limit（可接受） |
| Redis 用法 | ⭐⭐⭐⭐⭐ | 键设计合理，TTL 规范，Lua 原子操作 |
| 数据安全 | ⭐⭐⭐ | TOTP 明文存储，PII 日志需运行时验证 |

### 五、跨层集成

| 子项 | 评分 | 要点 |
|------|------|------|
| API 契约一致性 | ⭐⭐⭐⭐⭐ | 前后端路由/参数对齐，无 mismatch |
| Docker 部署 | ⭐⭐⭐⭐ | 健康检查 + 自动重启 + AOF，缺资源限制 |
| CORS/代理 | ⭐⭐⭐⭐ | 三路代理正确，CorsHandler 全局注册 |
| 配置管理 | ⭐⭐⭐⭐ | 集中式 config，部分值硬编码 |

---

## 修复优先级路线图

### P0 — 上线阻断 (本周)
1. [ ] **C1** Flutter secure storage 改造
2. [ ] **C2** Go apiresp 返回正确 HTTP 状态码
3. [ ] **C3** verify_code TTL 索引
4. [ ] **C5** Docker 资源限制
5. [ ] **H1** Flutter dispose() 括号修复
6. [ ] **H2** 文件上传大小限制

### P1 — 高优先级 (下一迭代)
1. [ ] **C4** Admin Web token → sessionStorage / httpOnly Cookie
2. [ ] **H3** TOTP 密钥加密存储
3. [ ] **H4** N+1 查询批量化
4. [ ] **H5** CSP 头部署
5. [ ] **H6** Admin 密码 bcrypt 全量迁移
6. [ ] **H7** groupID 条件传参
7. [ ] **H8** 数据库端口绑定 127.0.0.1

### P2 — 中优先级 (后续迭代)
- M1-M14 按影响面排序逐步修复
- 重点: 分页上限(M4)、操作超时(M6)、权限缓存(M5)

### P3 — 技术债务
- L1-L8 作为持续改进项
- 时间戳命名统一、软删除模式等

---

## 结论

整体架构扎实，安全体系（HMAC-SHA256 二次验证、RBAC+权限点、设备绑定、风控评分、安全响应头）远超同类项目水平。广播系统经过 Phase 10 加固后已达生产级别。

**5 个 Critical 问题**是上线前必须修复的硬性要求：
- 两端 token 存储安全化 (C1, C4)
- HTTP 状态码语义化 (C2)
- verify_code TTL (C3)
- Docker 资源限制 (C5)

修复这 5 项 + 8 项 High 后，系统即可安全上线，支撑 ≤1M 用户规模。
