#!/bin/bash
# LanMouse 部署继续脚本（跳过MySQL安装）

cd /opt/lanmouse

echo "======================================"
echo "LanMouse 后端部署继续"
echo "======================================"

# 安装Redis
echo "[步骤] 安装 Redis..."
yum install -y redis -q
systemctl enable redis
systemctl start redis
echo "[成功] Redis 已启动"

# 配置MySQL数据库
echo "[步骤] 配置数据库..."
mysql -u root -p'740528@Ww' << 'EOSQL'
CREATE DATABASE IF NOT EXISTS lanmouse DEFAULT CHARACTER SET utf8mb4;
CREATE USER IF NOT EXISTS 'lanmouse'@'localhost' IDENTIFIED BY 'LanMouse@2024';
GRANT ALL PRIVILEGES ON lanmouse.* TO 'lanmouse'@'localhost';
FLUSH PRIVILEGES;
EOSQL

# 初始化表
echo "[步骤] 初始化数据表..."
mysql -u root -p'740528@Ww' lanmouse << 'EOSQL'
CREATE TABLE IF NOT EXISTS user_groups (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL COMMENT '组名称',
    code VARCHAR(20) NOT NULL COMMENT '组代码',
    annual_fee DECIMAL(10,2) NOT NULL COMMENT '年费',
    discount_rate DECIMAL(3,2) DEFAULT 1.00 COMMENT '折扣率',
    status INT DEFAULT 1 COMMENT '状态：0-禁用 1-启用',
    UNIQUE KEY uk_code (code),
    INDEX idx_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户组表';

INSERT IGNORE INTO user_groups VALUES 
(1, '普通用户', 'normal', 99.00, 1.00, 1),
(2, '学生用户', 'student', 49.00, 0.50, 1),
(3, 'VIP会员', 'vip', 199.00, 1.00, 1),
(4, '企业用户', 'enterprise', 599.00, 0.80, 1);

CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL COMMENT '手机号',
    password_hash VARCHAR(128) NOT NULL COMMENT '密码哈希',
    name VARCHAR(50) COMMENT '姓名',
    id_card_hash VARCHAR(64) COMMENT '身份证号哈希',
    user_group_id INT DEFAULT 1 COMMENT '用户组ID',
    status INT DEFAULT 1 COMMENT '状态：0-禁用 1-正常',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_phone (phone),
    INDEX idx_phone (phone)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

CREATE TABLE IF NOT EXISTS devices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT COMMENT '用户ID',
    imei1 VARCHAR(20) COMMENT 'IMEI1',
    ios_device_id VARCHAR(100) COMMENT 'iOS设备ID',
    device_name VARCHAR(100) COMMENT '设备名称',
    os_type VARCHAR(20) COMMENT '系统类型',
    status INT DEFAULT 0 COMMENT '状态：0-未激活 1-正常 2-冻结',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备表';

CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL COMMENT '用户ID',
    device_id BIGINT NOT NULL COMMENT '设备ID',
    order_no VARCHAR(64) NOT NULL COMMENT '订单号',
    start_date DATE COMMENT '开始日期',
    end_date DATE COMMENT '结束日期',
    amount DECIMAL(10,2) COMMENT '金额',
    payment_status VARCHAR(20) DEFAULT 'pending' COMMENT '支付状态',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_order_no (order_no)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订阅表';

CREATE TABLE IF NOT EXISTS payment_qr_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_no VARCHAR(64) NOT NULL COMMENT '订单号',
    qr_code_url TEXT COMMENT '二维码URL',
    expires_at DATETIME COMMENT '过期时间',
    status INT DEFAULT 0 COMMENT '状态：0-未使用 1-已使用 2-已过期',
    create_time DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付二维码表';

INSERT IGNORE INTO users (phone, password_hash, name, id_card_hash, user_group_id) 
VALUES ('13800138000', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '测试用户', 'a1b2c3d4', 1);
EOSQL

echo "[成功] 数据库配置完成"

# 配置应用
echo "[步骤] 配置应用..."
cat > /opt/lanmouse/application.yml << 'EOF'
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
  redis:
    host: localhost
    port: 6379
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0

mybatis-plus:
  configuration:
    map-underscore-to-camel-case: true
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl
  global-config:
    db-config:
      id-type: auto
      logic-delete-field: deleted
      logic-delete-value: 1
      logic-not-delete-value: 0

jwt:
  secret: LanMouseSecretKey2024VeryLongSecretKeyForSecurity
  expiration: 86400000
EOF

echo "[成功] 应用配置完成"

# 编译项目
echo "[步骤] 编译项目..."
cd /opt/lanmouse
mvn clean package -DskipTests -q

if [ ! -f "target/lanmouse-backend-1.0.0.jar" ]; then
    echo "[错误] 编译失败，JAR文件未生成"
    exit 1
fi
echo "[成功] 编译完成"

# 创建系统服务
echo "[步骤] 创建系统服务..."
cat > /etc/systemd/system/lanmouse.service << 'EOF'
[Unit]
Description=LanMouse Backend Service
After=network.target mysqld.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lanmouse
ExecStart=/usr/bin/java -jar -Xms256m -Xmx512m /opt/lanmouse/target/lanmouse-backend-1.0.0.jar --spring.config.location=/opt/lanmouse/application.yml
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable lanmouse
systemctl start lanmouse

echo "======================================"
echo "部署完成！"
echo "======================================"
echo ""
echo "服务状态:"
systemctl status lanmouse --no-pager

echo ""
echo "测试API:"
sleep 3
curl -s http://localhost:8080/api/health | cat

echo ""
echo ""
echo "访问地址: http://120.77.81.144:8080"
echo "测试账号: 13800138000 / 123456"
