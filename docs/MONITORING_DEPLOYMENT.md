# ============================================================
# OpenIM 监控部署方案：Prometheus + Grafana + Alertmanager
# ============================================================
#
# 本文档描述如何为 OpenIM 安全加固后的系统部署完整监控方案。
# 基于已有 docker-compose.yaml 中的 profile "m" 服务。
#
# 目录：
#   1. 架构概览
#   2. 一键启动
#   3. Prometheus 扩展采集（openim-chat 安全指标）
#   4. Grafana Dashboard 导入
#   5. 告警规则
#   6. 自定义安全指标（Go 端埋点建议）
#   7. 运维 Checklist
# ============================================================

## 1. 架构概览

```
  ┌──────────────┐    scrape    ┌───────────────────────┐
  │  Prometheus  │◄────────────│  openim-server :12002  │ (内置 /metrics)
  │  :19090      │◄────────────│  openim-chat   :10009  │ (需增加 /metrics)
  │              │◄────────────│  node-exporter :19100  │
  └──────┬───────┘             └───────────────────────┘
         │ query
  ┌──────▼───────┐
  │   Grafana    │   Dashboard
  │   :13000     │   ← 浏览器访问
  └──────────────┘
         │
  ┌──────▼───────┐
  │ Alertmanager │   → 邮件 / 企微 / 钉钉
  │   :19093     │
  └──────────────┘
```

## 2. 一键启动

docker-compose.yaml 已内置 prometheus / grafana / alertmanager / node-exporter，
使用 profile `m` 启动：

```bash
cd d:\procket\IMCHAT\openim-docker

# 启动监控全家桶（附加到现有服务）
docker compose -f docker-compose.yaml -f docker-compose.override.yml --profile m up -d

# 验证
docker ps --filter "name=prometheus|grafana|alertmanager|node-exporter" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

访问地址：
| 服务 | URL | 默认账号 |
|------|-----|---------|
| Grafana | http://YOUR_IP:13000 | admin / admin（首次登录强制改密）|
| Prometheus | http://YOUR_IP:19090 | 无需登录 |
| Alertmanager | http://YOUR_IP:19093 | 无需登录 |

> ⚠️ 生产环境必须限制这些端口只对内网可达（防火墙 / Nginx IP 白名单）

## 3. Prometheus 扩展采集配置

现有 `config/prometheus.yml` 已配置 openim-server 的各 RPC 服务自动发现。
需要额外添加 openim-chat 的采集目标。

在 `config/prometheus.yml` 的 `scrape_configs:` 末尾追加：

```yaml
  # ── openim-chat admin-api 安全指标 ─────────────────────────
  - job_name: openim-chat-admin-api
    static_configs:
      - targets: ["host.docker.internal:10009"]
        labels:
          service: admin-api
    metrics_path: /metrics
    scrape_interval: 15s

  # ── openim-chat chat-api ───────────────────────────────────
  - job_name: openim-chat-chat-api
    static_configs:
      - targets: ["host.docker.internal:10008"]
        labels:
          service: chat-api
    metrics_path: /metrics
    scrape_interval: 15s

  # ── Redis Exporter (可选) ──────────────────────────────────
  # 如部署了 redis_exporter 容器：
  # - job_name: redis
  #   static_configs:
  #     - targets: ["redis-exporter:9121"]

  # ── MongoDB Exporter (可选) ────────────────────────────────
  # - job_name: mongodb
  #   static_configs:
  #     - targets: ["mongodb-exporter:9216"]
```

> 注意：由于 prometheus 使用 `network_mode: host`，可直接访问宿主机端口。
> Linux 用 `127.0.0.1:10009`，Windows/Mac Docker Desktop 用 `host.docker.internal:10009`。

## 4. Grafana Dashboard 导入

### 4.1 推荐 Dashboard

| ID | 名称 | 用途 |
|----|------|------|
| 1860 | Node Exporter Full | 主机 CPU / 内存 / 磁盘 / 网络 |
| 763 | Redis Dashboard | Redis 连接数 / 命中率 / 内存 |
| 2583 | MongoDB | MongoDB ops / 连接 / 延迟 |
| 自定义 | OpenIM Security | 安全加固专用（见下方） |

### 4.2 导入步骤

1. 打开 Grafana → 左侧 `+` → `Import`
2. 输入 Dashboard ID → `Load`
3. 选择数据源 `Prometheus` → `Import`

### 4.3 OpenIM 安全 Dashboard JSON（自定义）

在 Grafana UI 导入以下 JSON 或创建新面板：

**推荐面板组合:**

```
Row: 系统概览
  ├── 当前在线用户数     → up{job="openimserver-openim-msggateway"}
  ├── API QPS (5m avg)  → rate(http_server_requests_total[5m])
  └── 错误率             → rate(http_server_errors_total[5m]) / rate(http_server_requests_total[5m])

