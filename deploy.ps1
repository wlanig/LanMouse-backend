# =====================================================
# LanMouse 后端部署脚本 (本地 - Windows PowerShell)
# =====================================================

param(
    [string]$ServerHost = "120.77.81.144",
    [string]$ServerPort = "22",
    [string]$Username = "root",
    [string]$Password = "740528@Ww",
    [string]$LocalJarPath = "target\lanmouse-backend-1.0.0.jar"
)

$ErrorActionPreference = "Stop"

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  LanMouse 后端部署脚本" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# 颜色函数
function Write-Step { param($msg) Write-Host "[步骤] $msg" -ForegroundColor Yellow }
function Write-Success { param($msg) Write-Host "[成功] $msg" -ForegroundColor Green }
function Write-Error { param($msg) Write-Host "[错误] $msg" -ForegroundColor Red }

# 1. 检查Maven
Write-Step "检查Maven环境..."
try {
    $mvnVersion = & mvn -v 2>&1 | Select-Object -First 1
    if ($mvnVersion -match "Apache Maven") {
        Write-Success "Maven已安装: $mvnVersion"
    } else {
        throw "Maven未正确安装"
    }
} catch {
    Write-Error "Maven未安装或未配置PATH，请先安装Maven"
    exit 1
}

# 2. 编译打包
Write-Step "编译打包后端项目..."
Set-Location "d:\CodeBuddy_Project\LanMouse\backend"
& mvn clean package -DskipTests -q
if ($LASTEXITCODE -ne 0) {
    Write-Error "Maven打包失败"
    exit 1
}
Write-Success "项目打包成功"

# 3. 检查JAR文件
$jarFile = "target\lanmouse-backend-1.0.0.jar"
if (-not (Test-Path $jarFile)) {
    Write-Error "JAR文件未找到: $jarFile"
    exit 1
}
Write-Success "JAR文件: $jarFile"

# 4. 创建远程部署脚本内容
$remoteScript = @'
#!/bin/bash
# =====================================================
# LanMouse 服务器端部署脚本
# =====================================================

set -e

APP_NAME="lanmouse-backend"
APP_JAR="lanmouse-backend-1.0.0.jar"
APP_DIR="/opt/lanmouse"
APP_PORT=8080
BACKUP_DIR="/opt/lanmouse/backup"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo_step() { echo -e "${YELLOW}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_error() { echo -e "${RED}[错误]${NC} $1"; }

# 1. 创建目录
echo_step "创建应用目录..."
mkdir -p $APP_DIR
mkdir -p $BACKUP_DIR

# 2. 备份旧版本
if [ -f "$APP_DIR/$APP_JAR" ]; then
    echo_step "备份旧版本..."
    BACKUP_FILE="$BACKUP_DIR/${APP_JAR}.$(date +%Y%m%d%H%M%S)"
    cp $APP_DIR/$APP_JAR $BACKUP_FILE
    echo_success "已备份到: $BACKUP_FILE"
fi

# 3. 检查并安装Java 17
echo_step "检查Java环境..."
if ! command -v java &> /dev/null; then
    echo_step "安装OpenJDK 17..."
    yum install -y java-17-openjdk java-17-openjdk-devel > /dev/null 2>&1
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo_success "Java版本: $JAVA_VERSION"

# 4. 检查并安装MySQL 8
echo_step "检查MySQL环境..."
if ! command -v mysql &> /dev/null; then
    echo_step "安装MySQL 8..."
    
    # 检查CentOS版本
    if [ -f /etc/centos-release ]; then
        cat /etc/centos-release | grep -q "CentOS Linux 7"
        if [ $? -eq 0 ]; then
            # CentOS 7
            rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm > /dev/null 2>&1
            yum install -y mysql-community-server > /dev/null 2>&1
        else
            # CentOS 8/Rocky
            rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el8-5.noarch.rpm > /dev/null 2>&1
            dnf module disable mysql > /dev/null 2>&1 || true
            dnf install -y mysql-community-server > /dev/null 2>&1
        fi
    fi
    
    systemctl enable mysqld
    systemctl start mysqld
    
    # 获取临时密码
    TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}' | tail -1)
    if [ -n "$TEMP_PASS" ]; then
        echo_step "MySQL临时密码: $TEMP_PASS"
        echo_success "请及时修改MySQL root密码"
    fi
fi

echo_success "MySQL已安装"

# 5. 检查并安装Redis
echo_step "检查Redis环境..."
if ! command -v redis-server &> /dev/null; then
    echo_step "安装Redis..."
    yum install -y redis > /dev/null 2>&1
    systemctl enable redis
    systemctl start redis
