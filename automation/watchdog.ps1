# ============================================================
# Claude Code Watchdog - Windows PowerShell
# 모드: safe (반자동 - 검증 후 승인) / yolo (완전 자동)
# ============================================================

param(
    [ValidateSet("safe", "yolo")]
    [string]$Mode = "safe",
    [int]$Interval = 60,
    [string]$BuildCmd = "npm.cmd run build"
)

$LogDir = "./watchdog-logs"
$LogFile = "$LogDir/watchdog-$(Get-Date -Format 'yyyyMMdd').log"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $msg = "[$ts] $Message"
    Write-Host $msg -ForegroundColor $Color
    Add-Content -Path $LogFile -Value $msg
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "         Claude Code Watchdog v1.0                      " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
if ($Mode -eq "yolo") {
    Write-Host "  Mode: YOLO (Full Auto)                                " -ForegroundColor Red
} else {
    Write-Host "  Mode: SAFE (Review Required)                          " -ForegroundColor Green
}
Write-Host "  Interval: ${Interval}s | Build: $BuildCmd" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan

function Invoke-Build {
    Write-Log "Build running..." "Blue"
    try {
        $output = Invoke-Expression "$BuildCmd 2>&1" | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Build OK" "Green"
            return $true
        } else {
            Write-Log "Build FAILED" "Red"
            Set-Content -Path "$LogDir/last-error.log" -Value $output
            return $false
        }
    } catch {
        Write-Log "Build ERROR: $($_.Exception.Message)" "Red"
        Set-Content -Path "$LogDir/last-error.log" -Value $_.Exception.Message
        return $false
    }
}

function Invoke-AutoFix {
    $errorLog = Get-Content "$LogDir/last-error.log" -Raw
    Write-Log "Claude auto-fix requesting..." "Yellow"

    if ($Mode -eq "safe") {
        git stash push -m "watchdog-snapshot-$(Get-Date -Format 'HHmmss')" 2>$null

        $prompt = "Fix this build error with minimal changes:`n`n$errorLog`n`nSummarize what you changed."
        claude $prompt --auto-approve 2>&1 | Tee-Object -Append -FilePath $LogFile

        Write-Host ""
        Write-Host "--- Changes ---" -ForegroundColor Cyan
        git diff --stat
        Write-Host ""
        git diff --color
        Write-Host ""
        Write-Host "[A] Approve  [R] Reject  [S] Skip" -ForegroundColor Yellow
        $choice = Read-Host "Choice"

        switch ($choice.ToUpper()) {
            "A" {
                git add -A
                git commit -m "fix: watchdog auto-fix ($(Get-Date -Format 'MM/dd HH:mm'))"
                Write-Log "Approved and committed" "Green"
            }
            "R" {
                git checkout -- .
                git stash pop 2>$null
                Write-Log "Rejected and rolled back" "Red"
            }
            default {
                Write-Log "Skipped" "Blue"
            }
        }
    } else {
        $ts = Get-Date -Format 'MM/dd HH:mm'
        $prompt = "Fix this build error with minimal changes:`n`n$errorLog`n`nAfter fixing, run git add -A and git commit -m 'fix: watchdog auto-fix ($ts)'"
        claude $prompt --auto-approve 2>&1 | Tee-Object -Append -FilePath $LogFile
        Write-Log "YOLO auto-committed" "Yellow"
    }
}

$cycle = 0; $fixes = 0; $errors = 0
Write-Log "Watchdog started (PID: $PID)"

while ($true) {
    $cycle++
    Write-Log "-- Cycle #$cycle --" "Blue"

    if (-not (Invoke-Build)) {
        $errors++
        Invoke-AutoFix
        if (Invoke-Build) {
            $fixes++
            Write-Log "Auto-fix success! ($fixes/$errors resolved)" "Green"
        } else {
            Write-Log "Still failing after auto-fix" "Red"
            if ($Mode -eq "safe") { Read-Host "Press Enter to continue" }
        }
    }

    if ($cycle % 10 -eq 0) {
        Write-Log "Stats: cycles=$cycle errors=$errors fixes=$fixes" "Cyan"
    }
    Start-Sleep -Seconds $Interval
}