Row: 安全指标
  ├── 登录失败次数/分钟   → rate(admin_login_failures_total[1m])
  ├── 429 限流触发/分钟   → rate(rate_limit_rejections_total[1m])
  ├── 2FA 验证次数       → rate(totp_verify_total[5m])
  ├── SensitiveVerify    → rate(sensitive_verify_total[5m])
  └── 审计日志写入量/5m  → rate(security_log_writes_total[5m])

Row: 风控
  ├── 高风险用户数       → admin_risk_high_score_users
  ├── 暴力破解锁定数     → admin_brute_force_locks_active
  └── 异常 IP 触发数/h   → increase(risk_ip_events_total[1h])

Row: 基础设施
  ├── Redis 延迟 p99     → histogram_quantile(0.99, rate(redis_command_duration_seconds_bucket[5m]))
  ├── MongoDB ops/s      → rate(mongodb_op_counters_total[5m])
  └── Kafka consumer lag → kafka_consumer_group_lag
```

## 5. 告警规则

在 `config/instance-down-rules.yml` 追加安全相关告警：

```yaml
  # ── 安全加固专项告警 ───────────────────────────────────────
  - name: security_alerts
    rules:
      # 登录失败激增（可能正在被暴力破解）
      - alert: LoginFailureSpike
        expr: increase(admin_login_failures_total[5m]) > 50
        for: 2m
        labels:
          severity: warning
        annotations:
          summary: "管理后台登录失败激增"
          description: "5分钟内登录失败 {{ $value }} 次，可能遭受暴力破解攻击"

      # 限流大量触发（可能 DDoS）
      - alert: RateLimitStorm
        expr: increase(rate_limit_rejections_total[5m]) > 200
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "限流触发异常频繁"
          description: "5分钟内被限流 {{ $value }} 次，IP: {{ $labels.client_ip }}"

      # 审计日志写入停止（pipeline 故障）
      - alert: AuditLogWriteStopped
        expr: increase(security_log_writes_total[10m]) == 0
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "审计日志写入中断"
          description: "10分钟内无审计日志写入，安全审计管道可能故障"

      # API 延迟过高
      - alert: APIHighLatency
        expr: histogram_quantile(0.95, rate(http_server_request_duration_seconds_bucket[5m])) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "API p95 延迟超过 2 秒"
          description: "{{ $labels.handler }} p95 = {{ $value }}s"

      # 容器重启
      - alert: ContainerRestarting
        expr: increase(container_restart_count[10m]) > 2
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "容器频繁重启: {{ $labels.container_name }}"
```

## 6. Go 端埋点建议（openim-chat）

在 openim-chat 中暴露 `/metrics` 端点所需的指标注册：

```go
// pkg/metrics/prometheus.go
package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    LoginAttempts = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "admin_login_attempts_total",
        Help: "管理员登录尝试次数",
    }, []string{"result"}) // result: "success", "fail", "locked", "2fa_required"

    RateLimitRejections = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "rate_limit_rejections_total",
        Help: "限流拒绝次数",
    }, []string{"type", "client_ip"}) // type: "auth", "api", "user"

    SecurityLogWrites = promauto.NewCounter(prometheus.CounterOpts{
        Name: "security_log_writes_total",
        Help: "安全审计日志写入次数",
    })

    TOTPVerifications = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "totp_verify_total",
        Help: "TOTP 验证次数",
    }, []string{"result"}) // "success", "fail", "replay"

    SensitiveVerify = promauto.NewCounterVec(prometheus.CounterOpts{
        Name: "sensitive_verify_total",
        Help: "敏感操作验证次数",
    }, []string{"action", "result"}) // action: "change_password" etc.

    ActiveSessions = promauto.NewGauge(prometheus.GaugeOpts{
        Name: "admin_active_sessions",
        Help: "当前活跃管理员会话数",
    })

    BruteForceLocks = promauto.NewGauge(prometheus.GaugeOpts{
        Name: "admin_brute_force_locks_active",
        Help: "当前暴力破解锁定数",
    })
)
```

在 Gin router 中注册 metrics handler：

```go
import "github.com/prometheus/client_golang/prometheus/promhttp"

engine.GET("/metrics", gin.WrapH(promhttp.Handler()))
```

## 7. 运维 Checklist

- [ ] `docker compose --profile m up -d` 后确认 4 个监控容器全部 running
- [ ] Prometheus Targets 页面 (http://IP:19090/targets) 全部 UP
- [ ] Grafana 数据源配置 Prometheus URL = `http://127.0.0.1:19090`
- [ ] 导入 Node Exporter Dashboard (#1860)
- [ ] 配置邮件告警：编辑 `config/alertmanager.yml` 替换 smtp 信息
- [ ] Grafana 改默认密码
- [ ] 生产环境：Grafana 关闭匿名访问 (`GF_AUTH_ANONYMOUS_ENABLED=false`)
- [ ] 防火墙限制 19090 / 13000 / 19093 仅内网可达
- [ ] 配置 Grafana HTTPS（通过 Nginx 反向代理）
