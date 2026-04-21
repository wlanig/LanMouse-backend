#!/bin/bash
# =====================================================
# LanMouse 后端一键部署脚本
# 服务器: 120.77.81.144
# 执行方式: bash <(curl -sL https://xxx.com/deploy.sh)
# 或: curl -sL https://xxx.com/deploy.sh | bash
# =====================================================

set -e

APP_NAME="lanmouse-backend"
APP_DIR="/opt/lanmouse"
BACKUP_DIR="/opt/lanmouse/backup"
MYSQL_ROOT_PWD="740528@Ww"
MYSQL_APP_PWD="LanMouse@2024"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_title() { 
    echo ""
    echo -e "${CYAN}==============================================${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}==============================================${NC}"
    echo ""
}
echo_step() { echo -e "${YELLOW}[步骤]${NC} $1"; }
echo_success() { echo -e "${GREEN}[成功]${NC} $1"; }
echo_error() { echo -e "${RED}[错误]${NC} $1"; }
echo_info() { echo -e "${BLUE}[信息]${NC} $1"; }

# =====================================================
# 0. 前置检查
# =====================================================
echo_title "LanMouse 后端一键部署"

# 检查是否为root
if [ "$EUID" -ne 0 ]; then 
    echo_error "请使用 root 用户执行此脚本"
    echo_info "执行: sudo su - 或 ssh root@120.77.81.144"
    exit 1
fi

# 检查操作系统
if ! grep -qE "CentOS|Rocky|AlmaLinux" /etc/os-release; then
    echo_error "此脚本仅支持 CentOS/Rocky/AlmaLinux 系统"
    exit 1
fi

echo_info "检测到系统: $(cat /etc/os-release | grep "^NAME" | cut -d'"' -f2)"
echo_info "系统架构: $(uname -m)"
echo_info "当前目录: $(pwd)"

# =====================================================
# 1. 创建目录
# =====================================================
echo_step "创建应用目录..."
mkdir -p $APP_DIR
mkdir -p $BACKUP_DIR
mkdir -p /var/log/lanmouse
echo_success "目录创建完成"

# =====================================================
# 2. 备份旧版本（如有）
# =====================================================
if [ -f "$APP_DIR/target/lanmouse-backend-1.0.0.jar" ]; then
    echo_step "备份旧版本..."
    BACKUP_FILE="$BACKUP_DIR/lanmouse-backend-1.0.0.jar.$(date +%Y%m%d%H%M%S)"
    cp $APP_DIR/target/lanmouse-backend-1.0.0.jar $BACKUP_FILE
    echo_success "已备份到: $BACKUP_FILE"
fi

# =====================================================
# 3. 安装 Java 17
# =====================================================
echo_step "检查/安装 Java 17..."

if command -v java &> /dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    echo_info "Java 已安装: $JAVA_VER"
else
    echo_info "正在安装 OpenJDK 17..."
    yum install -y java-17-openjdk java-17-openjdk-devel java-17-openjdk-javadoc -q
    echo_success "Java 17 安装完成"
fi

# 设置 JAVA_HOME
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
export PATH=$JAVA_HOME/bin:$PATH
echo_success "JAVA_HOME: $JAVA_HOME"

# =====================================================
# 4. 安装 Maven
# =====================================================
echo_step "检查/安装 Maven..."

if command -v mvn &> /dev/null; then
    MVN_VER=$(mvn -version | head -n 1)
    echo_info "Maven 已安装: $MVN_VER"
else
    echo_info "正在安装 Maven 3.9..."
    cd /tmp
    curl -sL https://archive.apache.org/dist/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz -o apache-maven-3.9.6-bin.tar.gz
    tar -xzf apache-maven-3.9.6-bin.tar.gz -C /opt/
    ln -sf /opt/apache-maven-3.9.6/bin/mvn /usr/bin/mvn
    rm apache-maven-3.9.6-bin.tar.gz
    echo_success "Maven 安装完成"
fi

MVN_VER=$(mvn -version | head -n 1)
echo_success "Maven: $MVN_VER"

# =====================================================
# 5. 安装 MySQL 8
# =====================================================
echo_step "检查/安装 MySQL 8..."

if command -v mysql &> /dev/null; then
    MYSQL_VER=$(mysql --version)
    echo_info "MySQL 已安装: $MYSQL_VER"
else
    echo_info "正在安装 MySQL 8..."
    
    # 检测CentOS版本
    if grep -q "CentOS Linux release 7" /etc/centos-release; then
        # CentOS 7
        echo_info "检测到 CentOS 7"
        rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm -q
        yum install -y mysql-community-server -q
    else
        # CentOS 8 / Rocky / AlmaLinux
        echo_info "检测到 CentOS 8/Rocky"
        rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el8-5.noarch.rpm -q
        dnf module disable mysql -y > /dev/null 2>&1 || true
        dnf install -y mysql-community-server -q
    fi
    
    systemctl enable mysqld
    systemctl start mysqld
    sleep 5
    echo_success "MySQL 8 安装完成"
