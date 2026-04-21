# LanMouse 手机触控板控制系统 - 技术规范

## 1. 项目概述

### 项目名称
**LanMouse** (局域网鼠标)

### 项目类型
跨平台手机遥控PC鼠标控制系统，包含：
- **移动端App** (Android/iOS)
- **PC端服务端** (Windows/macOS/Linux)
- **后端服务器** (Spring Boot + MySQL)
- **扫码支付系统**

### 核心功能摘要
通过手机模拟笔记本电脑触控板，实现通过网络远程控制PC鼠标的功能，配合用户认证、年费订阅和扫码支付系统。

### 目标用户
- 需要演示/远程控制PC的商务人士
- 家庭影院PC用户
- 懒人用户
- 多设备协同用户

---

## 2. 技术架构

### 2.1 系统架构图
```
┌─────────────────────────────────────────────────────────────────┐
│                         后端服务器                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ 用户服务  │  │ 设备服务  │  │ 支付服务  │  │   QR码生成服务   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────────┘  │
│                         │                                        │
│                   ┌─────┴─────┐                                   │
│                   │   MySQL   │                                   │
│                   └───────────┘                                   │
└─────────────────────────────────────────────────────────────────┘
         │                                    │
         │ HTTP/REST                          │ TCP Socket
         ▼                                    ▼
┌─────────────────┐                  ┌─────────────────┐
│   手机端 App     │ ◄──────────────► │   PC端服务端    │
│ (触控板界面)     │     局域网连接     │  (鼠标控制)     │
└─────────────────┘                  └─────────────────┘
```

### 2.2 技术栈

| 组件 | 技术选型 |
|------|---------|
| 移动端(iOS) | Flutter |
| 移动端(Android) | Flutter |
| PC服务端 | Node.js (Electron) 或 Python |
| 后端服务器 | Spring Boot 2.7 + Java 17 |
| 数据库 | MySQL 8.0 |
| 缓存 | Redis |
| 支付集成 | 支付宝/微信支付 API |

### 2.3 网络通信协议

**手机 → PC 控制协议 (TCP Socket)**
```json
{
  "type": "mouse_move" | "mouse_click" | "mouse_scroll" | "touch_start" | "touch_end",
  "x": 0-100,        // 相对坐标百分比
  "y": 0-100,
  "dx": 0-100,       // 移动增量
  "dy": 0-100,
  "button": "left" | "right" | "middle",
  "scrollY": -100~100,
  "timestamp": 1234567890
}
```

**手机 ↔ 服务器通信 (HTTP REST API)**
- 设备注册/绑定
- 用户认证
- 年费查询/支付
- 扫码支付回调

---

## 3. 数据库设计

### 3.1 ER图概述
```
用户表(users) 1 ──N 手机表(devices) N──1 用户组表(user_groups)
    │                    │
    │                    │
    ▼                    ▼
订阅表(subscriptions)   设备注册表(device_registry)
```

### 3.2 表结构

#### users (用户表)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| id_card | VARCHAR(18) | 身份证号(唯一) |
| id_card_hash | VARCHAR(64) | 身份证号哈希(校验) |
| name | VARCHAR(50) | 真实姓名 |
| phone | VARCHAR(20) | 联系电话 |
| password_hash | VARCHAR(128) | 密码哈希 |
| user_group_id | INT FK | 用户组ID |
| status | TINYINT | 0-禁用 1-正常 |
| created_at | DATETIME | 注册时间 |
| updated_at | DATETIME | 更新时间 |

#### devices (手机设备表)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| user_id | BIGINT FK | 用户ID |
| imei1 | VARCHAR(20) | IMEI1 (主要) |
| imei2 | VARCHAR(20) | IMEI2 |
| ios_device_id | VARCHAR(100) | 苹果设备ID |
| device_name | VARCHAR(100) | 设备名称 |
| device_model | VARCHAR(50) | 设备型号 |
| os_type | VARCHAR(20) | ios/android |
| os_version | VARCHAR(20) | 系统版本 |
| last_ip | VARCHAR(45) | 最后连接IP |
| last_active_at | DATETIME | 最后活跃时间 |
| status | TINYINT | 0-未激活 1-正常 2-冻结 |
| bind_token | VARCHAR(64) | 绑定令牌 |
| created_at | DATETIME | 注册时间 |

