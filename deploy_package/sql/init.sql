-- =====================================================
-- LanMouse 数据库初始化脚本
-- =====================================================

-- 创建数据库
CREATE DATABASE IF NOT EXISTS lanmouse
DEFAULT CHARACTER SET utf8mb4
DEFAULT COLLATE utf8mb4_unicode_ci;

USE lanmouse;

-- =====================================================
-- 用户组表
-- =====================================================
CREATE TABLE IF NOT EXISTS user_groups (
    id INT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    name VARCHAR(50) NOT NULL COMMENT '组名称',
    code VARCHAR(20) NOT NULL UNIQUE COMMENT '组代码',
    annual_fee DECIMAL(10,2) NOT NULL DEFAULT 99.00 COMMENT '年费标准价',
    discount_rate DECIMAL(3,2) NOT NULL DEFAULT 1.00 COMMENT '折扣率(0.00-1.00)',
    description VARCHAR(200) COMMENT '描述',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-启用',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_user_groups_code (code),
    INDEX idx_user_groups_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户组表';

-- 初始化用户组数据
INSERT INTO user_groups (name, code, annual_fee, discount_rate, description) VALUES
('普通用户', 'normal', 99.00, 1.00, '标准收费'),
('学生用户', 'student', 49.00, 0.50, '学生五折优惠'),
('VIP会员', 'vip', 199.00, 1.00, 'VIP专属服务'),
('企业用户', 'enterprise', 599.00, 0.80, '企业八折优惠');

-- =====================================================
-- 用户表
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    phone VARCHAR(20) NOT NULL UNIQUE COMMENT '手机号',
    password_hash VARCHAR(128) NOT NULL COMMENT '密码哈希',
    name VARCHAR(50) NOT NULL COMMENT '真实姓名',
    id_card VARCHAR(18) COMMENT '身份证号(加密存储)',
    id_card_hash VARCHAR(64) NOT NULL COMMENT '身份证号哈希',
    user_group_id INT NOT NULL DEFAULT 1 COMMENT '用户组ID',
    openid VARCHAR(100) COMMENT '微信openid',
    status TINYINT NOT NULL DEFAULT 1 COMMENT '状态: 0-禁用 1-正常',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_users_phone (phone),
    INDEX idx_users_id_card_hash (id_card_hash),
    INDEX idx_users_user_group (user_group_id),
    INDEX idx_users_openid (openid),
    INDEX idx_users_status (status),
    CONSTRAINT fk_users_user_group FOREIGN KEY (user_group_id) REFERENCES user_groups(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户表';

-- =====================================================
-- 设备表
-- =====================================================
CREATE TABLE IF NOT EXISTS devices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    user_id BIGINT COMMENT '用户ID',
    imei1 VARCHAR(20) COMMENT '主IMEI(Android)',
    imei2 VARCHAR(20) COMMENT '副IMEI(Android)',
    ios_device_id VARCHAR(100) COMMENT 'iOS设备ID',
    device_name VARCHAR(100) NOT NULL COMMENT '设备名称',
    device_model VARCHAR(50) COMMENT '设备型号',
    os_type VARCHAR(20) NOT NULL COMMENT '操作系统类型: ios/android/windows',
    os_version VARCHAR(20) COMMENT '系统版本',
    last_ip VARCHAR(45) COMMENT '最后连接IP',
    last_active_at DATETIME COMMENT '最后活跃时间',
    status TINYINT NOT NULL DEFAULT 0 COMMENT '状态: 0-未激活 1-正常 2-冻结',
    bind_token VARCHAR(64) UNIQUE COMMENT '绑定令牌',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    INDEX idx_devices_imei1 (imei1),
    INDEX idx_devices_ios (ios_device_id),
    INDEX idx_devices_user (user_id),
    INDEX idx_devices_bind_token (bind_token),
    INDEX idx_devices_status (status),
    CONSTRAINT fk_devices_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='设备表';

-- =====================================================
-- 订阅表
-- =====================================================
CREATE TABLE IF NOT EXISTS subscriptions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    device_id BIGINT NOT NULL COMMENT '设备ID',
    order_no VARCHAR(64) NOT NULL UNIQUE COMMENT '订单号',
    start_date DATE NOT NULL COMMENT '有效期开始',
    end_date DATE NOT NULL COMMENT '有效期结束',
    amount DECIMAL(10,2) NOT NULL COMMENT '应付金额',
    discount_amount DECIMAL(10,2) DEFAULT 0 COMMENT '优惠金额',
    payment_method VARCHAR(20) COMMENT '支付方式: alipay/wechat',
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '支付状态: pending/paid/refunded/cancelled',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_subs_user (user_id),
    INDEX idx_subs_device (device_id),
    INDEX idx_subs_order (order_no),
    INDEX idx_subs_end_date (end_date),
    INDEX idx_subs_payment_status (payment_status),
    CONSTRAINT fk_subs_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_subs_device FOREIGN KEY (device_id) REFERENCES devices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订阅表';

-- =====================================================
-- 支付二维码表
-- =====================================================
CREATE TABLE IF NOT EXISTS payment_qr_codes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    qr_code VARCHAR(500) COMMENT '二维码内容',
    order_no VARCHAR(64) NOT NULL COMMENT '关联订单号',
    amount DECIMAL(10,2) NOT NULL COMMENT '金额',
    user_id BIGINT NOT NULL COMMENT '用户ID',
    device_id BIGINT NOT NULL COMMENT '设备ID',
    status VARCHAR(20) NOT NULL DEFAULT 'pending' COMMENT '状态: pending/paid/expired',
    expired_at DATETIME COMMENT '过期时间',
    paid_at DATETIME COMMENT '支付时间',
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX idx_qr_order (order_no),
    INDEX idx_qr_user (user_id),
    INDEX idx_qr_status (status),
    CONSTRAINT fk_qr_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT fk_qr_device FOREIGN KEY (device_id) REFERENCES devices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='支付二维码表';

-- =====================================================
-- 测试用户（密码: 123456）
-- =====================================================
-- BCrypt加密后的密码: $2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi
INSERT INTO users (phone, password_hash, name, id_card, id_card_hash, user_group_id, status) VALUES
('13800138000', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi', '测试用户', '110101199001011234', 'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2', 1, 1);
