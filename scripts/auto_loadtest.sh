#!/bin/bash
# ============================================================
# OpenIM 一键压测 + 自动瓶颈报告
# ============================================================
# 用法:
#   bash scripts/auto_loadtest.sh                    # 默认 200 VU
#   bash scripts/auto_loadtest.sh --vus 500          # 自定义 VU
#   bash scripts/auto_loadtest.sh --duration 120s    # 自定义时长
#
# 前置条件: k6, docker, jq
# ============================================================

set -euo pipefail

# ── 参数解析 ────────────────────────────────────────────────
VUS=${VUS:-200}
DURATION=${DURATION:-"90s"}
ADMIN_API=${ADMIN_API:-"http://localhost:10009"}
IM_API=${IM_API:-"http://localhost:10002"}
OUTDIR="loadtest_report_$(date +%Y%m%d_%H%M%S)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --vus) VUS="$2"; shift 2 ;;
    --duration) DURATION="$2"; shift 2 ;;
    --admin-api) ADMIN_API="$2"; shift 2 ;;
    --im-api) IM_API="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

mkdir -p "$OUTDIR"
REPORT="$OUTDIR/bottleneck_report.md"

echo "============================================"
echo " OpenIM 一键压测 + 瓶颈报告"
echo " VUs: $VUS | Duration: $DURATION"
echo " Output: $OUTDIR/"
echo "============================================"

# ── Phase 1: 压测前基线 ─────────────────────────────────────
echo ""
echo "[Phase 1/4] 采集基线..."
docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > "$OUTDIR/baseline_docker_stats.txt" 2>/dev/null

# Redis baseline
{
  docker exec redis redis-cli -a openIM123 --no-auth-warning INFO clients 2>/dev/null | grep connected_clients || true
  docker exec redis redis-cli -a openIM123 --no-auth-warning INFO memory 2>/dev/null | grep used_memory_human || true
  docker exec redis redis-cli -a openIM123 --no-auth-warning INFO stats 2>/dev/null | grep -E "instantaneous_ops|total_commands_processed" || true
} > "$OUTDIR/baseline_redis.txt"

# Mongo baseline
docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet \
  --eval 'const s=db.serverStatus(); print(JSON.stringify({connections: s.connections.current, opcounters: s.opcounters}))' \
  > "$OUTDIR/baseline_mongo.txt" 2>/dev/null || true

echo "[Phase 1/4] 基线采集完成"

# ── Phase 2: 执行 k6 压测 ───────────────────────────────────
echo ""
echo "[Phase 2/4] 开始 k6 压测 (VUs=$VUS, Duration=$DURATION)..."

k6 run \
  --vus "$VUS" \
  --duration "$DURATION" \
  --out "json=$OUTDIR/k6_results.json" \
  --summary-export="$OUTDIR/k6_summary.json" \
  -e "ADMIN_API=$ADMIN_API" \
  -e "IM_API=$IM_API" \
  scripts/k6_load_test.js 2>&1 | tee "$OUTDIR/k6_stdout.txt"

echo "[Phase 2/4] k6 压测完成"

# ── Phase 3: 压测后快照 ─────────────────────────────────────
echo ""
echo "[Phase 3/4] 采集压测后快照..."
docker stats --no-stream --format "{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" > "$OUTDIR/after_docker_stats.txt" 2>/dev/null

{
  docker exec redis redis-cli -a openIM123 --no-auth-warning INFO clients 2>/dev/null | grep connected_clients || true
  docker exec redis redis-cli -a openIM123 --no-auth-warning INFO memory 2>/dev/null | grep used_memory_human || true
  docker exec redis redis-cli -a openIM123 --no-auth-warning INFO stats 2>/dev/null | grep -E "instantaneous_ops|total_commands_processed" || true
  echo "--- SLOWLOG ---"
  docker exec redis redis-cli -a openIM123 --no-auth-warning SLOWLOG GET 5 2>/dev/null || true
} > "$OUTDIR/after_redis.txt"

docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet \
  --eval 'const s=db.serverStatus(); print(JSON.stringify({connections: s.connections.current, opcounters: s.opcounters}))' \
  > "$OUTDIR/after_mongo.txt" 2>/dev/null || true

# BF keys
docker exec redis redis-cli -a openIM123 --no-auth-warning --scan --pattern "bf:*" 2>/dev/null > "$OUTDIR/bf_keys.txt" || true

echo "[Phase 3/4] 快照采集完成"

# ── Phase 4: 自动分析 + 生成报告 ────────────────────────────
echo ""
echo "[Phase 4/4] 生成瓶颈报告..."

cat > "$REPORT" <<'HEADER'
# 压测瓶颈报告

HEADER

echo "**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')" >> "$REPORT"
echo "**VUs**: $VUS | **Duration**: $DURATION" >> "$REPORT"
echo "" >> "$REPORT"

# ── k6 摘要 ──
echo "## k6 核心指标" >> "$REPORT"
echo "" >> "$REPORT"