#### user_groups (用户组表)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | INT PK | 主键 |
| name | VARCHAR(50) | 组名称 |
| code | VARCHAR(20) | 组代码 |
| annual_fee | DECIMAL(10,2) | 年费标准价 |
| discount_rate | DECIMAL(3,2) | 折扣率(0.00-1.00) |
| description | VARCHAR(200) | 描述 |
| status | TINYINT | 状态 |

#### subscriptions (订阅表)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| user_id | BIGINT FK | 用户ID |
| device_id | BIGINT FK | 设备ID |
| order_no | VARCHAR(64) | 订单号 |
| start_date | DATE | 有效期开始 |
| end_date | DATE | 有效期结束 |
| amount | DECIMAL(10,2) | 实际金额 |
| discount_amount | DECIMAL(10,2) | 优惠金额 |
| payment_method | VARCHAR(20) | 支付方式 |
| payment_status | VARCHAR(20) | 支付状态 |
| created_at | DATETIME | 创建时间 |

#### payment_qr_codes (支付二维码表)
| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT PK | 主键 |
| qr_code | VARCHAR(255) | 二维码内容 |
| order_no | VARCHAR(64) | 关联订单号 |
| amount | DECIMAL(10,2) | 金额 |
| user_id | BIGINT FK | 用户ID |
| device_id | BIGINT FK | 设备ID |
| status | VARCHAR(20) | pending/paid/expired |
| expired_at | DATETIME | 过期时间 |
| paid_at | DATETIME | 支付时间 |
| created_at | DATETIME | 创建时间 |

---

## 4. 功能模块详细设计

### 4.1 手机端 App 功能

#### 4.1.1 触控板界面
- 全屏触控区域，模拟笔记本触控板
- 支持单指移动光标
- 支持单指点击/双击
- 支持双指滚动
- 支持双指右键菜单
- 支持三指手势（可自定义）
- 实时显示连接状态和电量

#### 4.1.2 连接管理
- 自动发现局域网内PC服务端
- 手动输入IP连接
- 连接密码保护（可选）
- 多设备快速切换
- 连接历史记录

#### 4.1.3 用户中心
- 登录/注册
- 身份证认证
- 设备绑定管理
- 年费状态查看
- 续费入口

#### 4.1.4 扫码支付
- 生成订单二维码
- 支付宝/微信扫码支付
- 支付状态实时更新
- 支付成功自动激活

### 4.2 PC端服务端功能

#### 4.2.1 鼠标控制核心
- 绝对坐标移动（基于屏幕分辨率）
- 相对坐标移动（平滑模式）
- 鼠标点击/双击/右键
- 滚轮滚动
- 拖拽操作
- 键盘输入转发（可选）

#### 4.2.2 网络服务
- TCP Socket服务器
- 自动端口映射（UPnP可选）
- 心跳保活
- 断线重连
- 多客户端支持

#### 4.2.3 系统托盘
- 最小化到托盘
- 连接状态指示
- 快捷设置
- 退出程序

#### 4.2.4 设置面板
- 服务端口配置
- 连接密码设置
- 开机自启
- 启动最小化
- 开机后延迟启动

### 4.3 后端服务器功能

#### 4.3.1 用户认证
- 用户注册（手机号+密码）
- 身份证号合法性校验（18位格式校验）
- 身份证实名认证（可选对接公安库）
- 登录认证（JWT Token）
- Token刷新机制

#### 4.3.2 设备管理
- 设备注册（IMEI/设备ID）
- 设备绑定到用户
- 设备解绑
- 设备状态管理
- 多设备支持（一用户多设备）

#### 4.3.3 订阅管理
- 创建订阅订单
- 查询订阅状态
- 订阅续费
- 订阅查询接口（供PC端验证）

#### 4.3.4 支付系统
- 生成支付二维码
- 支付宝当面付集成
- 微信支付Native集成
- 支付回调处理
- 订单状态管理

#### 4.3.5 管理后台 (可选)
- 用户管理
- 设备管理
- 订单管理
- 用户组管理
- 定价管理
- 统计数据

---

## 5. API接口设计

### 5.1 认证接口