fi

# =====================================================
# 6. 安装 Redis
# =====================================================
echo_step "检查/安装 Redis..."

if command -v redis-server &> /dev/null; then
    echo_info "Redis 已安装"
else
    echo_info "正在安装 Redis..."
    yum install -y redis -q
    systemctl enable redis
    systemctl start redis
    echo_success "Redis 安装完成"
fi

# =====================================================
# 7. 配置 MySQL
# =====================================================
echo_step "配置 MySQL 数据库..."

# 启动MySQL（如未启动）
systemctl start mysqld 2>/dev/null || true
sleep 3

# 获取临时密码或设置root密码
echo_step "设置 MySQL root 密码..."
sleep 2

# 尝试使用空密码登录并设置密码
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PWD';" 2>/dev/null || true

# 创建数据库和应用用户
echo_step "创建数据库和用户..."
mysql -u root -p"$MYSQL_ROOT_PWD" << 'EOSQL'
CREATE DATABASE IF NOT EXISTS lanmouse DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'lanmouse'@'localhost' IDENTIFIED BY 'LanMouse@2024';
CREATE USER IF NOT EXISTS 'lanmouse'@'%' IDENTIFIED BY 'LanMouse@2024';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'localhost';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'%';
FLUSH PRIVILEGES;
EOSQL

echo_success "数据库配置完成"

# =====================================================
# 8. 初始化数据库表
# =====================================================
echo_step "初始化数据库表..."

mysql -u root -p"$MYSQL_ROOT_PWD" << 'EOSQL'
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

echo_success "数据库表初始化完成"

# =====================================================
# 9. 配置应用参数
# =====================================================
echo_step "配置应用参数..."
mkdir -p $APP_DIR/src/main/resources

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
# 10. 编译项目
# =====================================================
echo_step "编译项目 (这可能需要几分钟)..."

cd $APP_DIR

# 如果没有源码，提示用户上传
if [ ! -f "pom.xml" ]; then
    echo_error "未找到 pom.xml，请先上传源码到 $APP_DIR"
    echo_info "上传命令: scp -r ./backend/* root@120.77.81.144:/opt/lanmouse/"
    exit 1
fi

# 编译打包
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
mvn clean package -DskipTests -q

if [ $? -ne 0 ]; then
    echo_error "编译失败，请检查错误日志"
    exit 1
fi

echo_success "项目编译完成"

# =====================================================
# 11. 创建 systemd 服务
# =====================================================
echo_step "创建系统服务..."

cat > /etc/systemd/system/lanmouse.service << EOF
[Unit]
Description=LanMouse Backend Service
Documentation=https://github.com/lanmouse/backend
After=network.target mysqld.service redis.service
Wants=mysqld.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=$APP_DIR
Environment="JAVA_HOME=$JAVA_HOME"
ExecStart=$JAVA_HOME/bin/java -jar -Xms256m -Xmx512m $APP_DIR/target/lanmouse-backend-1.0.0.jar
ExecReload=/bin/kill -HUP \$MAINPID
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
# 12. 启动服务
# =====================================================
echo_step "启动 LanMouse 服务..."

# 停止旧服务
systemctl stop lanmouse 2>/dev/null || true

# 启动新服务
systemctl enable lanmouse
systemctl start lanmouse

# 等待启动
echo_info "等待服务启动..."
sleep 5

# =====================================================
# 13. 验证服务
# =====================================================
echo_step "验证服务状态..."

for i in {1..30}; do
    if curl -s http://localhost:8080/api/health > /dev/null 2>&1; then
        echo_success "服务启动成功!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo_error "服务启动失败，请检查日志"
        echo_info "查看日志: journalctl -u lanmouse -n 50"
        systemctl status lanmouse
        exit 1
    fi
    sleep 1
done

# 获取服务状态
SERVICE_STATUS=$(systemctl is-active lanmouse)
echo_info "服务状态: $SERVICE_STATUS"

# =====================================================
# 14. 完成
# =====================================================
echo ""
echo_success "=============================================="
echo_success "  LanMouse 后端部署完成!"
echo_success "=============================================="
echo ""
echo -e "  ${CYAN}服务地址:${NC}  http://120.77.81.144:8080"
echo -e "  ${CYAN}健康检查:${NC}  http://120.77.81.144:8080/api/health"
echo -e "  ${CYAN}数据库:${NC}     MySQL 8.0 (localhost:3306)"
echo -e "  ${CYAN}缓存:${NC}       Redis (localhost:6379)"
echo ""
echo -e "  ${CYAN}管理命令:${NC}"
echo "  - 查看状态: systemctl status lanmouse"
echo "  - 查看日志: journalctl -u lanmouse -f"
echo "  - 重启服务: systemctl restart lanmouse"
echo "  - 停止服务: systemctl stop lanmouse"
echo ""
echo -e "  ${CYAN}测试账号:${NC}   手机号 13800138000"
echo -e "  ${CYAN}密码:${NC}       123456"
echo ""
echo_success "=============================================="