if command -v jq &>/dev/null && [ -f "$OUTDIR/k6_summary.json" ]; then
  P95=$(jq -r '.metrics.http_req_duration.values["p(95)"] // "N/A"' "$OUTDIR/k6_summary.json")
  P99=$(jq -r '.metrics.http_req_duration.values["p(99)"] // "N/A"' "$OUTDIR/k6_summary.json")
  AVG=$(jq -r '.metrics.http_req_duration.values.avg // "N/A"' "$OUTDIR/k6_summary.json")
  FAIL_RATE=$(jq -r '.metrics.http_req_failed.values.rate // "N/A"' "$OUTDIR/k6_summary.json")
  REQS=$(jq -r '.metrics.http_reqs.values.count // "N/A"' "$OUTDIR/k6_summary.json")
  RPS=$(jq -r '.metrics.http_reqs.values.rate // "N/A"' "$OUTDIR/k6_summary.json")

  echo "| 指标 | 值 | 阈值 | 状态 |" >> "$REPORT"
  echo "|------|-----|------|------|" >> "$REPORT"

  # p95 check
  P95_INT=${P95%.*}
  if [ "${P95_INT:-0}" -lt 500 ] 2>/dev/null; then P95_STATUS="✅"; else P95_STATUS="❌"; fi
  echo "| p95 | ${P95}ms | <500ms | $P95_STATUS |" >> "$REPORT"

  # p99 check
  P99_INT=${P99%.*}
  if [ "${P99_INT:-0}" -lt 2000 ] 2>/dev/null; then P99_STATUS="✅"; else P99_STATUS="❌"; fi
  echo "| p99 | ${P99}ms | <2000ms | $P99_STATUS |" >> "$REPORT"

  echo "| avg | ${AVG}ms | - | - |" >> "$REPORT"

  # fail rate check
  FAIL_PCT=$(echo "$FAIL_RATE * 100" | bc 2>/dev/null || echo "N/A")
  echo "| 失败率 | ${FAIL_PCT}% | <5% | - |" >> "$REPORT"
  echo "| 总请求 | $REQS | - | - |" >> "$REPORT"
  echo "| RPS | $RPS | >100 | - |" >> "$REPORT"
else
  echo "_(jq 未安装或 k6_summary.json 不存在，请手动查看 k6_stdout.txt)_" >> "$REPORT"
fi
echo "" >> "$REPORT"

# ── Docker stats 对比 ──
echo "## Docker Stats 对比 (Before → After)" >> "$REPORT"
echo "" >> "$REPORT"
echo '```' >> "$REPORT"
echo "=== BEFORE ===" >> "$REPORT"
cat "$OUTDIR/baseline_docker_stats.txt" >> "$REPORT"
echo "" >> "$REPORT"
echo "=== AFTER ===" >> "$REPORT"
cat "$OUTDIR/after_docker_stats.txt" >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

# ── Redis 对比 ──
echo "## Redis (Before → After)" >> "$REPORT"
echo "" >> "$REPORT"
echo '```' >> "$REPORT"
echo "=== BEFORE ===" >> "$REPORT"
cat "$OUTDIR/baseline_redis.txt" >> "$REPORT"
echo "" >> "$REPORT"
echo "=== AFTER ===" >> "$REPORT"
cat "$OUTDIR/after_redis.txt" >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

# ── MongoDB 对比 ──
echo "## MongoDB (Before → After)" >> "$REPORT"
echo "" >> "$REPORT"
echo '```' >> "$REPORT"
echo "=== BEFORE ===" >> "$REPORT"
cat "$OUTDIR/baseline_mongo.txt" >> "$REPORT"
echo "" >> "$REPORT"
echo "=== AFTER ===" >> "$REPORT"
cat "$OUTDIR/after_mongo.txt" >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

# ── 防爆破 key ──
echo "## BF Keys (压测后残留)" >> "$REPORT"
echo "" >> "$REPORT"
echo '```' >> "$REPORT"
cat "$OUTDIR/bf_keys.txt" >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

# ── 自动瓶颈判定 ──
echo "## 自动瓶颈判定" >> "$REPORT"
echo "" >> "$REPORT"

BOTTLENECK_FOUND=0

# Check each container CPU from after stats
while IFS=$'\t' read -r name cpu mem netio; do
  cpu_num=${cpu%%%}
  if (( $(echo "$cpu_num > 150" | bc -l 2>/dev/null || echo 0) )); then
    echo "- ❌ **$name** CPU=$cpu (>150%) → **CPU 瓶颈**" >> "$REPORT"
    BOTTLENECK_FOUND=1
  fi
done < "$OUTDIR/after_docker_stats.txt" 2>/dev/null || true

if [ "$BOTTLENECK_FOUND" -eq 0 ]; then
  echo "- ✅ 未发现明显瓶颈（所有容器 CPU <150%）" >> "$REPORT"
fi

echo "" >> "$REPORT"
echo "---" >> "$REPORT"
echo "_详细数据见同目录下 JSON/TXT 文件_" >> "$REPORT"

echo ""
echo "============================================"
echo " 报告已生成: $REPORT"
echo " 原始数据:   $OUTDIR/"
echo "============================================"
