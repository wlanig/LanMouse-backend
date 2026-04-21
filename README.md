# LanMouse - 手机触控板控制系统

一款通过手机模拟笔记本电脑触控板，实现通过网络远程控制PC鼠标的系统。

## 功能特性

- 📱 **跨平台手机App** - 支持Android和iOS
- 🖱️ **触控板控制** - 单指移动、双指滚动、右键菜单
- 🌐 **局域网直连** - 无需互联网，通过局域网IP连接
- 👤 **身份证认证** - 安全可靠的用户身份验证
- 📅 **年费订阅** - 支持扫码支付续费
- 👥 **多设备管理** - 一用户可绑定多部手机
- 💰 **用户分组定价** - 不同用户群体不同收费标准

## 系统架构

```
┌─────────────────┐      ┌─────────────────┐
│   手机端 App     │ ◄──► │   PC端服务端    │
│  (触控板界面)    │  TCP │  (鼠标控制)     │
└────────┬────────┘      └────────┬────────┘
         │                        │
         │ HTTP/REST               │
         ▼                        │
┌─────────────────────────────────┴─────────┐
│              后端服务器                     │
│  Spring Boot + MySQL + Redis              │
└───────────────────────────────────────────┘
```

## 技术栈

| 组件 | 技术 |
|------|------|
| 手机端 | Flutter |
| PC端 | Electron + Node.js + Python |
| 后端 | Spring Boot 2.7 + Java 17 |
| 数据库 | MySQL 8.0 |
| 缓存 | Redis |

## 目录结构

```
LanMouse/
├── backend/          # 后端服务器 (Spring Boot)
├── mobile/           # 手机端 (Flutter)
├── pc-server/        # PC端 (Electron)
├── docs/             # 文档
└── README.md
```

## 快速开始

### 1. 后端服务器

```bash
cd backend
# 创建数据库
mysql -u root -p < sql/init.sql
# 启动服务
./mvnw spring-boot:run
```

### 2. PC端

```bash
cd pc-server
npm install
npm start
```

### 3. 手机端

```bash
cd mobile
flutter pub get
flutter run
```

## API文档

详见 [docs/API.md](docs/API.md)

## 数据库设计

详见 [docs/DATABASE.md](docs/DATABASE.md)

## 部署指南

详见 [docs/DEPLOY.md](docs/DEPLOY.md)

## 网络协议

### 触控板控制协议 (TCP)

端口: 19876

```json
{
  "type": "mouse_move",
  "x": 50,
  "y": 50,
  "dx": 5,
  "dy": -3,
  "button": "left",
  "timestamp": 1713408000000
}
```

## 许可证

MIT License