#### POST /api/auth/register
```json
Request:
{
  "phone": "13800138000",
  "password": "xxxxxx",
  "name": "张三",
  "idCard": "110101199001011234"
}
Response:
{
  "code": 0,
  "msg": "success",
  "data": {
    "userId": 10001,
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

#### POST /api/auth/login
```json
Request:
{
  "phone": "13800138000",
  "password": "xxxxxx"
}
Response:
{
  "code": 0,
  "msg": "success",
  "data": {
    "userId": 10001,
    "token": "eyJhbGciOiJIUzI1NiIs...",
    "idCard": "110***********1234",
    "name": "张三",
    "userGroup": {
      "id": 1,
      "name": "普通用户",
      "annualFee": 99.00
    }
  }
}
```

### 5.2 设备接口

#### POST /api/device/register
```json
Request:
{
  "imei1": "861234567890123",
  "imei2": "861234567890124",
  "deviceName": "我的手机",
  "deviceModel": "Xiaomi 13",
  "osType": "android",
  "osVersion": "14"
}
Headers:
  Authorization: Bearer {token}
Response:
{
  "code": 0,
  "msg": "success",
  "data": {
    "deviceId": 20001,
    "bindToken": "abc123def456",
    "pcServicePort": 19876
  }
}
```

#### POST /api/device/bind
```json
Request:
{
  "bindToken": "abc123def456"
}
Headers:
  Authorization: Bearer {token}
Response:
{
  "code": 0,
  "msg": "绑定成功"
}
```

#### GET /api/device/list
```json
Headers:
  Authorization: Bearer {token}
Response:
{
  "code": 0,
  "data": [
    {
      "deviceId": 20001,
      "deviceName": "我的手机",
      "deviceModel": "Xiaomi 13",
      "status": 1,
      "lastActiveAt": "2026-04-18 10:00:00",
      "subscription": {
        "endDate": "2027-04-18",
        "status": "active"
      }
    }
  ]
}
```

### 5.3 订阅支付接口

#### POST /api/subscription/create-order
```json
Request:
{
  "deviceId": 20001
}
Headers:
  Authorization: Bearer {token}
Response:
{
  "code": 0,
  "data": {
    "orderNo": "SUB202604180001",
    "amount": 99.00,
    "discountAmount": 0.00,
    "qrCodeUrl": "https://xxx/qr/xxx",
    "expireMinutes": 30
  }
}
```

#### GET /api/subscription/status/{deviceId}
```json
Headers:
  Authorization: Bearer {token}
Response:
{
  "code": 0,
  "data": {
    "subscribed": true,
    "endDate": "2027-04-18",
    "daysRemaining": 365,
    "autoRenew": false
  }
}
```

### 5.4 PC端验证接口

#### GET /api/verify/subscription
```json
Query:
  deviceId=20001
  imei=861234567890123
Response:
{
  "code": 0,
  "data": {
    "valid": true,
    "endDate": "2027-04-18",
    "daysRemaining": 365
  }
}
```

---

## 6. 身份证号合法性校验规则

### 6.1 格式校验
1. 长度必须为18位
2. 前17位必须为数字
3. 第18位可以为数字或X/x

### 6.2 地区码校验
前6位为地区代码，需在已知地区码表中

### 6.3 出生日期校验
第7-14位为出生日期，格式YYYYMMDD，需为有效日期

### 6.4 校验码计算
```
加权因子: [7,9,10,5,8,4,2,1,6,3,7,9,10,5,8,4,2]
校验码:   ['1','0','X','9','8','7','6','5','4','3','2']

