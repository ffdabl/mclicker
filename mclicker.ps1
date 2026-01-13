if (-not ([System.Management.Automation.PSTypeName]'M').Type) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class M
{
    [DllImport("user32.dll")]
    public static extern void mouse_event(int a, int b, int c, int d, int e);
}
'@
}

$count = 0
$delay = 400
$parsedDelay = 0

$delayInput = Read-Host "Enter delay in milliseconds between clicks (default 400)"
$maxClicksInput = Read-Host "Enter max number of clicks (blank or 0 = unlimited)"

$jitterPct = 0.10  # 10% jitter
$maxClicks = 0

if ([int]::TryParse($delayInput, [ref]$parsedDelay) -and $parsedDelay -gt 0) {
    $delay = $parsedDelay
}

[int]::TryParse($maxClicksInput, [ref]$maxClicks) | Out-Null

Write-Host "Using delay $delay ms"
Write-Host ($(if ($maxClicks -gt 0) { "Max clicks: $maxClicks" } else { "Max clicks: unlimited" }))
Write-Host "Press ESC to stop"

$jitterRange = [int]($delay * $jitterPct)

while ($true) {
    # ESC key check (non-blocking)
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq [ConsoleKey]::Escape) {
            Write-Host "ESC pressed. Stopping."
            break
        }
    }

    [M]::mouse_event(2,0,0,0,0) # left down
    [M]::mouse_event(4,0,0,0,0) # left up

    $count++
    Write-Host ("Clicks: {0}" -f $count)

    if ($maxClicks -gt 0 -and $count -ge $maxClicks) {
        Write-Host "Max clicks reached. Stopping."
        break
    }

    $jitter = if ($jitterRange -gt 0) {
        Get-Random -Minimum (-$jitterRange) -Maximum ($jitterRange + 1)
    } else { 0 }

    $sleepMs = [Math]::Max(1, $delay + $jitter)
    Start-Sleep -Milliseconds $sleepMs
}
