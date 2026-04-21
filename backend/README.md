# LanMouse 后端服务

## 技术栈
- Spring Boot 2.7.18
- Java 17
- MyBatis-Plus 3.5.3.1
- MySQL 8.0
- Redis
- JWT

## 项目结构

```
backend/
├── src/main/java/com/lanmouse/
│   ├── LanmouseApplication.java    # 主启动类
│   ├── controller/                  # 控制器层
│   │   ├── AuthController.java      # 认证接口
│   │   ├── DeviceController.java     # 设备接口
│   │   ├── SubscriptionController.java  # 订阅接口
│   │   └── VerifyController.java     # PC端验证接口
│   ├── service/                      # 服务层
│   │   ├── UserService.java
│   │   ├── DeviceService.java
│   │   └── SubscriptionService.java
│   ├── service/impl/                 # 服务实现
│   ├── mapper/                       # 数据访问层
│   ├── entity/                       # 实体类
│   ├── util/                         # 工具类
│   └── config/                       # 配置类
├── src/main/resources/
│   ├── application.yml               # 应用配置
│   └── mapper/                       # MyBatis XML
├── sql/
│   └── init.sql                      # 数据库初始化脚本
└── pom.xml
```

## 快速开始

### 1. 环境要求
- JDK 17+
- MySQL 8.0+
- Redis 6.0+

### 2. 数据库初始化
```bash
mysql -u root -p < sql/init.sql
```

### 3. 修改配置文件
编辑 `src/main/resources/application.yml`，修改数据库和Redis配置：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/lanmouse?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false
    username: root
    password: your_password

  redis:
    host: localhost
    port: 6379
    password: your_redis_password
```

### 4. 启动服务
```bash
# Maven方式
./mvnw spring-boot:run

# 或打包后运行
./mvnw clean package
java -jar target/lanmouse-backend-1.0.0.jar
```

服务启动后，API服务运行在 http://localhost:8080

## API接口

### 认证接口

#### 用户注册
```
POST /api/auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456",
  "name": "张三",
  "idCard": "110101199001011234"
}
```

#### 用户登录
```
POST /api/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456"
}
```

### 设备接口

#### 注册设备
```
POST /api/device/register
Authorization: Bearer {token}
Content-Type: application/json

{
  "imei1": "861234567890123",
  "deviceName": "我的手机",
  "deviceModel": "Xiaomi 13",
  "osType": "android",
  "osVersion": "14"
}
```

#### 绑定设备
```
POST /api/device/bind
Authorization: Bearer {token}
Content-Type: application/json

{
  "bindToken": "abc123def456"
}
```

#### 获取设备列表
```
GET /api/device/list
Authorization: Bearer {token}
```

### 订阅接口

#### 创建订单
```
POST /api/subscription/create-order
Authorization: Bearer {token}
Content-Type: application/json

{
  "deviceId": 20001
}
```

#### 查询订阅状态
```
GET /api/subscription/status/{deviceId}
Authorization: Bearer {token}
```

### PC端验证接口

#### 验证订阅
```
GET /api/verify/subscription?deviceId=20001&imei=861234567890123
```

## 身份证号校验

后端实现了完整的18位身份证号校验：

1. **格式校验** - 17位数字 + 1位校验码(数字或X)
2. **地区码校验** - 前2位为有效省份代码
3. **出生日期校验** - 第7-14位格式为YYYYMMDD，且为有效日期
4. **校验码计算** - 使用加权求和模11算法验证

## JWT Token

- 有效期: 24小时
- 刷新有效期: 7天
- Token格式: Bearer Token

## 测试账号

- 手机号: 13800138000
- 密码: 123456

## 开发指南

### 添加新接口
1. 在 `controller/` 创建 Controller 类
2. 在 `service/` 创建 Service 接口
3. 在 `service/impl/` 创建实现类
4. 在 `mapper/` 创建 Mapper 接口

### 添加新实体
1. 在 `entity/` 创建 Entity 类
2. 使用 MyBatis-Plus 注解配置映射
3. 在 Mapper 接口继承 BaseMapper

## 许可证

MIT License
