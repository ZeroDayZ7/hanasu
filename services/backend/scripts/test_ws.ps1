$Uri = "ws://localhost:8080/ws"
Write-Host "Connecting to WebSocket at: $Uri ..." -ForegroundColor Cyan

$ws = New-Object System.Net.WebSockets.ClientWebSocket
$cts = New-Object System.Threading.CancellationTokenSource

try {
    $ws.ConnectAsync($Uri, $cts.Token).Wait()
    Write-Host "Connected successfully!" -ForegroundColor Green

    $data = @{
        type    = "translate"
        sender  = "powershell_tester"
        payload = "Czesc z testowego skryptu!"
    }
    $payload = $data | ConvertTo-Json -Compress

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $segment = New-Object System.ArraySegment[byte] -ArgumentList @(,$bytes)

    Write-Host "Sending packet: $payload" -ForegroundColor Yellow
    $ws.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true, $cts.Token).Wait()

    $buffer = New-Object byte[] 2048
    $recvSegment = New-Object System.ArraySegment[byte] -ArgumentList @(,$buffer)
    $result = $ws.ReceiveAsync($recvSegment, $cts.Token).Result
    
    $response = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
    Write-Host "Received broadcast: $response" -ForegroundColor Green

    $ws.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, "Test completed", $cts.Token).Wait()
    Write-Host "Connection closed." -ForegroundColor Gray
}
catch {
    Write-Host "Error during WS test: $_" -ForegroundColor Red
}
finally {
    $ws.Dispose()
    $cts.Dispose()
}