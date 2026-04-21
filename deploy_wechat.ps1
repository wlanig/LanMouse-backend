# LanMouse 微信登录功能部署脚本 (PowerShell)
# 使用方式: 
#   方式1: 右键 -> 使用PowerShell运行
#   方式2: powershell -ExecutionPolicy Bypass -File deploy_wechat.ps1

param(
    [string]$ServerHost = "120.77.81.144",
    [string]$ServerUser = "root"
)

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "LanMouse 微信登录功能部署脚本" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 颜色函数
function Write-Green($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Yellow($msg) { Write-Host $msg -ForegroundColor Yellow }
function Write-Red($msg) { Write-Host $msg -ForegroundColor Red }

# 部署步骤
$steps = @(
    @{Title="检查服务状态"; Cmd="systemctl status lanmouse --no-pager 2>&1 | head -10"},
    @{Title="停止服务"; Cmd="systemctl stop lanmouse"},
    @{Title="执行数据库更新"; Cmd="mysql -u root -p lanmouse -e `\"ALTER TABLE users ADD COLUMN IF NOT EXISTS openid VARCHAR(128) DEFAULT NULL COMMENT '微信openid' AFTER password_hash; ALTER TABLE users ADD UNIQUE INDEX idx_openid (openid);\"`"},
    @{Title="打包项目"; Cmd="cd /opt/lanmouse && mvn clean package -DskipTests -q"},
    @{Title="启动服务"; Cmd="systemctl daemon-reload && systemctl start lanmouse"},
    @{Title="检查服务状态"; Cmd="systemctl status lanmouse --no-pager | head -10"}
)

Write-Yellow "即将部署到服务器: $ServerHost"
Write-Host ""
$confirm = Read-Host "确认部署? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "取消部署" -ForegroundColor Gray
    exit
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "正在执行部署..." -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# 生成远程执行脚本
$remoteScript = @'
set -e

echo "[1/6] 检查当前服务状态..."
systemctl status lanmouse --no-pager 2>&1 | head -10 || true

echo ""
echo "[2/6] 停止服务..."
systemctl stop lanmouse
sleep 2

echo ""
echo "[3/6] 执行数据库更新..."
mysql -u root -p lanmouse << 'EOSQL'
ALTER TABLE users ADD COLUMN IF NOT EXISTS openid VARCHAR(128) DEFAULT NULL COMMENT '微信openid' AFTER password_hash;
ALTER TABLE users ADD UNIQUE INDEX idx_openid (openid);
EOSQL
echo "数据库更新完成"

echo ""
echo "[4/6] 重新打包项目..."
cd /opt/lanmouse
mvn clean package -DskipTests -q
echo "打包完成"

echo ""
echo "[5/6] 启动服务..."
systemctl daemon-reload
systemctl start lanmouse
sleep 3

echo ""
echo "[6/6] 检查服务状态..."
if systemctl is-active --quiet lanmouse; then
    echo ""
    echo "=========================================="
    echo "✓ 服务启动成功！"
    echo "=========================================="
else
    echo ""
    echo "=========================================="
    echo "✗ 服务启动失败"
    echo "=========================================="
    journalctl -u lanmouse -n 20 --no-pager
fi

echo ""
echo "测试API..."
sleep 2
curl -s http://localhost:8080/api/health
echo ""

echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "API端点："
echo "  微信登录: POST http://localhost:8080/api/auth/wechat-login"
echo ""
'@

# 保存脚本到临时文件
$tempScript = "$env:TEMP\deploy_wechat_remote_$(Get-Random).sh"
$remoteScript | Out-File -FilePath $tempScript -Encoding UTF8

try {
    # 使用SSH执行远程脚本
    Write-Host "正在连接到 $ServerHost ..." -ForegroundColor Yellow
    
    $sshCmd = "ssh -o StrictHostKeyChecking=no $ServerUser@$ServerHost 'bash -s' < `"$tempScript`""
    Invoke-Expression $sshCmd
    
} finally {
    # 清理临时文件
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Green "=========================================="
Write-Green "部署脚本已生成"
Write-Green "=========================================="
Write-Host ""
Write-Host "在服务器上执行以下命令完成部署：" -ForegroundColor Yellow
Write-Host ""
Write-Host '  chmod +x /opt/lanmouse/deploy_wechat.sh' -ForegroundColor White
Write-Host '  /opt/lanmouse/deploy_wechat.sh' -ForegroundColor White
Write-Host ""
