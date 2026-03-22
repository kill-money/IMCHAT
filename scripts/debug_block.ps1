$ErrorActionPreference = "Continue"

function Get-MD5([string]$text) {
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = $md5.ComputeHash($bytes)
    return [BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function Get-SHA256([string]$text) {
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($text)
    $hash = $sha.ComputeHash($bytes)
    return [BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function Post([string]$url, [string]$jsonBody, [hashtable]$headers = @{}) {
    $hdrs = @{ "operationID" = "dbg$(Get-Random)"; "Content-Type" = "application/json" }
    foreach ($k in $headers.Keys) { $hdrs[$k] = $headers[$k] }
    try {
        $r = Invoke-WebRequest -Uri $url -Method POST -Body $jsonBody -Headers $hdrs -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        return $r.Content
    } catch {
        try {
            $sr = $_.Exception.Response.GetResponseStream()
            $rd = [System.IO.StreamReader]::new($sr)
            $body = $rd.ReadToEnd(); $rd.Close()
            return $body
        } catch { return "EXCEPTION: $($_.Exception.Message)" }
    }
}

# 1. Admin login
$md5 = Get-MD5 "openIM123"
$loginResp = Post "http://localhost:10009/account/login" "{`"account`":`"imAdmin`",`"password`":`"$md5`"}"
Write-Host "LOGIN: $loginResp" 
$loginObj = $loginResp | ConvertFrom-Json
$tok = $loginObj.data.adminToken
$imTok = $loginObj.data.imToken

# 2. App user login
$sha = Get-SHA256 "Test1234"
$appResp = Post "http://localhost:10008/account/login" "{`"areaCode`":`"+86`",`"phoneNumber`":`"13800002222`",`"password`":`"$sha`",`"platform`":1,`"deviceID`":`"dbg`"}"
Write-Host ""
Write-Host "APP LOGIN: $appResp"
$appObj = $appResp | ConvertFrom-Json
$uid = $appObj.data.userID
Write-Host "userID = $uid"

# 3. Block user
Write-Host ""
$blockResp = Post "http://localhost:10009/user/forbidden/add" "{`"userID`":`"$uid`",`"reason`":`"test`"}" @{ "token"=$tok }
Write-Host "BLOCK: $blockResp"

# 4. Try login (should be 20012)
$checkResp = Post "http://localhost:10008/account/login" "{`"areaCode`":`"+86`",`"phoneNumber`":`"13800002222`",`"password`":`"$sha`",`"platform`":1,`"deviceID`":`"dbg`"}"
Write-Host "LOGIN AFTER BLOCK: $checkResp"

# 5. Unblock
$unblockResp = Post "http://localhost:10009/user/forbidden/remove" "{`"userIDs`":[`"$uid`"]}" @{ "token"=$tok }
Write-Host "UNBLOCK: $unblockResp"

# 6. Login again (should be 0)
$check2 = Post "http://localhost:10008/account/login" "{`"areaCode`":`"+86`",`"phoneNumber`":`"13800002222`",`"password`":`"$sha`",`"platform`":1,`"deviceID`":`"dbg`"}"
Write-Host "LOGIN AFTER UNBLOCK: $check2"

# 7. Statistics test
$now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$ago = (Get-Date).AddDays(-7).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$statsResp = Post "http://localhost:10009/statistic/new_user_count" "{`"start`":`"$ago`",`"end`":`"$now`"}" @{ "token"=$tok }
Write-Host ""
Write-Host "STATS: $statsResp"

# 8. Send message test
$sendResp = Post "http://localhost:10002/msg/send_msg" "{`"sendID`":`"imAdmin`",`"recvID`":`"$uid`",`"senderPlatformID`":3,`"content`":{`"text`":`"hello`"},`"contentType`":101,`"sessionType`":1,`"sendTime`":$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())}" @{ "token"=$imTok }
Write-Host ""
Write-Host "SEND MSG: $sendResp"

# 9. Update user info
$newNick = "TestDbg_$(Get-Random -Maximum 999)"
$updateResp = Post "http://localhost:10002/user/update_user_info" "{`"userInfo`":{`"userID`":`"$uid`",`"nickname`":`"$newNick`"}}" @{ "token"=$imTok }
Write-Host ""
Write-Host "UPDATE: $updateResp"

Start-Sleep -Milliseconds 500
$getResp = Post "http://localhost:10002/user/get_users_info" "{`"userIDs`":[`"$uid`"]}" @{ "token"=$imTok }
Write-Host "GET INFO: $getResp"
