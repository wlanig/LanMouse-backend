# LanMouse

手机触控板控制系统 — 用手机控制电脑鼠标，支持移动、点击、滚动、拖拽等操作。

## 系统架构

```
Mobile App (Flutter)  <---TCP:19876--->  PC Server (Electron)
       |                                        |
       +----------HTTP/REST----------+----------+
                                    Backend (Spring Boot)
                                    MySQL + Redis
```

| 通信链路 | 协议 | 说明 |
|----------|------|------|
| Mobile ↔ Backend | HTTP/REST | 登录注册、设备管理、订阅支付 (`/api/*`) |
| Mobile ↔ PC Server | TCP (19876) | JSON 消息，鼠标控制、认证握手、心跳 |
| Mobile → PC Server | UDP (19877) | 局域网服务发现广播 |
| PC Server → Backend | HTTP | `GET /api/verify/subscription` 验证订阅 |

## 项目结构

```
LanMouse/
├── backend/            # Spring Boot 后端
│   ├── src/            # Java 源码
│   └── sql/            # 数据库初始化脚本
├── mobile/             # Flutter 移动端
│   └── lib/            # Dart 源码
├── pc-server/          # Electron PC 服务端
│   ├── main.js         # Electron 主进程
│   ├── tcp_server.js   # TCP Socket 服务器
│   ├── mouse_controller.py  # Python 鼠标控制器
│   └── preload.js      # 安全上下文桥
└── deploy_package/     # 部署包（与 backend 同步）
```

## 快速开始

### 环境要求

| 组件 | 版本 |
|------|------|
| JDK | 17+ |
| MySQL | 8.0+ |
| Redis | 6.0+ |
| Flutter | 3.x (SDK >=3.0.0 <4.0.0) |
| Node.js | 18+ |
| Python | 3.7+ |

### Backend

```bash
cd backend

# 初始化数据库
mysql -u root -p < sql/init.sql

# 启动（开发模式）
./mvnw spring-boot:run

# 或打包运行
mvn clean package -DskipTests
java -jar target/lanmouse-backend-1.0.0.jar
```

### Mobile

```bash
cd mobile

flutter pub get
flutter run -d windows    # Windows 桌面
flutter run               # Android/iOS
flutter build apk --release
```

### PC Server

```bash
cd pc-server

npm install
npm start                 # 生产模式
npm run dev               # 开发模式（带日志）
npm run build             # 打包分发
```

## 关键端口

| 端口 | 协议 | 用途 |
|------|------|------|
| 8080 | HTTP | Backend REST API |
| 19876 | TCP | PC Server 鼠标控制 Socket |
| 19877 | UDP | 局域网服务发现广播 |

## 数据库

数据库名 `lanmouse`，包含以下表：

- `users` — 用户信息
- `user_groups` — 用户组
- `devices` — 设备信息
- `subscriptions` — 订阅记录
- `payment_qr_codes` — 支付二维码

初始化脚本：`backend/sql/init.sql`

## API 响应格式

```json
{"code": 0, "msg": "success", "data": {...}}
```

错误码：`0` 成功 | `1xxx` 参数错误 | `2xxx` 认证错误 | `3xxx` 设备错误 | `4xxx` 订单错误 | `5xxx` 权限错误

## 编码规范

- **Java**: Google Java Style Guide, Lombok, camelCase
- **Dart/Flutter**: Dart Style Guide, PascalCase for widgets
- **JavaScript**: Airbnb Style Guide, ES6+
- **Git**: Conventional Commits (`feat:`, `fix:`, `chore:` 等)
- **分支**: `main`, `develop`, `feature/*`, `fix/*`
