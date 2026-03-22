# k6 压测结果判读标准 & 三层瓶颈定位

## 目录
1. [k6 输出字段速查](#1-k6-输出字段速查)
2. [怎么判断"到极限了"](#2-怎么判断到极限了)
3. [哪个服务先崩 — 三层瓶颈定位](#3-哪个服务先崩--三层瓶颈定位)
4. [一键诊断命令集](#4-一键诊断命令集)
5. [典型瓶颈场景及解法](#5-典型瓶颈场景及解法)

---

## 1. k6 输出字段速查

```
k6 run --out json=results.json scripts/k6_load_test.js
```

k6 结束后输出类似：

```
     ✓ login status 200
     ✗ login errCode=0
      ↳  95% — ✓ 4750 / ✗ 250

     http_req_duration..............: avg=45ms  min=3ms  med=28ms  max=1.2s  p(90)=85ms  p(95)=120ms
     http_req_failed................: 2.3%  ✓ 115  ✗ 4885
     http_reqs......................: 5000  55.5/s
     iteration_duration.............: avg=2.1s  min=1.5s  med=2.0s  max=5.3s  p(90)=2.8s  p(95)=3.2s
     vus............................: 200   min=1   max=200
     vus_max........................: 200   min=200 max=200

     login_duration.................: avg=52ms  p(95)=130ms
     login_fail_rate................: 5.0%
     rate_limit_429.................: 23
     api_errors.....................: 8
```

### 关键指标含义

| 指标 | 含义 | 健康阈值 |
|------|------|---------|
| `http_req_duration p(95)` | 95% 请求的响应时间 | < 500ms (API)，< 2s (登录) |
| `http_req_failed` | HTTP 非 2xx 比例 | < 5% |
| `http_reqs` (rate) | 每秒请求总数 (RPS) | 越高越好 |
| `iteration_duration` | 每个 VU 完成一轮全部场景的耗时 | < 5s |
| `login_duration p(95)` | 登录请求 p95 延迟 | < 1s |
| `login_fail_rate` | 登录业务失败率（errCode≠0） | < 10% |
| `rate_limit_429` | 被限流的请求数 | 看趋势 |
| `api_errors` | 非限流的 API 错误数 | 应接近 0 |

---

## 2. 怎么判断"到极限了"

### 2.1 响应时间拐点

```
VU=50   → p95=  45ms  ← 线性增长
VU=100  → p95=  80ms  ← 线性增长
VU=150  → p95= 180ms  ← 开始弯曲 ⚠️
VU=200  → p95= 850ms  ← 非线性飙升 ❌ ← 这就是拐点
VU=250  → p95=2100ms  ← 系统过载
```

**判断法则：当 VU 增加 50%，p95 增加 > 100%，说明已过拐点。**

### 2.2 错误率突变

```
VU=100  → fail_rate=0.1%
VU=200  → fail_rate=0.5%
VU=250  → fail_rate=12%   ← 突变 ❌
```

**错误率从 <1% 突然跳到 >5%，系统到极限了。**

### 2.3 RPS 饱和

```
VU=100  → RPS=110
VU=200  → RPS=195
VU=300  → RPS=198  ← 不再增长 ❌
VU=400  → RPS=185  ← 反而下降 = 彻底过载
```

**RPS 不随 VU 增加而增长 → CPU/内存/连接池某处饱和。**

### 2.4 快速阶梯测试法

```bash
# 逐步加压，每梯度 30s，观察拐点
k6 run --stage "30s:50,30s:100,30s:150,30s:200,30s:250,30s:300,15s:0" scripts/k6_load_test.js
```

---

## 3. 哪个服务先崩 — 三层瓶颈定位

```
                     ┌─────────────────────────────────────────┐
                     │               请求入口                    │
                     │         k6 → Nginx → Go Service          │
                     └───────────┬─────────────────────────────┘
                                 │
              ┌──────────────────┼──────────────────┐
              ▼                  ▼                   ▼
    ┌─────────────────┐ ┌───────────────┐  ┌─────────────────┐
    │   Layer 1: CPU  │ │ Layer 2: Redis│  │  Layer 3: DB    │
    │                 │ │               │  │  (MongoDB)      │
    │ Go goroutines   │ │ 连接池/延迟    │  │  连接池/慢查询   │
    │ GC pause        │ │ 内存淘汰       │  │  锁竞争         │
    │ Nginx workers   │ │ Lua 脚本耗时   │  │  磁盘 IO        │
    └────────┬────────┘ └───────┬───────┘  └────────┬────────┘
             │                  │                    │
             ▼                  ▼                    ▼
    ┌─────────────────────────────────────────────────────────┐
    │                    症状 → 定位对照表                       │
    └─────────────────────────────────────────────────────────┘
```

### 三层瓶颈速查表

| 症状 | p95 延迟 | 错误类型 | 瓶颈层 | 确认命令 |
|------|---------|---------|--------|---------|
| 所有接口 p95 同时飙升 | 全面 >500ms | Connection reset | **CPU** | `docker stats` |
| 仅登录/限流接口慢 | 登录 >1s，其他正常 | timeout | **Redis** | `redis-cli INFO` |
| 仅搜索/列表接口慢 | 搜索 >2s，登录正常 | slow query | **MongoDB** | `db.currentOp()` |
| 间歇性全部超时 | 偶发 >5s | 502 Bad Gateway | **Go GC** | `GODEBUG=gctrace=1` |
| 429 大量出现但 p95 正常 | <100ms | 429 Too Many Req | **限流生效** | 正常现象 |
| 连接拒绝 (connection refused) | N/A | ECONNREFUSED | **端口/进程** | `netstat -tlnp` |

---

## 4. 一键诊断命令集

### 4.1 总览：谁先到瓶颈

```bash
# ── 一键看所有容器 CPU/内存/网络 ──
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
```

输出解读：
```
NAME             CPU %    MEM USAGE / LIMIT      NET I/O          BLOCK I/O
openim-chat      185%     320MiB / 2GiB          12MB / 8MB       50MB / 10MB   ← CPU 高 = Go 瓶颈
redis            12%      85MiB / 512MiB         45MB / 38MB      0B / 0B       ← 正常
mongo            45%      1.2GiB / 4GiB          30MB / 25MB      500MB / 200MB ← IO 高 = DB 瓶颈
openim-server    90%      450MiB / 2GiB          20MB / 15MB      10MB / 5MB
```

**判断规则：**
- CPU > 150%（多核折算）→ Go 服务瓶颈
- MEM > 80% limit → 内存瓶颈，即将 OOM
- BlockIO 持续高 → 磁盘瓶颈 (MongoDB)

### 4.2 Layer 1: CPU / Go 服务诊断

```bash
# Go 容器 goroutine 数量和 GC
docker exec openim-chat sh -c 'curl -s http://localhost:10009/debug/pprof/goroutine?debug=1 | head -5'

# 实时 CPU profile（30 秒采样）
docker exec openim-chat sh -c 'curl -o /tmp/cpu.prof http://localhost:10009/debug/pprof/profile?seconds=30'
docker cp openim-chat:/tmp/cpu.prof ./cpu.prof
go tool pprof -http=:8080 cpu.prof

# Goroutine 泄露检测
docker exec openim-chat sh -c 'curl -s http://localhost:10009/debug/pprof/goroutine?debug=1 | grep "^goroutine"'
# 正常：goroutine profile: total 50-200
# 异常：goroutine profile: total 10000+ ← 泄露
```

### 4.3 Layer 2: Redis 诊断

```bash
# Redis 连接数 + 内存 + 命令统计
docker exec redis redis-cli -a openIM123 INFO clients | grep connected_clients
docker exec redis redis-cli -a openIM123 INFO memory | grep used_memory_human
docker exec redis redis-cli -a openIM123 INFO stats | grep -E "instantaneous_ops|rejected_connections|evicted_keys"

# 慢命令日志
docker exec redis redis-cli -a openIM123 SLOWLOG GET 10

# 防爆破 key 分布（检查 bf: 前缀）
docker exec redis redis-cli -a openIM123 --scan --pattern "bf:*" | head -20

# 限流 key 分布
docker exec redis redis-cli -a openIM123 --scan --pattern "rl:*" | head -20

# 关键指标阈值
# connected_clients > 500      → 连接池不够
# evicted_keys > 0             → 内存不足，key 被淘汰
# instantaneous_ops_per_sec    → 当前 QPS
# rejected_connections > 0     → maxclients 太小
```

### 4.4 Layer 3: MongoDB 诊断

```bash
# 当前活跃操作
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin \
  --eval 'db.currentOp({"active": true, "secs_running": {"$gt": 1}}).inprog.forEach(op => print(op.opid, op.op, op.ns, op.secs_running + "s"))'

# 慢查询日志（> 100ms 的操作）
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin \
  --eval 'db.setProfilingLevel(1, {slowms: 100}); print("profiling enabled")'

# 查看慢查询
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin \
  openim_enterprise --eval 'db.system.profile.find().sort({ts:-1}).limit(5).forEach(printjson)'

# 连接数
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin \
  --eval 'db.serverStatus().connections'

# 关键指标阈值
# connections.current > 200    → 连接池需要扩容
# opcounters.query > 5000/s    → 查询压力大
# secs_running > 5s            → 存在阻塞查询
```

### 4.5 一键全景诊断脚本

```bash
#!/bin/bash
# save as: scripts/diagnose_bottleneck.sh
echo "========== DOCKER STATS =========="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"

echo ""
echo "========== REDIS =========="
docker exec redis redis-cli -a openIM123 --no-auth-warning INFO clients 2>/dev/null | grep connected_clients
docker exec redis redis-cli -a openIM123 --no-auth-warning INFO memory 2>/dev/null | grep used_memory_human
docker exec redis redis-cli -a openIM123 --no-auth-warning INFO stats 2>/dev/null | grep -E "instantaneous_ops|rejected_connections|evicted_keys"
echo "Slow log:"
docker exec redis redis-cli -a openIM123 --no-auth-warning SLOWLOG GET 3 2>/dev/null

echo ""
echo "========== MONGODB =========="
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet \
  --eval 'const s=db.serverStatus(); print("connections:", s.connections.current, "/", s.connections.available); print("opcounters:", JSON.stringify(s.opcounters))'

echo ""
echo "========== ACTIVE SLOW OPS =========="
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet \
  --eval 'db.currentOp({"active":true,"secs_running":{"$gt":1}}).inprog.forEach(op => print(op.opid, op.op, op.ns, op.secs_running+"s"))'

echo ""
echo "========== BRUTE-FORCE KEYS =========="
echo "Account:IP keys:"
docker exec redis redis-cli -a openIM123 --no-auth-warning --scan --pattern "bf:*:*" 2>/dev/null | head -10
echo "IP global keys:"
docker exec redis redis-cli -a openIM123 --no-auth-warning --scan --pattern "bf:ip:*" 2>/dev/null | head -10
```

PowerShell 版本：

```powershell
# save as: scripts/Diagnose-Bottleneck.ps1
Write-Host "========== DOCKER STATS ==========" -ForegroundColor Cyan
docker stats --no-stream --format "table {{.Name}}`t{{.CPUPerc}}`t{{.MemUsage}}`t{{.NetIO}}"

Write-Host "`n========== REDIS ==========" -ForegroundColor Cyan
docker exec redis redis-cli -a openIM123 --no-auth-warning INFO clients 2>$null | Select-String "connected_clients"
docker exec redis redis-cli -a openIM123 --no-auth-warning INFO memory 2>$null | Select-String "used_memory_human"
docker exec redis redis-cli -a openIM123 --no-auth-warning INFO stats 2>$null | Select-String "instantaneous_ops|rejected_connections|evicted_keys"
Write-Host "Slow log:"
docker exec redis redis-cli -a openIM123 --no-auth-warning SLOWLOG GET 3 2>$null

Write-Host "`n========== MONGODB ==========" -ForegroundColor Cyan
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet `
  --eval 'const s=db.serverStatus(); print(\"connections:\", s.connections.current, \"/\", s.connections.available); print(\"opcounters:\", JSON.stringify(s.opcounters))'

Write-Host "`n========== BRUTE-FORCE KEYS ==========" -ForegroundColor Cyan
docker exec redis redis-cli -a openIM123 --no-auth-warning --scan --pattern "bf:*" 2>$null | Select-Object -First 10
```

---

## 5. 典型瓶颈场景及解法

### 场景 A：Go CPU 瓶颈（最常见）

**现象**：`docker stats` 显示 openim-chat CPU > 150%，所有接口 p95 同时上升。

**解法**：
```yaml
# docker-compose.override.yml
services:
  openim-chat:
    deploy:
      resources:
        limits:
          cpus: '4'     # 增加 CPU 核心
          memory: 2G
    environment:
      - GOMAXPROCS=4    # 匹配 CPU 限制
```

### 场景 B：Redis 连接池耗尽

**现象**：登录/限流接口 p95 飙升，其他用 token 鉴权的接口也慢。Redis `connected_clients` 接近 `maxclients`。

**解法**：
```bash
# 增大 Redis maxclients
docker exec redis redis-cli -a openIM123 CONFIG SET maxclients 10000

# Go 端增大连接池（需改代码 / env 配置）
# Redis pool size 建议：VU数 × 2
```

### 场景 C：MongoDB 慢查询

**现象**：审计日志查询、用户搜索 p95 >2s，其他接口正常。

**解法**：
```bash
# 添加索引
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin \
  openim_enterprise --eval '
    db.security_log.createIndex({createTime: -1});
    db.security_log.createIndex({adminID: 1, createTime: -1});
    db.security_log.createIndex({action: 1, createTime: -1});
    print("indexes created");
  '
```

### 场景 D：限流按预期生效（不是瓶颈）

**现象**：k6 报大量 429，但 admin API 的 p95 <100ms。

**解读**：这是**正常行为**。限流在 Redis Lua 层直接返回 429，不消耗后端资源。
说明限流配置合理，压测 VU 超过了设定的 QPS 容量。

### 场景 E：三维度限流验证

**确认新策略生效**：

```bash
# 清理测试数据
docker exec redis redis-cli -a openIM123 --no-auth-warning KEYS "bf:*" | xargs -r -L1 docker exec -i redis redis-cli -a openIM123 --no-auth-warning DEL

# 从同一 IP 用错密码打 imAdmin 5 次
for i in $(seq 1 6); do
  curl -s http://localhost:10009/account/login \
    -H "Content-Type: application/json" \
    -H "operationID: test-$i" \
    -d '{"account":"imAdmin","password":"wrong"}'
done

# 检查 Redis key 结构
docker exec redis redis-cli -a openIM123 --no-auth-warning KEYS "bf:*"
# 预期看到：
#   bf:imAdmin:127.0.0.1    ← 账号:IP 维度
#   bf:ip:127.0.0.1         ← IP 全局维度
#   bf:acc:imAdmin           ← 账号全局维度（防 IP 轮换）

# imAdmin 从另一个 IP 应该仍可登录（前两层不互锁）
# 但累计 50 次失败后，所有 IP 都无法登录（第三层生效）
```

### 三维度防护矩阵

| 维度 | Redis Key | 阈值 | 锁定时长 | 防护目标 |
|------|-----------|------|---------|---------|
| 账号+IP | `bf:{account}:{ip}` | 5次 | 5分钟 | 单 IP 爆破单账号 |
| IP 全局 | `bf:ip:{ip}` | 20次 | 15分钟 | 单 IP 扫号 |
| 账号全局 | `bf:acc:{account}` | 50次 | 30分钟 | 分布式 IP 轮换 |

---

## 回顾 Checklist

压测结束后，按此清单逐一确认：

- [ ] p95 < 500ms（API），p95 < 2s（登录）
- [ ] 错误率 < 5%
- [ ] RPS > 100（最低可接受）
- [ ] `rate_limit_429` 计数符合预期（非零说明限流在保护系统）
- [ ] `docker stats` 各容器 CPU < 80%，MEM < 80%
- [ ] Redis `connected_clients` < 50% maxclients
- [ ] Redis `evicted_keys` = 0
- [ ] MongoDB 无 > 2s 慢查询
- [ ] 无 goroutine 泄露（total < 500）
- [ ] 双维度 bf key 结构正确（`bf:{account}:{ip}` + `bf:ip:{ip}` + `bf:acc:{account}`）
