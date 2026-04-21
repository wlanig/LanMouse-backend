# 数据库设计文档

## 数据库名称
`lanmouse`

## 表结构

### 1. 用户表 (users)

存储用户基本信息。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | 手机号 |
| password_hash | VARCHAR(128) | NOT NULL | BCrypt加密密码 |
| name | VARCHAR(50) | NOT NULL | 真实姓名 |
| id_card | VARCHAR(18) | UNIQUE, NOT NULL | 身份证号(加密存储) |
| id_card_hash | VARCHAR(64) | NOT NULL | 身份证号哈希 |
| user_group_id | INT | FK | 用户组ID |
| status | TINYINT | DEFAULT 1 | 0-禁用 1-正常 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引:**
- idx_users_phone (phone)
- idx_users_id_card (id_card_hash)
- idx_users_user_group (user_group_id)

---

### 2. 用户组表 (user_groups)

用户分组和定价配置。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | INT | PK, AUTO_INCREMENT | 主键 |
| name | VARCHAR(50) | NOT NULL | 组名称 |
| code | VARCHAR(20) | UNIQUE, NOT NULL | 组代码 |
| annual_fee | DECIMAL(10,2) | NOT NULL | 年费标准价 |
| discount_rate | DECIMAL(3,2) | DEFAULT 1.00 | 折扣率(0.00-1.00) |
| description | VARCHAR(200) | | 描述 |
| status | TINYINT | DEFAULT 1 | 0-禁用 1-启用 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |

**初始数据:**
```sql
INSERT INTO user_groups (name, code, annual_fee, discount_rate, description) VALUES
('普通用户', 'normal', 99.00, 1.00, '标准收费'),
('学生用户', 'student', 49.00, 0.50, '学生五折优惠'),
('VIP会员', 'vip', 199.00, 1.00, 'VIP专属服务'),
('企业用户', 'enterprise', 599.00, 0.80, '企业八折优惠');
```

---

### 3. 手机设备表 (devices)

存储用户绑定的手机设备信息。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | FK, NOT NULL | 用户ID |
| imei1 | VARCHAR(20) | | 主IMEI(Android) |
| imei2 | VARCHAR(20) | | 副IMEI(Android) |
| ios_device_id | VARCHAR(100) | | iOS设备ID |
| device_name | VARCHAR(100) | | 设备名称 |
| device_model | VARCHAR(50) | | 设备型号 |
| os_type | VARCHAR(20) | NOT NULL | ios/android |
| os_version | VARCHAR(20) | | 系统版本 |
| last_ip | VARCHAR(45) | | 最后连接IP |
| last_active_at | DATETIME | | 最后活跃时间 |
| bind_token | VARCHAR(64) | UNIQUE | 绑定令牌 |
| bind_token_expire | DATETIME | | 令牌过期时间 |
| status | TINYINT | DEFAULT 0 | 0-未激活 1-正常 2-冻结 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 注册时间 |
| updated_at | DATETIME | ON UPDATE CURRENT_TIMESTAMP | 更新时间 |

**索引:**
- idx_devices_imei1 (imei1)
- idx_devices_ios (ios_device_id)
- idx_devices_user (user_id)
- idx_devices_bind_token (bind_token)

---

### 4. 订阅表 (subscriptions)

存储用户订阅信息。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| user_id | BIGINT | FK, NOT NULL | 用户ID |
| device_id | BIGINT | FK, NOT NULL | 设备ID |
| order_no | VARCHAR(64) | UNIQUE, NOT NULL | 订单号 |
| user_group_id | INT | FK | 订购时的用户组 |
| start_date | DATE | NOT NULL | 有效期开始 |
| end_date | DATE | NOT NULL | 有效期结束 |
| amount | DECIMAL(10,2) | NOT NULL | 应付金额 |
| discount_amount | DECIMAL(10,2) | DEFAULT 0 | 优惠金额 |
| payment_method | VARCHAR(20) | | alipay/wechat |
| payment_status | VARCHAR(20) | NOT NULL | pending/paid/refunded |
| paid_at | DATETIME | | 支付时间 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |

**索引:**
- idx_subs_user (user_id)
- idx_subs_device (device_id)
- idx_subs_order (order_no)
- idx_subs_end_date (end_date)

---

### 5. 支付二维码表 (payment_qr_codes)

存储支付二维码和订单信息。

| 字段 | 类型 | 约束 | 说明 |
|------|------|------|------|
| id | BIGINT | PK, AUTO_INCREMENT | 主键 |
| order_no | VARCHAR(64) | UNIQUE, NOT NULL | 订单号 |
| user_id | BIGINT | FK, NOT NULL | 用户ID |
| device_id | BIGINT | FK, NOT NULL | 设备ID |
| amount | DECIMAL(10,2) | NOT NULL | 金额 |
| qr_code_url | VARCHAR(500) | | 二维码链接 |
| qr_code_data | TEXT | | 二维码原始数据 |
| payment_channel | VARCHAR(20) | | alipay/wechat |
| status | VARCHAR(20) | DEFAULT 'pending' | pending/paid/expired/cancelled |
| expire_time | DATETIME | NOT NULL | 过期时间 |
| paid_time | DATETIME | | 支付时间 |
| created_at | DATETIME | DEFAULT CURRENT_TIMESTAMP | 创建时间 |

**索引:**
- idx_qr_order (order_no)
- idx_qr_user (user_id)
- idx_qr_status (status)

---

## 关系图

```
┌──────────────┐       ┌──────────────┐
│ user_groups  │       │    users     │
│──────────────│       │──────────────│
│ id (PK)      │◄──N───┤user_group_id │
│ name         │       │ id (PK)      │
│ annual_fee   │       │ phone        │
└──────────────┘       │ id_card_hash │
                       └──────┬───────┘
                              │1
                              │N
                       ┌──────┴───────┐
                       │   devices    │
                       │──────────────│
                       │ id (PK)      │
                       │ user_id (FK)│◄─┐
                       │ imei1       │  │
                       │ bind_token  │  │
                       └──────┬───────┘  │
                              │1         │N
                              │    ┌─────┴─────┐
                       ┌──────┴────┐│subscriptions│
                       │payment_qr ││──────────────│
                       │_codes     ││ id (PK)     │
                       │───────────││ user_id (FK)│
                       │ id (PK)   ││ device_id(FK)│
                       │ order_no  │└──────────────┘
                       └───────────┘
```

## SQL脚本

详见 `sql/init.sql`
