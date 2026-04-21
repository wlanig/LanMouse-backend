#!/bin/bash
# 服务器诊断脚本

echo "=============================================="
echo "  LanMouse 服务器诊断"
echo "=============================================="
echo ""

# 1. 检查端口监听
echo "[1] 检查端口 8080 监听状态..."
netstat -tlnp | grep 8080 || echo "  端口 8080 未监听"
echo ""

# 2. 检查服务状态
echo "[2] 检查 lanmouse 服务状态..."
systemctl status lanmouse --no-pager 2>/dev/null || echo "  服务未安装"
echo ""

# 3. 检查防火墙
echo "[3] 检查防火墙状态..."
firewall-cmd --state 2>/dev/null || echo "  firewalld 未运行"
echo "  开放端口:"
firewall-cmd --list-ports 2>/dev/null || echo "  无"
echo ""

# 4. 检查进程
echo "[4] 检查 Java 进程..."
ps aux | grep java | grep -v grep || echo "  无 Java 进程"
echo ""

# 5. 检查日志
echo "[5] 最近日志..."
journalctl -u lanmouse -n 20 --no-pager 2>/dev/null || echo "  无日志"
echo ""

# 6. 检查目录
echo "[6] 检查应用目录..."
ls -la /opt/lanmouse/ 2>/dev/null || echo "  目录不存在"
echo ""

# 7. 检查JAR文件
echo "[7] 检查JAR文件..."
ls -la /opt/lanmouse/target/*.jar 2>/dev/null || echo "  未找到JAR文件"
echo ""

echo "=============================================="
echo "诊断完成"
echo "=============================================="
