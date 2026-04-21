# LanMouse - 手机触控板控制系统

LanMouse 是一款基于 Flutter 开发的手机触控板控制系统，允许用户通过手机模拟笔记本电脑触控板，实现远程控制 PC 鼠标的功能。

## 功能特性

### 1. 触控板界面
- 全屏触控区域，模拟笔记本触控板
- 单指移动光标
- 单指点击/双击
- 双指滚动
- 双指右键菜单
- 实时显示连接状态

### 2. 连接管理
- 自动发现局域网内 PC 服务端 (UDP 广播)
- 手动输入 IP 连接
- 连接密码保护
- 连接历史记录

### 3. 用户中心
- 登录/注册界面
- 身份证号认证
- 设备绑定管理
- 年费状态查看
- 续费入口

### 4. 扫码支付
- 生成订单
- 显示支付二维码
- 支付状态轮询

## 技术栈

- **框架**: Flutter 3.x
- **状态管理**: Provider
- **HTTP 请求**: http
- **Socket 通信**: socket_io_client
- **本地存储**: shared_preferences
- **二维码生成**: qr_flutter
- **设备信息**: device_info_plus

## 项目结构

```
mobile/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── config/
│   │   ├── app_config.dart       # 应用配置
│   │   └── app_theme.dart        # 主题配置
│   ├── models/
│   │   ├── user.dart             # 用户模型
│   │   ├── device.dart            # 设备模型
│   │   ├── mouse_control.dart    # 鼠标控制消息模型
│   │   ├── pc_server.dart        # PC 服务器模型
│   │   └── order.dart            # 订单模型
│   ├── services/
│   │   ├── api_service.dart      # API 服务
│   │   ├── socket_service.dart   # Socket 连接服务
│   │   ├── discovery_service.dart # UDP 发现服务
│   │   └── storage_service.dart  # 本地存储服务
│   ├── providers/
│   │   ├── user_provider.dart    # 用户状态管理
│   │   ├── connection_provider.dart # 连接状态管理
│   │   ├── touchpad_provider.dart   # 触控板状态管理
│   │   ├── device_provider.dart    # 设备状态管理
│   │   └── payment_provider.dart   # 支付状态管理
│   ├── pages/
│   │   ├── home_page.dart        # 主页
│   │   ├── touchpad_page.dart    # 触控板页面
│   │   ├── connection_page.dart  # 连接管理页面
│   │   ├── user_center_page.dart # 用户中心页面
│   │   ├── login_page.dart       # 登录/注册页面
│   │   └── payment_page.dart     # 支付页面
│   ├── widgets/
│   │   ├── status_bar.dart       # 状态栏组件
│   │   ├── touchpad_widget.dart  # 触控板组件
│   │   └── device_card.dart      # 设备卡片组件
│   └── utils/
│       ├── id_card_validator.dart # 身份证验证工具
│       └── validators.dart        # 通用验证工具
├── android/                       # Android 配置
├── ios/                           # iOS 配置
└── pubspec.yaml                   # 依赖配置
```

## 通信协议

### 手机 → PC 控制协议 (TCP Socket)

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

### HTTP REST API

- POST /api/auth/register - 用户注册
- POST /api/auth/login - 用户登录
- POST /api/device/register - 设备注册
- GET /api/device/list - 获取设备列表
- POST /api/subscription/create-order - 创建订单
- GET /api/subscription/status/{deviceId} - 获取订阅状态

## 开发环境

### 前提条件

- Flutter SDK >= 3.0.0
- Android Studio / Xcode
- Dart SDK

### 安装依赖

```bash
cd mobile
flutter pub get
```

### 运行应用

```bash
# 调试模式
flutter run

# Release 模式
flutter run --release
```

### 构建 APK

```bash
flutter build apk --release
```

### 构建 iOS

```bash
flutter build ios --release
```

## 配置说明

### API 服务器

在 `lib/config/app_config.dart` 中修改 `apiBaseUrl` 为实际的服务器地址：

```dart
static const String apiBaseUrl = 'http://your-api-server.com';
```

### PC 服务端端口

默认端口为 19876，可在 `app_config.dart` 中修改：

```dart
static const int pcServicePort = 19876;
```

## UI 设计

- 深色主题
- Material Design 3
- 全屏触控板
- 顶部状态栏（连接状态）
- 底部导航（触控板、连接、我的）

## 许可证

本项目仅供学习交流使用。

## 联系方式

如有问题，请提交 Issue。
