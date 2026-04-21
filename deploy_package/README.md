# LanMouse 后端一键部署指南

## 服务器信息
- **IP**: 120.77.81.144
- **用户**: root
- **密码**: 740528@Ww

---

## 部署步骤

### 第一步：上传部署包到服务器

在本地 Windows 打开 PowerShell，执行以下命令：

```powershell
# 上传整个部署包到服务器
scp -r d:\CodeBuddy_Project\LanMouse\deploy_package\* root@120.77.81.144:/opt/lanmouse/
```

或者分步上传：
```powershell
# 上传源码
scp -r d:\CodeBuddy_Project\LanMouse\deploy_package\* root@120.77.81.144:/opt/lanmouse/
```

### 第二步：SSH 连接到服务器

```bash
ssh root@120.77.81.144
# 密码: 740528@Ww
```

### 第三步：执行一键部署

```bash
cd /opt/lanmouse
chmod +x deploy.sh
bash deploy.sh
```

脚本会自动完成以下工作：
1. ✅ 安装 Java 17
2. ✅ 安装 Maven 3.9
3. ✅ 安装 MySQL 8
4. ✅ 安装 Redis
5. ✅ 配置数据库和用户
6. ✅ 初始化数据库表
7. ✅ 编译项目
8. ✅ 创建系统服务
9. ✅ 启动服务

### 第四步：验证部署

部署完成后，执行以下命令验证：

```bash
# 检查服务状态
systemctl status lanmouse

# 测试健康检查
curl http://localhost:8080/api/health

# 查看日志
journalctl -u lanmouse -f
```

---

## 部署完成后的信息

| 项目 | 值 |
|------|-----|
| 服务地址 | http://120.77.81.144:8080 |
| 健康检查 | http://120.77.81.144:8080/api/health |
| 测试手机号 | 13800138000 |
| 测试密码 | 123456 |

---

## 服务管理命令

```bash
# 启动服务
systemctl start lanmouse

# 停止服务
systemctl stop lanmouse

# 重启服务
systemctl restart lanmouse

# 查看状态
systemctl status lanmouse

# 查看实时日志
journalctl -u lanmouse -f

# 卸载服务
systemctl disable lanmouse
systemctl stop lanmouse
rm /etc/systemd/system/lanmouse.service
systemctl daemon-reload
```

---

## API 测试

```bash
# 健康检查
curl http://120.77.81.144:8080/api/health

# 用户登录 (测试账号)
curl -X POST http://120.77.81.144:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456"}'
```

---

## 防火墙配置

如果无法访问端口，需要开放防火墙：

```bash
# 开放端口
firewall-cmd --permanent --add-port=8080/tcp

# 重载防火墙
firewall-cmd --reload

# 或关闭防火墙（测试环境）
systemctl stop firewalld
systemctl disable firewalld
```

---

## 常见问题

### Q1: 部署脚本执行失败
```bash
# 查看详细错误
bash -x deploy.sh
```

### Q2: MySQL 连接失败
```bash
# 检查MySQL状态
systemctl status mysqld

# 查看MySQL日志
cat /var/log/mysqld.log | grep ERROR
```

### Q3: 端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep 8080

# 杀死占用进程
kill -9 <PID>
```

### Q4: 编译超时
```bash
# Maven 可能需要较长时间下载依赖
# 可以设置超时时间或使用代理
export MAVEN_OPTS="-Dmaven.wagon.http.retryHandler.count=3"
```
