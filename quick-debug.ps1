# LanMouse Quick Debug Script

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("1", "2", "3", "4")]
    [string]$Choice = $null
)

$projectRoot = "D:\CodeBuddy_Project\LanMouse"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LanMouse Quick Debug" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Select component to debug:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. Backend (Spring Boot + Java)" -ForegroundColor Gray
Write-Host "  2. Mobile (Flutter)" -ForegroundColor Gray
Write-Host "  3. PC Server (Node.js)" -ForegroundColor Gray
Write-Host "  4. All Components" -ForegroundColor Gray
Write-Host ""
Write-Host "  5. CodeBuddy Analysis Mode" -ForegroundColor Cyan
Write-Host ""

if (-not $Choice) {
    $Choice = Read-Host "Enter choice (1-5)"
}

switch ($Choice) {
    "1" {
        Write-Host ""
        Write-Host "[SELECT] Backend Debug" -ForegroundColor Green
        Write-Host ""
        & "$projectRoot\lanmouse-debug.ps1" -Component backend -AutoFix
    }
    "2" {
        Write-Host ""
        Write-Host "[SELECT] Mobile Debug" -ForegroundColor Green
        Write-Host ""
        & "$projectRoot\lanmouse-debug.ps1" -Component mobile -AutoFix
    }
    "3" {
        Write-Host ""
        Write-Host "[SELECT] PC Server Debug" -ForegroundColor Green
        Write-Host ""
        & "$projectRoot\lanmouse-debug.ps1" -Component pc-server -AutoFix
    }
    "4" {
        Write-Host ""
        Write-Host "[SELECT] All Components Debug" -ForegroundColor Green
        Write-Host ""
        & "$projectRoot\lanmouse-debug.ps1" -Component all -AutoFix
    }
    "5" {
        Write-Host ""
        Write-Host "[SELECT] CodeBuddy Analysis Mode" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Paste error info to CodeBuddy:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host '  "analyze these errors and fix LanMouse issues"' -ForegroundColor Cyan
        Write-Host ""
        $output = Get-Clipboard
        if ($output) {
            Write-Host "Clipboard content detected:" -ForegroundColor Gray
            Write-Host "---"
            $output | Select-Object -First 10 | ForEach-Object { Write-Host $_ -ForegroundColor White }
            Write-Host "---"
            Write-Host ""
            Write-Host "Ready for CodeBuddy analysis" -ForegroundColor Green
        } else {
            Write-Host "Clipboard is empty" -ForegroundColor Yellow
            Write-Host "Please copy error info first" -ForegroundColor Yellow
        }
    }
    default {
        Write-Host ""
        Write-Host "[ERROR] Invalid choice" -ForegroundColor Red
        Write-Host ""
    }
}

Write-Host ""