计算: Σ(ai × Wi) % 11 的映射值 == A18
```

---

## 7. 界面设计

### 7.1 手机端界面

#### 主界面 - 触控板
- 全屏深色主题
- 顶部状态栏（连接状态、电量、时间）
- 底部快捷操作栏（首页、设置）
- 触控区域无边界限制
- 手势提示动画

#### 连接界面
- 设备发现列表
- 手动输入IP输入框
- 连接历史（最近5个）
- 扫码添加设备

#### 用户中心
- 用户信息卡片
- 设备列表
- 年费状态
- 续费按钮
- 退出登录

### 7.2 PC端界面

#### 系统托盘菜单
- 连接状态（已连接X台设备）
- 当前连接设备列表
- 打开设置
- 启动/停止服务
- 退出

#### 设置窗口
- 基本设置（端口、密码）
- 外观设置
- 启动设置
- 关于

---

## 8. 安全设计

### 8.1 通信安全
- TCP连接使用自定义简单加密
- HTTP请求使用HTTPS
- Token使用JWT+签名

### 8.2 数据安全
- 身份证号存储使用哈希+盐值
- 密码使用BCrypt加密
- IMEI存储加密

### 8.3 设备绑定安全
- 首次注册需要绑定Token
- 绑定Token一次性使用
- 更换手机需要解绑原设备

---

## 9. 部署架构

### 9.1 开发环境
- 本地MySQL + Redis
- 本地后端服务
- 手机模拟器 + 物理PC

### 9.2 生产环境建议
```
┌────────────────────────────────────────────────────┐
│                    云服务器                          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐    │
│  │ Spring Boot│  │   MySQL    │  │    Redis   │    │
│  │  API服务   │  │   主库     │  │    缓存    │    │
│  └────────────┘  └────────────┘  └────────────┘    │
│       │                                          │
│       └──────── HTTPS 负载均衡 ─────────┘         │
└────────────────────────────────────────────────────┘
```

### 9.3 PC端分发
- 便携版exe（无需安装）
- MSI安装包
- 自动更新机制

---

## 10. 项目结构

```
LanMouse/
├── backend/                    # 后端服务器
│   ├── src/main/java/
│   │   └── com/lanmouse/
│   │       ├── controller/     # 控制器
│   │       ├── service/        # 服务层
│   │       ├── mapper/         # 数据访问
│   │       ├── entity/         # 实体类
│   │       ├── dto/            # 数据传输对象
│   │       ├── config/         # 配置类
│   │       └── util/           # 工具类
│   ├── src/main/resources/
│   │   ├── application.yml
│   │   └── mapper/
│   └── pom.xml
│
├── mobile/                     # 手机端 Flutter
│   ├── lib/
│   │   ├── main.dart
│   │   ├── pages/
│   │   │   ├── touchpad_page.dart
│   │   │   ├── connection_page.dart
│   │   │   ├── user_center_page.dart
│   │   │   └── payment_page.dart
│   │   ├── widgets/
│   │   ├── services/
│   │   │   ├── network_service.dart
│   │   │   ├── api_service.dart
│   │   │   └── socket_service.dart
│   │   └── models/
│   ├── pubspec.yaml
│   └── android/ios/
│
├── pc-server/                  # PC端服务端
│   ├── src/
│   │   ├── main.js
│   │   ├── mouse_control.js
│   │   ├── network_server.js
│   │   └── ui/
│   ├── package.json
│   └── electron/               # Electron相关
│
├── docs/                       # 文档
│   ├── API.md
│   ├── DATABASE.md
│   └── DEPLOY.md
│
└── README.md
```

---

## 11. 开发计划

### Phase 1 - 后端基础 (1周)
- [ ] 项目框架搭建
- [ ] 数据库设计与创建
- [ ] 用户认证模块
- [ ] 设备注册模块
- [ ] API接口测试

### Phase 2 - 后端业务 (1周)
- [ ] 订阅管理
- [ ] 支付二维码生成
- [ ] 支付回调处理
- [ ] Redis缓存集成

### Phase 3 - PC端 (1周)
- [ ] Electron项目搭建
- [ ] TCP Socket服务
- [ ] 鼠标控制核心
- [ ] 系统托盘
- [ ] 设置界面

### Phase 4 - 移动端 (2周)
- [ ] Flutter项目搭建
- [ ] 触控板界面
- [ ] 设备发现与连接
- [ ] 用户注册登录
- [ ] 扫码支付

### Phase 5 - 集成测试 (1周)
- [ ] 前后端联调
- [ ] 支付流程测试
- [ ] 多设备测试
- [ ] 性能优化

### Phase 6 - 部署上线 (1周)
- [ ] 服务器部署
- [ ] 应用签名
- [ ] 发布准备

---

## 12. 验收标准

### 功能验收
- [ ] 用户可使用身份证号注册并登录
- [ ] 设备可使用IMEI注册并绑定用户
- [ ] 一用户可绑定多设备
- [ ] 可生成支付二维码
- [ ] 扫码支付后可激活设备
- [ ] 不同用户组有不同定价
- [ ] 手机触控板可控制PC鼠标
- [ ] PC端无需安装即可运行（便携版）

### 性能验收
- [ ] 鼠标移动延迟 < 50ms
- [ ] 点击响应延迟 < 30ms
- [ ] API响应时间 < 200ms
- [ ] 支持至少10台设备同时连接

### 安全验收
- [ ] 身份证号正确加密存储
- [ ] 密码使用BCrypt加密
- [ ] API需认证访问
- [ ] Token有效期内可刷新
