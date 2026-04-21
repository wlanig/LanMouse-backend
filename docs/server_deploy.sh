#!/bin/bash
# =====================================================
# LanMouse 服务器端部署脚本 (直接复制到服务器执行)
# IP: 120.77.81.144
# =====================================================

set -e

APP_NAME="lanmouse-backend"
APP_JAR="lanmouse-backend-1.0.0.jar"
APP_DIR="/opt/lanmouse"
BACKUP_DIR="/opt/lanmouse/backup"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo_title() { echo -e "${CYAN}==============================================${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}==============================================${NC}"; }
echo_step() { echo -e "${YELLOW}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_error() { echo -e "${RED}[错误]${NC} $1"; }

# =====================================================
# 1. 初始化
# =====================================================
echo_title "LanMouse 后端部署脚本"

# 创建目录
mkdir -p $APP_DIR
mkdir -p $BACKUP_DIR
mkdir -p /var/log/lanmouse

# 备份旧版本
if [ -f "$APP_DIR/$APP_JAR" ]; then
    echo_step "备份旧版本..."
    BACKUP_FILE="$BACKUP_DIR/${APP_JAR}.$(date +%Y%m%d%H%M%S)"
    cp $APP_DIR/$APP_JAR $BACKUP_FILE
    echo_success "已备份到: $BACKUP_FILE"
fi

# =====================================================
# 2. 安装Java 17
# =====================================================
echo_step "检查Java环境..."
if ! command -v java &> /dev/null; then
    echo_step "安装OpenJDK 17..."
    yum install -y java-17-openjdk java-17-openjdk-devel -q
fi

JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
echo_success "Java版本: $JAVA_VERSION"

# =====================================================
# 3. 安装MySQL 8
# =====================================================
echo_step "检查MySQL环境..."
if ! command -v mysql &> /dev/null; then
    echo_step "安装MySQL 8..."
    
    # 根据CentOS版本选择安装方式
    if [ -f /etc/centos-release ]; then
        if grep -q "CentOS Linux release 7" /etc/centos-release; then
            # CentOS 7
            rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm -q
            yum install -y mysql-community-server -q
        else
            # CentOS 8 / Rocky / AlmaLinux
            rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el8-5.noarch.rpm -q
            dnf module disable mysql -y > /dev/null 2>&1 || true
            dnf install -y mysql-community-server -q
        fi
    fi
    
    systemctl enable mysqld
    systemctl start mysqld
    
    # 等待MySQL启动
    sleep 5
fi
echo_success "MySQL已安装"

# =====================================================
# 4. 安装Redis
# =====================================================
echo_step "检查Redis环境..."
if ! command -v redis-server &> /dev/null; then
    echo_step "安装Redis..."
    yum install -y redis -q
    systemctl enable redis
    systemctl start redis
fi
echo_success "Redis已安装"

# =====================================================
# 5. 配置MySQL数据库
# =====================================================
echo_step "配置MySQL数据库..."

# 设置MySQL root密码
mysql -u root << 'EOSQL'
ALTER USER 'root'@'localhost' IDENTIFIED BY '740528@Ww';
CREATE DATABASE IF NOT EXISTS lanmouse DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'lanmouse'@'localhost' IDENTIFIED BY 'LanMouse@2024';
CREATE USER IF NOT EXISTS 'lanmouse'@'%' IDENTIFIED BY 'LanMouse@2024';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'localhost';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'%';
FLUSH PRIVILEGES;
EOSQL

# 初始化数据库表
mysql -u root -p'740528@Ww' << 'EOSQL'
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

# =====================================================
# 6. 配置应用参数
# =====================================================
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

# =====================================================
# 7. 创建systemd服务
# =====================================================
echo_step "创建系统服务..."
cat > /etc/systemd/system/lanmouse.service << 'EOF'
[Unit]
Description=LanMouse Backend Service
After=network.target mysqld.service redis.service
Wants=mysqld.service redis.service

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

systemctl daemon-reload
echo_success "服务配置完成"

# =====================================================
# 8. 启动服务
# =====================================================
echo_step "启动LanMouse服务..."

# 停止旧服务（如果存在）
systemctl stop lanmouse 2>/dev/null || true

# 启用并启动服务
systemctl enable lanmouse
systemctl start lanmouse

# 等待启动
sleep 5

# 检查服务状态
for i in {1..30}; do
    if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
        echo_success "服务启动成功!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo_error "服务启动失败，请检查日志"
        echo "查看日志: journalctl -u lanmouse -n 50"
        exit 1
    fi
    sleep 1
done

# =====================================================
# 9. 完成
# =====================================================
echo ""
echo_success "============================================"
echo_success "  LanMouse 后端部署完成!"
echo_success "============================================"
echo ""
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
echo ""
echo_success "  测试账号: 13800138000 / 123456"
echo_success "============================================"