fi
echo_success "Redis已安装"

# 6. 配置MySQL数据库
echo_step "配置MySQL数据库..."
mysql -u root -p"740528@Ww" << 'EOSQL'
-- 创建数据库
CREATE DATABASE IF NOT EXISTS lanmouse DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建应用用户
CREATE USER IF NOT EXISTS 'lanmouse'@'localhost' IDENTIFIED BY 'LanMouse@2024';
CREATE USER IF NOT EXISTS 'lanmouse'@'%' IDENTIFIED BY 'LanMouse@2024';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'localhost';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'%';
FLUSH PRIVILEGES;

-- 使用数据库
USE lanmouse;

-- 用户组表
CREATE TABLE IF NOT EXISTS user_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    code VARCHAR(20) NOT NULL UNIQUE,
    annual_fee DECIMAL(10,2) NOT NULL DEFAULT 99.00,
    discount_rate DECIMAL(3,2) NOT NULL DEFAULT 1.00,
    description VARCHAR(200),
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 初始化用户组
INSERT IGNORE INTO user_groups (name, code, annual_fee, discount_rate, description) VALUES
('普通用户', 'normal', 99.00, 1.00, '标准收费'),
('学生用户', 'student', 49.00, 0.50, '学生五折优惠'),
('VIP会员', 'vip', 199.00, 1.00, 'VIP专属服务'),
('企业用户', 'enterprise', 599.00, 0.80, '企业八折优惠');

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    password_hash VARCHAR(128) NOT NULL,
    name VARCHAR(50) NOT NULL,
    id_card VARCHAR(18),
    id_card_hash VARCHAR(64) NOT NULL,
    user_group_id INT NOT NULL DEFAULT 1,
    status TINYINT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_phone (phone),
    INDEX idx_id_card_hash (id_card_hash),
    INDEX idx_user_group (user_group_id),
    CONSTRAINT fk_users_user_group FOREIGN KEY (user_group_id) REFERENCES user_groups(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 设备表
CREATE TABLE IF NOT EXISTS devices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT,
    imei1 VARCHAR(20),
    imei2 VARCHAR(20),
    ios_device_id VARCHAR(100),
    device_name VARCHAR(100) NOT NULL,
    device_model VARCHAR(50),
    os_type VARCHAR(20) NOT NULL,
    os_version VARCHAR(20),
    last_ip VARCHAR(45),
    last_active_at DATETIME,
    bind_token VARCHAR(64) UNIQUE,
    bind_token_expire DATETIME,
    status TINYINT NOT NULL DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_imei1 (imei1),
    INDEX idx_ios (ios_device_id),
    INDEX idx_user (user_id),
    INDEX idx_bind_token (bind_token),
    CONSTRAINT fk_devices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 订阅表
CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    order_no VARCHAR(64) NOT NULL UNIQUE,
    user_group_id INT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    payment_method VARCHAR(20),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    paid_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user (user_id),
    INDEX idx_device (device_id),
    INDEX idx_order (order_no),
    INDEX idx_end_date (end_date),
    CONSTRAINT fk_subs_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_subs_device FOREIGN KEY (device_id) REFERENCES devices(id),
    CONSTRAINT fk_subs_user_group FOREIGN KEY (user_group_id) REFERENCES user_groups(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 支付二维码表
CREATE TABLE IF NOT EXISTS payment_qr_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL,
    user_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    qr_code_url VARCHAR(500),
    qr_code_data TEXT,
    payment_channel VARCHAR(20),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    expire_time DATETIME NOT NULL,
    paid_time DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_order (order_no),
    INDEX idx_user (user_id),
    INDEX idx_status (status),
    INDEX idx_expire_time (expire_time),
    CONSTRAINT fk_qr_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_qr_device FOREIGN KEY (device_id) REFERENCES devices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 测试用户 (密码: 123456)
INSERT IGNORE INTO users (phone, password_hash, name, id_card, id_card_hash, user_group_id, status) 
VALUES ('13800138000', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '测试用户', '110101199001011234', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2', 1, 1);

EOSQL

echo_success "数据库配置完成"

# 7. 配置application.yml
echo_step "配置应用参数..."
cat > $APP_DIR/application.yml << 'EOF'
server:
  port: 8080

spring:
  application:
    name: lanmouse-backend
  
  datasource:
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://localhost:3306/lanmouse?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true
    username: lanmouse
    password: LanMouse@2024
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 300000
      connection-timeout: 20000
  
  redis:
    host: localhost
    port: 6379
    database: 0
    timeout: 5000
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0
        max-wait: -1

mybatis-plus:
  mapper-locations: classpath*:/mapper/**/*.xml
  type-aliases-package: com.lanmouse.entity
  configuration:
    map-underscore-to-camel-case: true
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl

jwt:
  secret: LanMouseSecretKey2024VeryLongSecretKeyForSecurity
  expiration: 86400000

logging:
  level:
    com.lanmouse: INFO
  file:
    name: /var/log/lanmouse/application.log
EOF

echo_success "应用配置完成"

# 8. 创建systemd服务
echo_step "创建系统服务..."
cat > /etc/systemd/system/lanmouse.service << 'EOF'
[Unit]
Description=LanMouse Backend Service
After=network.target mysql.service redis.service
Wants=mysql.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lanmouse
ExecStart=/usr/bin/java -jar -Xms256m -Xmx512m /opt/lanmouse/lanmouse-backend-1.0.0.jar
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10
StandardOutput=append:/var/log/lanmouse/stdout.log
StandardError=append:/var/log/lanmouse/stderr.log

[Install]
WantedBy=multi-user.target
EOF

# 创建日志目录
mkdir -p /var/log/lanmouse

# 重新加载systemd
systemctl daemon-reload

# 9. 停止旧服务
if systemctl is-active --quiet lanmouse; then
    echo_step "停止旧服务..."
    systemctl stop lanmouse
fi

# 10. 启动服务
echo_step "启动LanMouse服务..."
systemctl enable lanmouse
systemctl start lanmouse

# 11. 等待启动并检查
echo_step "检查服务状态..."
sleep 5
for i in {1..30}; do
    if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
        echo_success "服务启动成功!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo_error "服务启动失败，请检查日志"
        systemctl status lanmouse
        exit 1
    fi
    sleep 1
done

# 12. 显示最终状态
echo ""
echo_success "============================================"
echo_success "  LanMouse 后端部署完成!"
echo_success "============================================"
echo "  服务地址: http://120.77.81.144:8080"
echo "  健康检查: http://120.77.81.144:8080/api/health"
echo "  数据库:   MySQL 8.0 (localhost:3306)"
echo "  缓存:     Redis (localhost:6379)"
echo ""
echo "  管理命令:"
echo "  - 查看状态: systemctl status lanmouse"
echo "  - 查看日志: journalctl -u lanmouse -f"
echo "  - 重启服务: systemctl restart lanmouse"
echo "  - 停止服务: systemctl stop lanmouse"
echo_success "============================================"
'@

# 5. 转换远程脚本为Base64
Write-Step "编码部署脚本..."
$scriptBytes = [System.Text.Encoding]::UTF8.GetBytes($remoteScript)
$scriptBase64 = [System.Convert]::ToBase64String($scriptBytes)

# 6. 使用PowerShell SSH连接到服务器
Write-Step "连接远程服务器: $ServerHost..."
$session = New-PSSession -HostName $ServerHost -UserName $Username -Port $ServerPort

try {
    # 6.1 发送部署脚本到服务器
    Write-Step "上传部署脚本..."
    Invoke-Command -Session $session -ScriptBlock {
        param($base64)
        $script = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($base64))
        $script | Out-File -FilePath "/tmp/deploy_lanmouse.sh" -Encoding UTF8
    } -ArgumentList $scriptBase64

    # 6.2 设置脚本执行权限并运行
    Write-Step "执行服务器部署脚本..."
    Invoke-Command -Session $session -ScriptBlock {
        chmod +x /tmp/deploy_lanmouse.sh
        bash /tmp/deploy_lanmouse.sh
    }

    # 6.3 上传JAR文件
    Write-Step "上传JAR文件..."
    $jarContent = Get-Content $jarFile -Raw -Encoding Byte
    $jarBase64 = [Convert]::ToBase64String($jarContent)
    
    Invoke-Command -Session $session -ScriptBlock {
        param($base64, $jarPath)
        $bytes = [System.Convert]::FromBase64String($base64)
        [System.IO.File]::WriteAllBytes($jarPath, $bytes)
    } -ArgumentList $jarBase64, $jarFile

    # 6.4 重启服务
    Write-Step "重启服务..."
    Invoke-Command -Session $session -ScriptBlock {
        systemctl restart lanmouse
        Start-Sleep -Seconds 3
        systemctl status lanmouse --no-pager
    }

    Write-Success "部署完成!"
    
} catch {
    Write-Error "部署失败: $_"
} finally {
    Remove-PSSession $session
}

Write-Host ""
Write-Success "============================================"
Write-Success "  部署完成!"
Write-Success "============================================"
Write-Host "  服务地址: http://120.77.81.144:8080"
Write-Host "  API文档: http://120.77.81.144:8080/swagger-ui.html"
Write-Host "============================================"
