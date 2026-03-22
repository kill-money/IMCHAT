$utf8 = [Text.UTF8Encoding]::new($false)
$outFile = "$env:TEMP\wallet_test_results.txt"
$results = @()

# Step 1: Admin login
[IO.File]::WriteAllText("$env:TEMP\al_rw.json", '{"account":"imAdmin","password":"openIM123"}', $utf8)
$rLogin = curl.exe -s -X POST http://localhost:10009/account/login -H "Content-Type: application/json" -H "operationID: RW001" "--data-binary" "@$env:TEMP\al_rw.json"
$loginData = $rLogin | ConvertFrom-Json
$results += "ADMIN_LOGIN: errCode=$($loginData.errCode)"
if ($loginData.errCode -ne 0) {
    $results += "FAILED: $rLogin"
    [IO.File]::WriteAllText($outFile, ($results -join "`n"), $utf8)
    exit 1
}
$imTok = $loginData.data.imToken
$results += "imToken_len=$($imTok.Length)"

# Step 2: Register wallet001 in IM server
[IO.File]::WriteAllText("$env:TEMP\imreg_rw.json", '{"users":[{"userID":"8879191946","nickname":"wallet001","faceURL":""}]}', $utf8)
$rReg = curl.exe -s -X POST http://localhost:10002/user/user_register `
    -H "Content-Type: application/json" `
    -H "operationID: RW002" `
    -H "token: $imTok" `
    "--data-binary" "@$env:TEMP\imreg_rw.json"
$results += "IM_REGISTER: $rReg"

# Step 3: Login as wallet001
[IO.File]::WriteAllText("$env:TEMP\wl_rw.json", '{"account":"wallet001","password":"849f1575ccfbf3a4d6cf00e6c5641b7fd4da2ed3e212c2d79ba9161a5a432ff0","platform":1}', $utf8)
$rWallet = curl.exe -s -X POST http://localhost:10008/account/login `
    -H "Content-Type: application/json" `
    -H "operationID: RW003" `
    -H "X-Device-ID: rw-test" `
    "--data-binary" "@$env:TEMP\wl_rw.json"
$results += "WALLET001_LOGIN: $rWallet"

[IO.File]::WriteAllText($outFile, ($results -join "`n"), $utf8)
Write-Host "Done. Results in $outFile"
