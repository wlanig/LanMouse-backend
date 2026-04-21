# LanMouse 后端部署指南

## 服务器信息
- IP: `120.77.81.144`
- 用户: `root`
- 密码: `740528@Ww`

---

## 方式一：一键部署（推荐）

### 第一步：在本地Windows上打包

```powershell
# 进入项目目录
cd d:\CodeBuddy_Project\LanMouse\backend

# 打包项目
mvn clean package -DskipTests
```

### 第二步：将JAR文件上传到服务器

使用以下任一方式上传 `d:\CodeBuddy_Project\LanMouse\backend\target\lanmouse-backend-1.0.0.jar`：

**方法A: SCP命令**
```powershell
scp d:\CodeBuddy_Project\LanMouse\backend\target\lanmouse-backend-1.0.0.jar root@120.77.81.144:/opt/lanmouse/
```

**方法B: 使用WinSCP图形工具**
1. 下载 WinSCP: https://winscp.net/
2. 连接服务器，上传JAR文件到 `/opt/lanmouse/`

**方法C: 使用PowerShell远程执行**
```powershell
# 本地执行
$session = New-PSSession -HostName 120.77.81.144 -UserName root
Copy-Item "d:\CodeBuddy_Project\LanMouse\backend\target\lanmouse-backend-1.0.0.jar" -Destination "/opt/lanmouse/" -ToSession $session
```

### 第三步：在服务器上执行部署脚本

通过SSH连接到服务器：
```bash
ssh root@120.77.81.144
```

上传并执行部署脚本：
```bash
# 创建部署脚本
cat > /tmp/deploy.sh << 'SCRIPT_EOF'
#!/bin/bash
# [粘贴 server_deploy.sh 的内容]
SCRIPT_EOF

# 执行脚本
chmod +x /tmp/deploy.sh
bash /tmp/deploy.sh
```

---

## 方式二：手动分步部署

### 1. 连接服务器
```bash
ssh root@120.77.81.144
```

### 2. 安装Java 17
```bash
yum install -y java-17-openjdk java-17-openjdk-devel
java -version
```

### 3. 安装MySQL 8
```bash
# CentOS 7
rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el7-7.noarch.rpm
yum install -y mysql-community-server

# CentOS 8/Rocky
rpm -Uvh https://dev.mysql.com/get/mysql80-community-release-el8-5.noarch.rpm
dnf install -y mysql-community-server

systemctl enable mysqld
systemctl start mysqld
```

### 4. 安装Redis
```bash
yum install -y redis
systemctl enable redis
systemctl start redis
```

### 5. 配置MySQL
```bash
# 设置root密码
mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '740528@Ww';"

# 创建数据库和用户
mysql -u root -p'740528@Ww' < /opt/lanmouse/sql/init.sql
```

### 6. 上传JAR文件
```bash
# 在本地Windows执行
scp d:\CodeBuddy_Project\LanMouse\backend\target\lanmouse-backend-1.0.0.jar root@120.77.81.144:/opt/lanmouse/
```

### 7. 创建systemd服务
```bash
cat > /etc/systemd/system/lanmouse.service << 'EOF'
[Unit]
Description=LanMouse Backend Service
After=network.target mysqld.service redis.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/lanmouse
ExecStart=/usr/bin/java -jar -Xms256m -Xmx512m /opt/lanmouse/lanmouse-backend-1.0.0.jar
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable lanmouse
```

### 8. 启动服务
```bash
systemctl start lanmouse
systemctl status lanmouse
```

### 9. 检查服务
```bash
curl http://localhost:8080/api/health
```

---

## 服务管理命令

```bash
# 查看状态
systemctl status lanmouse

# 启动服务
systemctl start lanmouse

# 停止服务
systemctl stop lanmouse

# 重启服务
systemctl restart lanmouse

# 查看日志
journalctl -u lanmouse -f

# 查看应用日志
tail -f /var/log/lanmouse/application.log
```

---

## 验证部署

### API端点测试

```bash
# 健康检查
curl http://120.77.81.144:8080/api/health

# 用户注册
curl -X POST http://120.77.81.144:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13900000001","password":"123456","name":"测试用户","idCard":"110101199001011234"}'

# 用户登录
curl -X POST http://120.77.81.144:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456"}'

# 测试账号: 13800138000 / 123456
```

---

## 防火墙配置

```bash
# 开放端口
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --reload

# 或使用 iptables
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
```

---

## 常见问题

### 1. MySQL启动失败
```bash
# 查看错误日志
cat /var/log/mysqld.log | grep ERROR

# 临时密码
grep 'temporary password' /var/log/mysqld.log
```

### 2. 服务启动失败
```bash
# 查看Java进程错误
journalctl -u lanmouse -n 100

# 检查端口占用
netstat -tlnp | grep 8080
```

### 3. 数据库连接失败
```bash
# 测试MySQL连接
mysql -u lanmouse -p'LanMouse@2024' -h localhost

# 检查用户权限
mysql -u root -p'740528@Ww' -e "SHOW GRANTS FOR 'lanmouse'@'localhost';"
```
