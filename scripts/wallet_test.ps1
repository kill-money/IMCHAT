# wallet_test.ps1 - 必须用 PowerShell 直接执行
param()
$utf8 = [Text.UTF8Encoding]::new($false)
$logPath = "$env:TEMP\wt_full.txt"
$log = @()

function Log($msg) {
    Write-Host $msg
    $script:log += $msg
}

# Step 1: Admin login
[IO.File]::WriteAllText("$env:TEMP\al_t.json", '{"account":"imAdmin","password":"openIM123"}', $utf8)
$rLogin = curl.exe -s -X POST http://localhost:10009/account/login -H "Content-Type: application/json" -H "operationID: T001" "--data-binary" "@$env:TEMP\al_t.json"
$ld = $rLogin | ConvertFrom-Json
Log "ADMIN_LOGIN errCode=$($ld.errCode)"
if ($ld.errCode -ne 0) { Log "ADMIN_LOGIN FAILED: $rLogin"; [IO.File]::WriteAllText($logPath, ($log -join "`n"), $utf8); exit 1 }
$imTok = $ld.data.imToken
Log "imToken_len=$($imTok.Length)"

# Step 2: Register wallet001 in IM server
[IO.File]::WriteAllText("$env:TEMP\imreg_t.json", '{"users":[{"userID":"8879191946","nickname":"wallet001","faceURL":""}]}', $utf8)
$rReg = curl.exe -s -X POST http://localhost:10002/user/user_register -H "Content-Type: application/json" -H "operationID: T002" -H "token: $imTok" "--data-binary" "@$env:TEMP\imreg_t.json"
Log "IM_REGISTER: $rReg"

# Step 3: Login as wallet001
[IO.File]::WriteAllText("$env:TEMP\wl_t.json", '{"account":"wallet001","password":"849f1575ccfbf3a4d6cf00e6c5641b7fd4da2ed3e212c2d79ba9161a5a432ff0","platform":1}', $utf8)
$rWl = curl.exe -s -X POST http://localhost:10008/account/login -H "Content-Type: application/json" -H "operationID: T003" -H "X-Device-ID: t-test" "--data-binary" "@$env:TEMP\wl_t.json"
Log "WALLET001_LOGIN: $rWl"

[IO.File]::WriteAllText($logPath, ($log -join "`n"), $utf8)
Log "Results saved to: $logPath"
