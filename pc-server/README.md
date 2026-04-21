# LanMouse PC服务端

LanMouse手机触控板控制系统的PC端服务端，用于接收手机端的触控板指令并控制鼠标。

## 功能特性

- **鼠标控制** - 支持移动、点击、双击、右键菜单、滚动、拖拽
- **TCP Socket服务** - 监听端口19876，接收手机端连接
- **系统托盘** - 最小化到托盘运行，后台服务
- **密码保护** - 可设置连接密码，防止未授权访问
- **多设备支持** - 同时支持多台手机连接
- **跨平台** - 支持Windows、macOS、Linux

## 系统要求

### Windows
- Windows 7 或更高版本
- Python 3.7+ (用于鼠标控制，Windows自带ctypes可无需安装)

### macOS
- macOS 10.10 或更高版本
- Python 3.7+ (可选，使用pyautogui)
- 终端权限（用于鼠标控制）

### Linux
- Ubuntu 18.04 或类似发行版
- Python 3.7+
- xdotool 或 pyautogui

## 安装运行

### 方式一：直接运行（开发模式）

1. 确保已安装 Node.js 18+
2. 克隆项目并进入目录
3. 安装依赖：
```bash
npm install
```

4. 启动应用：
```bash
npm start
```

### 方式二：打包为可执行文件

```bash
npm run build
```

打包后的文件将位于 `dist/` 目录。

### 方式三：便携版

下载预编译的便携版exe，双击即可运行，无需安装。

## 网络连接

### 默认配置
- 端口: 19876
- 协议: TCP Socket
- 编码: UTF-8

### 手机端连接
1. 确保手机和PC在同一局域网
2. 在手机App中输入PC的局域网IP地址
3. 如果设置了密码，输入密码
4. 点击连接

### 防火墙设置
如果连接失败，可能需要允许应用通过防火墙：

**Windows:**
```powershell
# 以管理员身份运行
netsh advfirewall firewall add rule name="LanMouse" dir=in action=allow protocol=TCP localport=19876
```

**macOS/Linux:**
```bash
# iptables
sudo iptables -A INPUT -p tcp --dport 19876 -j ACCEPT

# 或使用ufw
sudo ufw allow 19876/tcp
```

## 触控板协议

手机端发送的JSON消息格式：

### 连接握手
```json
{
  "type": "auth",
  "password": "123456",
  "deviceName": "我的手机"
}
```

### 鼠标移动
```json
{
  "type": "mouse_move",
  "x": 50,        // 绝对坐标 0-100
  "y": 50,        // 绝对坐标 0-100
  "mode": "absolute"
}
```

### 鼠标点击
```json
{
  "type": "mouse_click",
  "button": "left",  // left/right/middle
  "x": 50,
  "y": 50,
  "double": false
}
```

### 鼠标滚动
```json
{
  "type": "mouse_scroll",
  "scrollY": 10    // 正数向上，负数向下
}
```

### 心跳
```json
{
  "type": "heartbeat",
  "timestamp": 1713408000000
}
```

## 托盘菜单

- **显示主窗口** - 打开设置界面
- **设置** - 打开设置面板
- **启动/停止服务** - 控制TCP服务
- **退出** - 完全退出应用

## 快捷键

| 功能 | 快捷键 |
|------|--------|
| 显示/隐藏主窗口 | 点击托盘图标 |
| 打开设置 | 托盘菜单 → 设置 |
| 退出应用 | 托盘菜单 → 退出 |

## 配置文件

配置文件存储在用户数据目录：
- Windows: `%APPDATA%/lanmouse-pc-server/`
- macOS: `~/Library/Application Support/lanmouse-pc-server/`
- Linux: `~/.config/lanmouse-pc-server/`

配置文件 `config.json`:
```json
{
  "port": 19876,
  "password": "",
  "autoStart": false,
  "startMinimized": false,
  "debugMode": false
}
```

## 日志

日志文件位置：
- Windows: `%APPDATA%/lanmouse-pc-server/logs/`
- macOS: `~/Library/Logs/lanmouse-pc-server/`
- Linux: `~/.config/lanmouse-pc-server/logs/`

日志文件包含：
- 连接日志
- 错误日志
- 调试信息

## 常见问题

### Q: 连接失败？
A: 检查以下内容：
1. 手机和PC是否在同一局域网
2. 防火墙是否允许19876端口
3. PC的IP地址是否正确
4. 是否设置了密码，输入是否正确

### Q: 鼠标移动延迟高？
A: 检查网络质量，确保局域网连接稳定。

### Q: 无法控制鼠标？
A: 确保Python鼠标控制器正常启动，可以在设置中查看状态。

### Q: macOS提示权限问题？
A: 在系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能 中添加本应用。

## 开发

### 项目结构
```
pc-server/
├── main.js           # Electron主进程
├── preload.js        # 预加载脚本
├── index.html        # 主界面
├── tcp_server.js     # TCP Socket服务器
├── mouse_controller.py # Python鼠标控制器
├── renderer/         # 渲染进程代码
│   ├── app.js
│   └── styles.css
├── assets/           # 资源文件
│   └── icon.ico
└── package.json
```

### 构建命令
```bash
npm run dev      # 开发模式
npm run build    # 构建
npm run pack     # 快速打包
```

## 许可证

MIT License
