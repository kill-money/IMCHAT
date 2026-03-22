# ============================================================
# OpenIM 一键压测 + 自动瓶颈报告 (Windows PowerShell)
# ============================================================
# 用法:
#   .\scripts\Auto-LoadTest.ps1                      # 默认 200 VU
#   .\scripts\Auto-LoadTest.ps1 -VUs 500             # 自定义
#   .\scripts\Auto-LoadTest.ps1 -Duration 120s       # 自定义时长
#
# 前置条件: k6, docker
# ============================================================

param(
    [int]$VUs = 200,
    [string]$Duration = "90s",
    [string]$AdminApi = "http://localhost:10009",
    [string]$ImApi = "http://localhost:10002"
)

$ErrorActionPreference = "Continue"
$ts = Get-Date -Format "yyyyMMdd_HHmmss"
$outDir = "loadtest_report_$ts"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "============================================" -ForegroundColor Cyan
Write-Host " OpenIM 一键压测 + 瓶颈报告" -ForegroundColor Cyan
Write-Host " VUs: $VUs | Duration: $Duration" -ForegroundColor Cyan
Write-Host " Output: $outDir\" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ── Phase 1: 基线采集 ───────────────────────────────────────
Write-Host "`n[Phase 1/4] 采集基线..." -ForegroundColor Yellow
docker stats --no-stream --format "{{.Name}}`t{{.CPUPerc}}`t{{.MemUsage}}`t{{.NetIO}}" 2>$null | Out-File "$outDir\baseline_docker_stats.txt"

$redisBaseline = @()
$redisBaseline += docker exec redis redis-cli -a openIM123 --no-auth-warning INFO clients 2>$null | Select-String "connected_clients"
$redisBaseline += docker exec redis redis-cli -a openIM123 --no-auth-warning INFO memory 2>$null | Select-String "used_memory_human"
$redisBaseline += docker exec redis redis-cli -a openIM123 --no-auth-warning INFO stats 2>$null | Select-String "instantaneous_ops|total_commands_processed"
$redisBaseline | Out-File "$outDir\baseline_redis.txt"

docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet `
  --eval 'const s=db.serverStatus(); print(JSON.stringify({connections: s.connections.current, opcounters: s.opcounters}))' `
  2>$null | Out-File "$outDir\baseline_mongo.txt"

Write-Host "[Phase 1/4] 基线采集完成" -ForegroundColor Green

# ── Phase 2: k6 压测 ────────────────────────────────────────
Write-Host "`n[Phase 2/4] 开始 k6 压测 (VUs=$VUs, Duration=$Duration)..." -ForegroundColor Yellow

$k6Args = @(
    "run",
    "--vus", "$VUs",
    "--duration", "$Duration",
    "--out", "json=$outDir\k6_results.json",
    "--summary-export=$outDir\k6_summary.json",
    "-e", "ADMIN_API=$AdminApi",
    "-e", "IM_API=$ImApi",
    "scripts\k6_load_test.js"
)
& k6 @k6Args 2>&1 | Tee-Object -FilePath "$outDir\k6_stdout.txt"

Write-Host "[Phase 2/4] k6 压测完成" -ForegroundColor Green

# ── Phase 3: 压测后快照 ─────────────────────────────────────
Write-Host "`n[Phase 3/4] 压测后快照..." -ForegroundColor Yellow
docker stats --no-stream --format "{{.Name}}`t{{.CPUPerc}}`t{{.MemUsage}}`t{{.NetIO}}" 2>$null | Out-File "$outDir\after_docker_stats.txt"

$redisAfter = @()
$redisAfter += docker exec redis redis-cli -a openIM123 --no-auth-warning INFO clients 2>$null | Select-String "connected_clients"
$redisAfter += docker exec redis redis-cli -a openIM123 --no-auth-warning INFO memory 2>$null | Select-String "used_memory_human"
$redisAfter += docker exec redis redis-cli -a openIM123 --no-auth-warning INFO stats 2>$null | Select-String "instantaneous_ops|total_commands_processed"
$redisAfter += "--- SLOWLOG ---"
$redisAfter += docker exec redis redis-cli -a openIM123 --no-auth-warning SLOWLOG GET 5 2>$null
$redisAfter | Out-File "$outDir\after_redis.txt"

docker exec mongo mongosh -u openIM -p openIM123 --authenticationDatabase admin --quiet `
  --eval 'const s=db.serverStatus(); print(JSON.stringify({connections: s.connections.current, opcounters: s.opcounters}))' `
  2>$null | Out-File "$outDir\after_mongo.txt"

docker exec redis redis-cli -a openIM123 --no-auth-warning --scan --pattern "bf:*" 2>$null | Out-File "$outDir\bf_keys.txt"

