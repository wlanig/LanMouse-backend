# LanMouse code sync script
# Usage: powershell -ExecutionPolicy Bypass -File sync_code.ps1

param(
    [string]$ServerHost = "120.77.81.144",
    [string]$ServerUser = "root",
    [string]$LocalPath = "d:/CodeBuddy_Project/LanMouse/backend",
    [string]$RemotePath = "/opt/lanmouse"
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "LanMouse Code Sync Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Sync Config:" -ForegroundColor Yellow
Write-Host "  Server: $ServerUser@$ServerHost"
Write-Host "  Local:  $LocalPath"
Write-Host "  Remote: $RemotePath"
Write-Host ""

$confirm = Read-Host "Confirm sync? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Cancelled" -ForegroundColor Gray
    exit
}

Write-Host ""
Write-Host "Syncing code..." -ForegroundColor Yellow
Write-Host ""

# Sync src/main/java
Write-Host "  Syncing src/main/java ..." -ForegroundColor Gray
scp -o StrictHostKeyChecking=no -r "$LocalPath/src/main/java" "$ServerUser@$ServerHost`:$RemotePath/src/main/"

# Sync src/main/resources
Write-Host "  Syncing src/main/resources ..." -ForegroundColor Gray
scp -o StrictHostKeyChecking=no -r "$LocalPath/src/main/resources" "$ServerUser@$ServerHost`:$RemotePath/src/main/"

# Sync pom.xml
Write-Host "  Syncing pom.xml ..." -ForegroundColor Gray
scp -o StrictHostKeyChecking=no "$LocalPath/pom.xml" "$ServerUser@$ServerHost`:$RemotePath/"

# Sync SQL scripts
Write-Host "  Syncing sql ..." -ForegroundColor Gray
scp -o StrictHostKeyChecking=no -r "$LocalPath/sql" "$ServerUser@$ServerHost`:$RemotePath/"

Write-Host ""
Write-Host "Code sync completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next step, run deploy script:" -ForegroundColor Yellow
Write-Host "  ssh $ServerUser@$ServerHost" -ForegroundColor White
Write-Host "  /opt/lanmouse/deploy_wechat.sh" -ForegroundColor White
Write-Host ""
