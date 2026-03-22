$ErrorActionPreference = "Continue"

$h = @{ "operationID"="ws1"; "Content-Type"="application/json" }
$body = '{"account":"imAdmin","password":"fb01f147b53025cb74aae37eb0a4f46e"}'
$login = Invoke-RestMethod -Uri "http://localhost:10009/account/login" -Method POST -Body $body -Headers $h
$adminToken = $login.data.adminToken
Write-Host "Token OK: $([bool]($null -ne $adminToken))"

# Test 1: Valid token -> WS connects
try {
    $ws = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts = [System.Threading.CancellationTokenSource]::new(5000)
    $uri = "ws://localhost:10008/ws/presence?token=$adminToken"
    $ws.ConnectAsync([Uri]::new($uri), $cts.Token).Wait()
    Write-Host "Test1 PresenceWS: State=$($ws.State)"
    
    # Send heartbeat
    $msg = [System.Text.Encoding]::UTF8.GetBytes('{"event":"heartbeat"}')
    $seg = [System.ArraySegment[byte]]::new($msg)
    $ws.SendAsync($seg, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, [System.Threading.CancellationToken]::None).Wait()
    Write-Host "Test1 Heartbeat sent OK"
    
    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", [System.Threading.CancellationToken]::None).Wait()
    Write-Host "Test1 Close OK"
} catch {
    Write-Host "Test1 FAIL: $($_.Exception.InnerException.Message)"
}

# Test 2: Invalid token -> WS rejected
try {
    $ws2 = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts2 = [System.Threading.CancellationTokenSource]::new(5000)
    $ws2.ConnectAsync([Uri]::new("ws://localhost:10008/ws/presence?token=invalid_bad_token"), $cts2.Token).Wait()
    Write-Host "Test2 BadToken: State=$($ws2.State) -- SHOULD NOT CONNECT"
    $ws2.Dispose()
} catch {
    Write-Host "Test2 BadToken: REJECTED (correct)"
}

# Test 3: No token -> WS rejected
try {
    $ws3 = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts3 = [System.Threading.CancellationTokenSource]::new(5000)
    $ws3.ConnectAsync([Uri]::new("ws://localhost:10008/ws/presence"), $cts3.Token).Wait()
    Write-Host "Test3 NoToken: State=$($ws3.State) -- SHOULD NOT CONNECT"
    $ws3.Dispose()
} catch {
    Write-Host "Test3 NoToken: REJECTED (correct)"
}

# Test 4: IM native WS (10001) - basic connectivity
try {
    $ws4 = [System.Net.WebSockets.ClientWebSocket]::new()
    $cts4 = [System.Threading.CancellationTokenSource]::new(5000)
    $imToken = $login.data.imToken
    $imUri = "ws://localhost:10001?sendID=$($login.data.imUserID)&token=$imToken&platformID=3&operationID=wstest1"
    $ws4.ConnectAsync([Uri]::new($imUri), $cts4.Token).Wait()
    Write-Host "Test4 IM-WS: State=$($ws4.State)"
    $ws4.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "", [System.Threading.CancellationToken]::None).Wait()
    Write-Host "Test4 IM-WS Close OK"
} catch {
    Write-Host "Test4 IM-WS: $($_.Exception.InnerException.Message)"
}

Write-Host "Done."
