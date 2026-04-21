# LanMouse Server Auto Debug Script v2
# 服务器自动调试脚本

$Server = @{
    Host = "120.77.81.144"
    Port = 22
    User = "root"
    Pass = "740528@Ww"
    AppDir = "/opt/lanmouse"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LanMouse Server Auto Debug v2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function SSH-Command {
    param([string]$cmd, [int]$retry = 2)
    for ($i = 1; $i -le $retry; $i++) {
        try {
            $escaped = $cmd -replace "'", "'\"'\"'"
            $output = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes "$($Server.User)@$($Server.Host)" "$escaped" 2>&1
            return $output
        } catch {
            Write-Host "SSH 重试 $i/$retry..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
    return "SSH 连接失败"
}

Write-Host "开始自动调试..." -ForegroundColor Green
Write-Host ""

# 1. 修改数据库 name 字段
Write-Host "[1/5] 修改数据库 name 字段..." -ForegroundColor Yellow
$alter = SSH-Command "mysql -u root -p'$($Server.Pass)' -e 'ALTER TABLE lanmouse.users MODIFY name VARCHAR(50) NULL;' 2>&1"
Write-Host $alter

# 2. 检查并重启服务
Write-Host ""
Write-Host "[2/5] 检查服务状态..." -ForegroundColor Yellow
$health = SSH-Command "curl -s http://localhost:8080/api/health 2>&1"
Write-Host "健康检查: $health"

$proc = SSH-Command "pgrep -f lanmouse-1.0.0.jar"
if (-not $proc) {
    Write-Host "服务未运行，正在启动..." -ForegroundColor Red
    SSH-Command "cd $($Server.AppDir) && nohup java -jar target/lanmouse-1.0.0.jar > /tmp/lanmouse.log 2>&1 &"
    SSH-Command "sleep 8"
    $health = SSH-Command "curl -s http://localhost:8080/api/health 2>&1"
    Write-Host "启动后健康检查: $health"
} else {
    Write-Host "服务已运行 (PID: $proc)" -ForegroundColor Green
}

# 3. 测试注册
Write-Host ""
Write-Host "[3/5] 测试注册接口..." -ForegroundColor Yellow
$reg = SSH-Command "curl -s -X POST http://localhost:8080/api/auth/register -H 'Content-Type: application/json' -d '{\"phone\":\"13800138002\",\"password\":\"123456\",\"email\":\"test2@test.com\"}'"
Write-Host $reg

# 4. 测试登录
Write-Host ""
Write-Host "[4/5] 测试登录接口..." -ForegroundColor Yellow
$login = SSH-Command "curl -s -X POST http://localhost:8080/api/auth/login -H 'Content-Type: application/json' -d '{\"phone\":\"13800138002\",\"password\":\"123456\"}'"
Write-Host $login

# 5. 检查错误日志
Write-Host ""
Write-Host "[5/5] 检查最新日志..." -ForegroundColor Yellow
$log = SSH-Command "tail -20 /tmp/lanmouse.log 2>/dev/null || echo '无日志'"
Write-Host $log

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  调试完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
