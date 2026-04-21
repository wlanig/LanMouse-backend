# LanMouse 项目统计

## 代码统计

| 模块 | 文件数 | 主要文件类型 |
|------|--------|-------------|
| 后端 | 48 | Java, XML, SQL |
| 移动端 | 35 | Dart, YAML, Gradle |
| PC端 | 10 | JavaScript, Python, HTML |
| 文档 | 4 | Markdown |
| **总计** | **97** | |

## 功能模块

### 后端 (Spring Boot)
- [x] 用户认证 (注册/登录/JWT)
- [x] 身份证号校验 (18位格式/地区码/生日/校验码)
- [x] 设备管理 (注册/绑定/解绑)
- [x] 订阅管理 (创建订单/支付回调)
- [x] 支付二维码生成
- [x] 用户组和定价管理
- [x] Redis缓存
- [x] CORS跨域

### 移动端 (Flutter)
- [x] 触控板界面 (单指移动/双指滚动)
- [x] 设备发现 (UDP广播)
- [x] TCP Socket连接
- [x] 用户注册/登录
- [x] 设备绑定管理
- [x] 扫码支付
- [x] 深色主题UI

### PC端 (Electron)
- [x] TCP Socket服务器
- [x] 系统托盘
- [x] 鼠标控制 (pyautogui/ctypes)
- [x] 多设备支持
- [x] 密码保护
- [x] 开机自启
- [x] 设置面板

## 数据库表
- [x] users (用户表)
- [x] user_groups (用户组表)
- [x] devices (设备表)
- [x] subscriptions (订阅表)
- [x] payment_qr_codes (支付二维码表)

## API接口
- [x] POST /api/auth/register
- [x] POST /api/auth/login
- [x] POST /api/auth/refresh
- [x] GET /api/auth/me
- [x] POST /api/device/register
- [x] POST /api/device/bind
- [x] GET /api/device/list
- [x] POST /api/subscription/create-order
- [x] GET /api/subscription/status/{deviceId}
- [x] GET /api/verify/subscription

## 待完成项

### 高优先级
- [ ] 真实支付接口集成 (支付宝/微信)
- [ ] 身份证实名认证对接

### 中优先级
- [ ] iOS真机测试
- [ ] PC端安装包签名
- [ ] 自动更新机制

### 低优先级
- [ ] 管理后台
- [ ] 数据统计面板
- [ ] 客服系统集成
