# Run from an elevated Windows PowerShell on the WSL host:
#   powershell -ExecutionPolicy Bypass -File configure-ssh-portproxy.ps1 `
#     -ListenAddress 192.168.1.50 -RemoteSubnet 192.168.1.0/24
# Forwards <ListenAddress>:22 to WSL's sshd and allows only the given subnet.
param(
    [Parameter(Mandatory = $true)][string]$ListenAddress,
    [Parameter(Mandatory = $true)][string]$RemoteSubnet,
    [int]$ListenPort = 22
)

$ErrorActionPreference = 'Stop'

$connectAddress = '127.0.0.1'
$ruleName = "WSL SSH - $RemoteSubnet only"
$resultPath = Join-Path $env:TEMP 'wsl-ssh-portproxy-result.txt'

try {
    & netsh interface portproxy delete v4tov4 listenaddress=$ListenAddress listenport=$ListenPort | Out-Null
    & netsh interface portproxy add v4tov4 listenaddress=$ListenAddress listenport=$ListenPort connectaddress=$connectAddress connectport=$ListenPort
    if ($LASTEXITCODE -ne 0) { throw "netsh portproxy failed with exit code $LASTEXITCODE" }

    Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    New-NetFirewallRule `
        -DisplayName $ruleName `
        -Direction Inbound `
        -Action Allow `
        -Enabled True `
        -Protocol TCP `
        -LocalAddress $ListenAddress `
        -LocalPort $ListenPort `
        -RemoteAddress $RemoteSubnet `
        -Profile Any | Out-Null

    "OK`nListenAddress=$ListenAddress`nConnectAddress=$connectAddress`nRule=$ruleName" | Set-Content -Encoding ascii $resultPath
} catch {
    "ERROR`n$($_.Exception.Message)" | Set-Content -Encoding ascii $resultPath
    throw
}
