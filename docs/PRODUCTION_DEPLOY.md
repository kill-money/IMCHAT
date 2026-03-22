# ============================================================
# OpenIM 生产部署模板 — Kubernetes / Railway
# ============================================================
# 本文件包含：
#   1. Kubernetes 部署清单（含安全加固配置）
#   2. Railway 部署配置
#   3. "哪个服务先崩" — 压力序列图 + 自愈策略
# ============================================================

## 目录
1. [服务崩溃顺序图](#1-服务崩溃顺序图)
2. [Kubernetes 部署](#2-kubernetes-部署)
3. [Railway 部署](#3-railway-部署)
4. [安全配置 Checklist](#4-安全配置-checklist)

---

## 1. 服务崩溃顺序图

### 1.1 压力传导链

```
 k6 / 真实用户流量
       │
       ▼
 ┌──────────┐
 │  Nginx   │ ← 第一道墙：连接数限制 + rate_limit
 └────┬─────┘
      │ proxy_pass
      ▼
 ┌──────────────────┐
 │  openim-chat     │ ← 第二道墙：Go 层三维度限流
 │  (Go, Gin)       │
 │  CPU + goroutine │
 └─┬──────┬────┬────┘
   │      │    │
   ▼      ▼    ▼
 Redis  Mongo  Kafka
```

### 1.2 谁先崩？（典型压力递增序列）

```
负载递增 ──────────────────────────────────────────────►

VU=50        VU=200       VU=500        VU=1000       VU=2000
  │              │            │              │              │
  │              │            │              │              │
  ▼              ▼            ▼              ▼              ▼
 正常          正常      ┌─────────┐   ┌──────────┐  ┌──────────┐
                         │ Redis   │   │ Go CPU   │  │ MongoDB  │
                         │ 连接池  │   │ 饱和     │  │ 连接耗尽 │
                         │ 告警    │   │ p95>2s   │  │ OOM      │
                         └─────────┘   └──────────┘  └──────────┘
                              ①             ②             ③
```

**崩溃顺序（从最可能到最不可能）：**

| 顺序 | 服务 | 典型阈值 | 症状 | 自愈方式 |
|------|------|---------|------|---------|
| ① | **Redis** | connected_clients > 500 | 登录/限流全部超时 | 增大 maxclients + 连接池 |
| ② | **Go (openim-chat)** | CPU > 200%, goroutine > 5000 | 所有 API p95 飙升 | HPA 水平扩容 |
| ③ | **MongoDB** | connections > 300, slowop > 5s | 搜索/日志接口超时 | 加索引 + 连接池扩容 |
| ④ | **Kafka** | consumer lag > 10000 | 消息延迟，不影响 API | 增加 partition |
| ⑤ | **Nginx** | worker_connections 耗尽 | 502 Bad Gateway | 增大 worker_connections |

### 1.3 决策树

```
所有接口同时慢？
  ├─ 是 → docker stats 看 CPU
  │     ├─ openim-chat CPU > 150% → Go 瓶颈（扩容/优化）
  │     └─ 所有容器 CPU 正常 → 网络/Nginx 瓶颈
  │
  └─ 否 → 哪些接口慢？
        ├─ 仅登录 → Redis（bf key 操作阻塞）
        ├─ 仅搜索/列表 → MongoDB（慢查询）
        ├─ 仅消息 → Kafka（消费积压）
        └─ 仅 WebSocket → openim-server（非 chat 服务）
```

---

## 2. Kubernetes 部署

### 2.1 Namespace + Secrets

```yaml
# k8s/00-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: openim
---
# k8s/01-secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: openim-secrets
  namespace: openim
type: Opaque
stringData:
  REDIS_PASSWORD: "your-strong-redis-password"
  MONGO_PASSWORD: "your-strong-mongo-password"
  OPENIM_SECRET: "your-jwt-secret-min-32-chars-long"
  MINIO_ACCESS_KEY: "your-minio-access-key"
  MINIO_SECRET_KEY: "your-minio-secret-key"
```

### 2.2 Redis (StatefulSet)

```yaml
# k8s/10-redis.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  namespace: openim
spec:
  serviceName: redis
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:7.0-alpine
        ports:
        - containerPort: 6379
        command:
        - redis-server
        - --requirepass
        - $(REDIS_PASSWORD)
        - --appendonly
        - "yes"
        - --maxclients
        - "10000"
        - --maxmemory
        - "512mb"
        - --maxmemory-policy
        - allkeys-lru
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: openim-secrets
              key: REDIS_PASSWORD
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: "1"
            memory: 512Mi
        livenessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 10
        readinessProbe:
          exec:
            command: ["redis-cli", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: redis-data
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 5Gi
---
apiVersion: v1
kind: Service
metadata:
  name: redis
  namespace: openim
spec:
  selector:
    app: redis
  ports:
  - port: 6379
  clusterIP: None
```

### 2.3 MongoDB (StatefulSet)

```yaml
# k8s/11-mongo.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mongo
  namespace: openim
spec:
  serviceName: mongo
  replicas: 1
  selector:
    matchLabels:
      app: mongo
  template:
    metadata:
      labels:
        app: mongo
    spec:
      containers:
      - name: mongo
        image: mongo:7.0
        ports:
        - containerPort: 27017
        args:
        - --wiredTigerCacheSizeGB
        - "1"
        - --auth
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: root
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: openim-secrets
              key: MONGO_PASSWORD
        resources:
          requests:
            cpu: 200m
            memory: 512Mi
          limits:
            cpu: "2"
            memory: 2Gi
        volumeMounts:
        - name: mongo-data
          mountPath: /data/db
  volumeClaimTemplates:
  - metadata:
      name: mongo-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 20Gi
---
apiVersion: v1
kind: Service
metadata:
  name: mongo
  namespace: openim
spec:
  selector:
    app: mongo
  ports:
  - port: 27017
  clusterIP: None
```

### 2.4 openim-chat (Deployment + HPA)

```yaml
# k8s/20-openim-chat.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: openim-chat
  namespace: openim
spec:
  replicas: 2
  selector:
    matchLabels:
      app: openim-chat
  template:
    metadata:
      labels:
        app: openim-chat
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
      containers:
      - name: openim-chat
        image: your-registry/openim-chat:latest
        ports:
        - name: chat-api
          containerPort: 10008
        - name: admin-api
          containerPort: 10009
        env:
        - name: CHATENV_MONGODB_ADDRESS
          value: "mongo:27017"
        - name: CHATENV_MONGODB_USERNAME
          value: "openIM"
        - name: CHATENV_MONGODB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: openim-secrets
              key: MONGO_PASSWORD
        - name: CHATENV_REDIS_ADDRESS
          value: "redis:6379"
        - name: CHATENV_REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: openim-secrets
              key: REDIS_PASSWORD
        - name: CHATENV_SHARE_OPENIM_SECRET
          valueFrom:
            secretKeyRef:
              name: openim-secrets
              key: OPENIM_SECRET
        - name: CHATENV_LOG_ISSTDOUT
          value: "true"
        - name: CHATENV_LOG_REMAINLOGLEVEL
          value: "4"
        - name: GOMAXPROCS
          value: "2"
        resources:
          requests:
            cpu: 200m
            memory: 256Mi
          limits:
            cpu: "2"
            memory: 1Gi
        livenessProbe:
          httpGet:
            path: /account/login
            port: admin-api
          initialDelaySeconds: 15
          periodSeconds: 20
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /account/login
            port: admin-api
          initialDelaySeconds: 10
          periodSeconds: 10
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop: ["ALL"]
---
apiVersion: v1
kind: Service
metadata:
  name: openim-chat
  namespace: openim
spec:
  selector:
    app: openim-chat
  ports:
  - name: chat-api
    port: 10008
    targetPort: 10008
  - name: admin-api
    port: 10009
    targetPort: 10009
---
# HPA: 自动扩容（CPU > 70% 触发）
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: openim-chat-hpa
  namespace: openim
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: openim-chat
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30
      policies:
      - type: Pods
        value: 2
        periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Pods
        value: 1
        periodSeconds: 120
```

### 2.5 Ingress (含安全 headers)

```yaml
# k8s/30-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: openim-ingress
  namespace: openim
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    # 安全 Headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Frame-Options "DENY" always;
      add_header X-Content-Type-Options "nosniff" always;
      add_header X-XSS-Protection "1; mode=block" always;
      add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
      add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    # 全局限流: 10 rps per IP
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "20"
    # cert-manager TLS
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - im.example.com
    secretName: openim-tls
  rules:
  - host: im.example.com
    http:
      paths:
      - path: /admin_api/
        pathType: Prefix
        backend:
          service:
            name: openim-chat
            port:
              number: 10009
      - path: /chat_api/
        pathType: Prefix
        backend:
          service:
            name: openim-chat
            port:
              number: 10008
      - path: /im_api/
        pathType: Prefix
        backend:
          service:
            name: openim-server
            port:
              number: 10002
```

### 2.6 NetworkPolicy (最小权限)

```yaml
# k8s/31-networkpolicy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: openim-chat-netpol
  namespace: openim
spec:
  podSelector:
    matchLabels:
      app: openim-chat
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # 仅允许 Ingress controller 访问
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: ingress-nginx
    ports:
    - port: 10008
    - port: 10009
  egress:
  # 允许访问 Redis
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - port: 6379
  # 允许访问 MongoDB
  - to:
    - podSelector:
        matchLabels:
          app: mongo
    ports:
    - port: 27017
  # 允许访问 openim-server
  - to:
    - podSelector:
        matchLabels:
          app: openim-server
    ports:
    - port: 10002
  # 允许 DNS
  - to:
    - namespaceSelector: {}
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
```

### 2.7 PodDisruptionBudget

```yaml
# k8s/32-pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: openim-chat-pdb
  namespace: openim
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: openim-chat
```

---

## 3. Railway 部署

### 3.1 railway.toml

```toml
# openim-chat service
[build]
builder = "dockerfile"
dockerfilePath = "openim-chat/Dockerfile"

[deploy]
healthcheckPath = "/account/login"
healthcheckTimeout = 30
numReplicas = 2
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 10

[[services]]
name = "openim-chat"
internalPort = 10008

[[services]]
name = "openim-admin"
internalPort = 10009
```

### 3.2 Railway 环境变量

在 Railway Dashboard → Variables 中设置：

```bash
# Redis (Railway 插件自动提供，或手动配置)
CHATENV_REDIS_ADDRESS=redis.railway.internal:6379
CHATENV_REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}

# MongoDB (Railway 插件)
CHATENV_MONGODB_ADDRESS=mongo.railway.internal:27017
CHATENV_MONGODB_USERNAME=openIM
CHATENV_MONGODB_PASSWORD=${{MongoDB.MONGO_PASSWORD}}

# Core
CHATENV_SHARE_OPENIM_SECRET=${{shared.OPENIM_SECRET}}
CHATENV_LOG_ISSTDOUT=true
CHATENV_LOG_REMAINLOGLEVEL=4

# Go tuning
GOMAXPROCS=2
```

### 3.3 Railway 注意事项

1. **无状态要求**：openim-chat 必须连接外部 Redis，不能用进程内内存限流（多副本场景下会不一致）
2. **健康检查**：Railway 内置 healthcheck，设置 `/account/login` POST 端点
3. **域名**：Railway 自动分配 `*.up.railway.app`，生产环境绑定自定义域名 + Cloudflare
4. **TLS**：Railway 自动提供 HTTPS，无需额外配置
5. **日志**：Railway 自带日志面板，设置 `CHATENV_LOG_ISSTDOUT=true`

---

## 4. 安全配置 Checklist

### 4.1 生产必须项

- [ ] 所有密码已从默认值更换（Redis / Mongo / JWT Secret / Admin 密码）
- [ ] HTTPS 已启用（cert-manager / Railway auto / Cloudflare）
- [ ] 安全 Headers 已配置（HSTS / CSP / X-Frame-Options / nosniff）
- [ ] 三维度限流已验证（bf:account:ip + bf:ip + bf:acc:account）
- [ ] NetworkPolicy 已应用（k8s）
- [ ] Secrets 使用 k8s Secret / Railway Variables（不在镜像内）
- [ ] 容器以非 root 运行（runAsNonRoot: true）
- [ ] CPU/Memory 资源限制已设置
- [ ] HPA 已配置（CPU > 70% 自动扩容）
- [ ] PDB 已配置（滚动更新不中断服务）

### 4.2 生产推荐项

- [ ] Prometheus + Grafana 监控已部署
- [ ] AlertManager 告警已配置（CPU / Memory / 5xx rate）
- [ ] 日志集中收集（EFK / Loki）
- [ ] MongoDB 生产索引已创建（见 LOAD_TEST_GUIDE.md）
- [ ] Redis AOF 持久化已启用
- [ ] 定期备份策略（MongoDB dump + Redis RDB）
- [ ] 2FA/TOTP 已启用（管理员账号）
- [ ] 审计日志定期归档

### 4.3 容灾

| 场景 | 影响 | 自愈 |
|------|------|------|
| openim-chat Pod 崩溃 | API 短暂不可用 | k8s 自动重启 + HPA |
| Redis 不可用 | 登录/限流失败 | Go 自动降级到内存限流 |
| MongoDB 不可用 | 数据操作失败 | 告警 + 人工介入 |
| Kafka 不可用 | 消息延迟 | openim-server 缓冲 → 恢复后补发 |