Write-Host "[Phase 3/4] 快照采集完成" -ForegroundColor Green

# ── Phase 4: 生成报告 ───────────────────────────────────────
Write-Host "`n[Phase 4/4] 生成瓶颈报告..." -ForegroundColor Yellow

$report = @()
$report += "# 压测瓶颈报告"
$report += ""
$report += "**生成时间**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "**VUs**: $VUs | **Duration**: $Duration"
$report += ""

# k6 summary
$report += "## k6 核心指标"
$report += ""

if (Test-Path "$outDir\k6_summary.json") {
    try {
        $summary = Get-Content "$outDir\k6_summary.json" -Raw | ConvertFrom-Json
        $p95 = [math]::Round($summary.metrics.http_req_duration.values.'p(95)', 1)
        $p99 = [math]::Round($summary.metrics.http_req_duration.values.'p(99)', 1)
        $avg = [math]::Round($summary.metrics.http_req_duration.values.avg, 1)
        $failRate = [math]::Round($summary.metrics.http_req_failed.values.rate * 100, 2)
        $reqs = $summary.metrics.http_reqs.values.count
        $rps = [math]::Round($summary.metrics.http_reqs.values.rate, 1)

        $p95Status = if ($p95 -lt 500) { "pass" } else { "FAIL" }
        $p99Status = if ($p99 -lt 2000) { "pass" } else { "FAIL" }
        $failStatus = if ($failRate -lt 5) { "pass" } else { "FAIL" }

        $report += "| 指标 | 值 | 阈值 | 状态 |"
        $report += "|------|-----|------|------|"
        $report += "| p95 | ${p95}ms | <500ms | $p95Status |"
        $report += "| p99 | ${p99}ms | <2000ms | $p99Status |"
        $report += "| avg | ${avg}ms | - | - |"
        $report += "| 失败率 | ${failRate}% | <5% | $failStatus |"
        $report += "| 总请求 | $reqs | - | - |"
        $report += "| RPS | $rps | >100 | - |"
    } catch {
        $report += "_(k6_summary.json 解析失败，请手动查看 k6_stdout.txt)_"
    }
} else {
    $report += "_(k6_summary.json 不存在)_"
}
$report += ""

# Docker stats diff
$report += "## Docker Stats 对比 (Before -> After)"
$report += ""
$report += '```'
$report += "=== BEFORE ==="
$report += (Get-Content "$outDir\baseline_docker_stats.txt" -ErrorAction SilentlyContinue)
$report += ""
$report += "=== AFTER ==="
$report += (Get-Content "$outDir\after_docker_stats.txt" -ErrorAction SilentlyContinue)
$report += '```'
$report += ""

# Redis diff
$report += "## Redis (Before -> After)"
$report += ""
$report += '```'
$report += "=== BEFORE ==="
$report += (Get-Content "$outDir\baseline_redis.txt" -ErrorAction SilentlyContinue)
$report += ""
$report += "=== AFTER ==="
$report += (Get-Content "$outDir\after_redis.txt" -ErrorAction SilentlyContinue)
$report += '```'
$report += ""

# Mongo diff
$report += "## MongoDB (Before -> After)"
$report += ""
$report += '```'
$report += "=== BEFORE ==="
$report += (Get-Content "$outDir\baseline_mongo.txt" -ErrorAction SilentlyContinue)
$report += ""
$report += "=== AFTER ==="
$report += (Get-Content "$outDir\after_mongo.txt" -ErrorAction SilentlyContinue)
$report += '```'
$report += ""

# BF keys
$report += "## BF Keys (压测后残留)"
$report += ""
$report += '```'
$report += (Get-Content "$outDir\bf_keys.txt" -ErrorAction SilentlyContinue)
$report += '```'
$report += ""

# Auto bottleneck
$report += "## 自动瓶颈判定"
$report += ""
$bottleneckFound = $false
$afterStats = Get-Content "$outDir\after_docker_stats.txt" -ErrorAction SilentlyContinue
foreach ($line in $afterStats) {
    if ($line -match "(\S+)\s+(\d+\.?\d*)%") {
        $name = $matches[1]
        $cpu = [double]$matches[2]
        if ($cpu -gt 150) {
            $report += "- FAIL **$name** CPU=${cpu}% (>150%) -> **CPU 瓶颈**"
            $bottleneckFound = $true
        }
    }
}
if (-not $bottleneckFound) {
    $report += "- pass 未发现明显瓶颈（所有容器 CPU <150%）"
}
$report += ""
$report += "---"
$report += "_详细数据见同目录下 JSON/TXT 文件_"

$report | Out-File "$outDir\bottleneck_report.md" -Encoding UTF8

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " 报告已生成: $outDir\bottleneck_report.md" -ForegroundColor Green
Write-Host " 原始数据:   $outDir\" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
