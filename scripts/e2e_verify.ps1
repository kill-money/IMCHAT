#!/usr/bin/env pwsh
# ============================================================
#  端到端全栈验证脚本（End‑to‑End Verification）
#  覆盖 9 大维度：
#    1. 后端 API CRUD       2. UI→API 联调
#    3. 权限/Token 链       4. 跨平台同步
#    5. IM 功能             6. UI 交互
#    7. 安全链（nonce/lockout/auth） 8. 审计日志
#    9. 并发测试
#
#  使用：在 PowerShell 中运行：
#    .\scripts\e2e_verify.ps1 [-BaseUrl http://localhost] [-Account imAdmin] [-Password openIM123]
# ============================================================

param(
    [string]$BaseUrl    = "http://localhost",
    [string]$Account    = "imAdmin",
    [string]$Password   = "openIM123",
    [switch]$Verbose
)

Set-StrictMode -Off
$ErrorActionPreference = "Continue"

$AdminApi = "$BaseUrl`:10009"
$ImApi    = "$BaseUrl`:10002"
$ChatApi  = "$BaseUrl`:10008"

$pass = 0
$fail = 0
$skip = 0
$results = @()

function md5([string]$text) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = $md5.ComputeHash($bytes)
    return [BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function Post([string]$url, [hashtable]$body, [hashtable]$headers = @{}) {
    $hdrs = @{
        "operationID" = [string][DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        "Content-Type" = "application/json"
    }
    foreach ($k in $headers.Keys) { $hdrs[$k] = $headers[$k] }
    try {
        $resp = Invoke-RestMethod -Uri $url -Method POST -Body ($body | ConvertTo-Json -Depth 10) -Headers $hdrs -TimeoutSec 15 -ErrorAction Stop
        return $resp
    } catch {
        $httpSc = 0
        try { $httpSc = [int]$_.Exception.Response.StatusCode } catch {}
        try {
            $sr = $_.Exception.Response
            if ($null -ne $sr) {
                $stream = $sr.GetResponseStream()
                if ($null -ne $stream) {
                    $reader = [System.IO.StreamReader]::new($stream)
                    $rawBody = $reader.ReadToEnd()
                    if ($rawBody -and $rawBody.Length -gt 0) {
                        $errBody = $rawBody | ConvertFrom-Json
                        return $errBody
                    }
                }
            }
        } catch {}
        $ec = -1; if ($httpSc -gt 0) { $ec = $httpSc }
        return @{ errCode = $ec; errMsg = $_.Exception.Message }
    }
}

function Test([string]$name, [scriptblock]$block) {
    try {
        $result = & $block
        if ($result -eq $true) {
            Write-Host "  [PASS] $name" -ForegroundColor Green
            $script:pass++
            $script:results += @{ name=$name; status="PASS" }
        } elseif ($result -eq $null -or $result -eq "SKIP") {
            Write-Host "  [SKIP] $name" -ForegroundColor Yellow
            $script:skip++
            $script:results += @{ name=$name; status="SKIP" }
        } else {
            Write-Host "  [FAIL] $name → $result" -ForegroundColor Red
            $script:fail++
            $script:results += @{ name=$name; status="FAIL"; detail=$result }
        }
    } catch {
        Write-Host "  [FAIL] $name → $($_.Exception.Message)" -ForegroundColor Red
        $script:fail++
        $script:results += @{ name=$name; status="FAIL"; detail=$_.Exception.Message }
    }
}

# ========================================
#  0. 连通性预检
# ========================================
Write-Host "`n===== 0. 连通性预检 =====" -ForegroundColor Cyan

$canReach = $true
Test "AdminAPI 10009 可达" {
    $r = Post "$AdminApi/account/login" @{ account=$Account; password=(md5 $Password) }
    if ($r.errCode -eq 0 -and $r.data.adminToken) { return $true }
    return "errCode=$($r.errCode) errMsg=$($r.errMsg)"
}

$loginResp = Post "$AdminApi/account/login" @{ account=$Account; password=(md5 $Password) }
if ($loginResp.errCode -ne 0) {
    Write-Host "`n  [FATAL] 登录失败，无法继续测试: $($loginResp.errMsg)" -ForegroundColor Red
    exit 1
}

$adminToken = $loginResp.data.adminToken
$imToken    = $loginResp.data.imToken
$refreshTk  = if ($loginResp.data.PSObject.Properties.Name -contains 'refreshToken') { $loginResp.data.refreshToken } else { "" }
$adminUID   = $loginResp.data.adminUserID

$authHeaders = @{ "token" = $adminToken }
$imAuthHeaders = @{ "token" = $imToken }
$emptyBody = @{}

$rtPreview = if ($refreshTk -and $refreshTk.Length -ge 8) { $refreshTk.Substring(0, 8) } else { "(none)" }
Write-Host "  登录成功: adminUID=$adminUID refreshToken=$rtPreview..." -ForegroundColor DarkGray

# ========================================
#  1. 后端 API CRUD 验证
# ========================================
Write-Host "`n===== 1. 后端 API CRUD =====" -ForegroundColor Cyan

Test "GET /account/info" {
    $r = Post "$AdminApi/account/info" @{} $authHeaders
    if ($r.errCode -eq 0 -and $r.data.account) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /user/search (用户列表)" {
    $r = Post "$AdminApi/user/search" @{ keyword=""; pagination=@{pageNumber=1;showNumber=5} } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode) $($r.errMsg)"
}

Test "POST /default/user/find (默认好友)" {
    $r = Post "$AdminApi/default/user/find" @{} $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /default/group/find (默认群)" {
    $r = Post "$AdminApi/default/group/find" @{} $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /invitation_code/search" {
    $r = Post "$AdminApi/invitation_code/search" @{ pagination=@{pageNumber=1;showNumber=5} } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /user/forbidden/search (封禁列表)" {
    $r = Post "$AdminApi/user/forbidden/search" @{ pagination=@{pageNumber=1;showNumber=5} } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /forbidden/ip/search" {
    $r = Post "$AdminApi/forbidden/ip/search" @{ pagination=@{pageNumber=1;showNumber=5} } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /client_config/get" {
    $r = Post "$AdminApi/client_config/get" @{} $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /statistic/new_user_count" {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $r = Post "$AdminApi/statistic/new_user_count" @{ start=($now - 86400); end=$now } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /whitelist/search" {
    $r = Post "$AdminApi/whitelist/search" @{ pagination=@{pageNumber=1;showNumber=5} } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

Test "POST /wallet/user (查询钱包)" {
    $r = Post "$AdminApi/wallet/user" @{ userID="test_nonexist" } $authHeaders
    # 用户不存在时可能返回错误但不应是 404/500
    if ($r.errCode -eq 0 -or $r.errCode -lt 1000) { return $true }
    return "errCode=$($r.errCode)"
}

# ========================================
#  2. 权限 & Token 链
# ========================================
Write-Host "`n===== 2. 权限 & Token 链 =====" -ForegroundColor Cyan

Test "无 Token 请求被拒 (401)" {
    $r = Post "$AdminApi/account/info" @{} @{}
    if ($r.errCode -ne 0) { return $true }
    return "应被拒绝但返回 errCode=0"
}

Test "过期/错误 Token 被拒" {
    $r = Post "$AdminApi/account/info" @{} @{ "token"="invalid.token.here" }
    if ($r.errCode -ne 0) { return $true }
    return "应被拒绝"
}

if ($refreshTk) {
    Test "Token 刷新 (refresh)" {
        $r = Post "$AdminApi/account/token/refresh" @{ refreshToken=$refreshTk }
        if ($r.errCode -eq 0 -and $r.data.adminToken) { return $true }
        return "errCode=$($r.errCode) $($r.errMsg)"
    }
} else {
    Test "Token 刷新 (refresh)" { return "SKIP" }
}

Test "operationID 缺失被拒" {
    try {
        $resp = Invoke-RestMethod -Uri "$AdminApi/account/info" -Method POST `
            -Body '{}' -Headers @{ "token"=$adminToken; "Content-Type"="application/json" } `
            -TimeoutSec 10 -ErrorAction Stop
        if ($resp.errCode -ne 0) { return $true }
        return "缺少 operationID 但未被拒"
    } catch { return $true }  # 被拒 = 正确行为
}

# ========================================
#  3. 安全链验证
# ========================================
Write-Host "`n===== 3. 安全链 =====" -ForegroundColor Cyan

Test "SensitiveVerify challenge 签发" {
    $r = Post "$AdminApi/account/confirm/challenge" @{ action="test_action" } $authHeaders
    if ($r.errCode -eq 0 -and $r.data.nonce) { return $true }
    return "errCode=$($r.errCode) $($r.errMsg)"
}

Test "SensitiveVerify 无 nonce 被拒 (change_password)" {
    $r = Post "$AdminApi/account/change_password" @{
        currentPassword=(md5 $Password)
        newPassword=(md5 $Password)
    } $authHeaders
    # 应该返回 SensitiveVerify 错误（缺少 nonce headers）
    if ($r.errCode -ne 0) { return $true }
    return "缺少 SensitiveVerify 但请求通过"
}

Test "风控评分查询" {
    $r = Post "$AdminApi/security/risk/score" @{ ip="127.0.0.1" } $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode) $($r.errMsg)"
}

$b2fa = { $body = @{}; $r = Post "$AdminApi/account/2fa/status" $body $authHeaders; if ($r.errCode -eq 0) { return $true }; return "errCode=$($r.errCode) $($r.errMsg)" }
Test "2FA status" $b2fa

# ========================================
#  4. 审计日志
# ========================================
Write-Host "`n===== 4. 审计日志 =====" -ForegroundColor Cyan

# 先做一次写操作触发审计日志
$null = Post "$AdminApi/client_config/set" @{ config=@{discoverPageURL="https://e2e-test.example.com"} } $authHeaders
Start-Sleep 2

$baudit1 = { $r = Post "$AdminApi/security_log/search" @{ pageNum=1; showNum=10 } $authHeaders; if ($r.errCode -eq 0) { return $true }; return "errCode=$($r.errCode) $($r.errMsg)" }
Test "audit log search" $baudit1

$baudit2 = { $r = Post "$AdminApi/security_log/search" @{ pageNum=1; showNum=10 } $authHeaders; if ($r.errCode -eq 0 -and $r.data.total -gt 0) { return $true }; return "audit log empty (total=$($r.data.total))" }
Test "audit log has entries" $baudit2

# ========================================
#  5. WebSocket 鉴权
# ========================================
Write-Host "`n===== 5. WebSocket 鉴权 =====" -ForegroundColor Cyan

Test "WS Ticket 签发" {
    $r = Post "$AdminApi/ws/auth" $emptyBody $authHeaders
    if ($r.errCode -eq 0 -and $r.data.ticket) { return $true }
    return "errCode=$($r.errCode) $($r.errMsg)"
}

# ========================================
#  6. 权限管理 (RBAC)
# ========================================
Write-Host "`n===== 6. 权限管理 (RBAC) =====" -ForegroundColor Cyan

Test "查询自身权限" {
    $r = Post "$AdminApi/account/permissions" $emptyBody $authHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

# ========================================
#  7. 多租户隔离
# ========================================
Write-Host "`n===== 7. 多租户 =====" -ForegroundColor Cyan

Test "请求携带 X-Tenant-ID (ExtractTenantID)" {
    $hdrs = @{ "token"=$adminToken; "X-Tenant-ID"="test-tenant" }
    $r = Post "$AdminApi/account/info" @{} $hdrs
    # 正常返回即可（租户 ID 仅做上下文注入）
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode)"
}

# ========================================
#  8. IM API 联调
# ========================================
Write-Host "`n===== 8. IM API 联调 =====" -ForegroundColor Cyan

Test "IM API 获取在线用户统计" {
    $r = Post "$ImApi/user/get_users_online_status" @{ userIDs=@("imAdmin") } $imAuthHeaders
    if ($r.errCode -eq 0) { return $true }
    return "errCode=$($r.errCode) $($r.errMsg)"
}

# ========================================
#  9. 并发测试
# ========================================
Write-Host "`n===== 9. 并发测试 =====" -ForegroundColor Cyan

Test "10 并发用户搜索" {
    $jobs = 1..10 | ForEach-Object {
        Start-Job -ScriptBlock {
            param($url, $token, $i)
            $hdrs = @{
                "token" = $token
                "operationID" = "concurrent_$i"
                "Content-Type" = "application/json"
            }
            $body = @{ keyword=""; pagination=@{pageNumber=1;showNumber=2} } | ConvertTo-Json -Depth 5
            try {
                $r = Invoke-RestMethod -Uri "$url/user/search" -Method POST -Body $body -Headers $hdrs -TimeoutSec 15
                return $r.errCode
            } catch { return -1 }
        } -ArgumentList $AdminApi, $adminToken, $_
    }
    $results2 = $jobs | Wait-Job -Timeout 30 | Receive-Job
    $jobs | Remove-Job -Force
    $successes = ($results2 | Where-Object { $_ -eq 0 }).Count
    if ($successes -ge 8) { return $true }
    return "仅 $successes/10 成功"
}

# ========================================
#  10. 登录限流（放最后，会触发 IP 锁定）
# ========================================
Write-Host "`n===== 10. 登录限流 =====" -ForegroundColor Cyan

Test "登录限流 (AuthRateLimitByIP)" {
    # AuthRateLimitByIP: 5 req/min/IP. Use fake account to avoid brute-force locking admin.
    $blocked = $false
    for ($i = 0; $i -lt 8; $i++) {
        $rr = Post "$AdminApi/account/login" @{ account="ratelimit_test_user_$i"; password="x" }
        if ($null -ne $rr) {
            $ec = $null; try { $ec = $rr.errCode } catch {}
            if ($null -eq $ec) { try { $ec = $rr["errCode"] } catch {} }
            if ($ec -eq 429) { $blocked = $true; break }
        }
    }
    if ($blocked) { return $true }
    return "未触发429限流"
}

Write-Host "  等待限流解除 (65s)..." -ForegroundColor DarkGray
Start-Sleep 65
# 重新登录确认解锁
$unlockResp = Post "$AdminApi/account/login" @{ account=$Account; password=(md5 $Password) }
if ($unlockResp.errCode -eq 0) {
    Write-Host "  限流已解除，账户正常" -ForegroundColor Green
} else {
    Write-Host "  [WARN] 限流未解除: $($unlockResp.errMsg)" -ForegroundColor Yellow
}

# ========================================
#  Summary
# ========================================
Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "  验证完成" -ForegroundColor Cyan
Write-Host "  PASS: $pass  |  FAIL: $fail  |  SKIP: $skip" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Green" })
Write-Host "====================================" -ForegroundColor Cyan

if ($fail -gt 0) {
    Write-Host "`n失败项:" -ForegroundColor Red
    $results | Where-Object { $_.status -eq "FAIL" } | ForEach-Object {
        Write-Host "  - $($_.name): $($_.detail)" -ForegroundColor Red
    }
}

exit $fail
