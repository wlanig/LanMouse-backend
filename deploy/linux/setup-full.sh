#!/bin/bash
# LanMouse 全功能部署脚本

echo "========================================"
echo "LanMouse 全功能部署开始"
echo "========================================"

# 1. 安装 Nginx
echo "[1/6] 安装 Nginx..."
yum install -y nginx > /dev/null 2>&1
systemctl enable nginx
systemctl start nginx

# 2. 配置 Nginx 反向代理
echo "[2/6] 配置 Nginx..."
cat > /etc/nginx/conf.d/lanmouse.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
NGINX_EOF

nginx -t && systemctl reload nginx

# 3. 配置 SSL（自签名证书，用于 HTTPS）
echo "[3/6] 配置 HTTPS..."
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/lanmouse.key \
    -out /etc/nginx/ssl/lanmouse.crt \
    -subj "/C=CN/ST=Beijing/L=Beijing/O=LanMouse" > /dev/null 2>&1

cat > /etc/nginx/conf.d/lanmouse-ssl.conf << 'SSL_EOF'
server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/lanmouse.crt;
    ssl_certificate_key /etc/nginx/ssl/lanmouse.key;
    
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
SSL_EOF

nginx -t && systemctl reload nginx

# 4. 配置日志
echo "[4/6] 配置日志..."
cat >> /opt/lanmouse/application.yml << 'LOG_EOF'

logging:
  file:
    name: /var/log/lanmouse/application.log
  level:
    com.lanmouse: INFO
LOG_EOF

mkdir -p /var/log/lanmouse

# 5. 创建数据库备份脚本
echo "[5/6] 创建数据库备份..."
cat > /opt/lanmouse/backup.sh << 'BACKUP_EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/lanmouse/backups"
mkdir -p $BACKUP_DIR
mysqldump -u root -p'740528@Ww' lanmouse > $BACKUP_DIR/lanmouse_$DATE.sql
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
echo "Backup saved: $BACKUP_DIR/lanmouse_$DATE.sql"
BACKUP_EOF

chmod +x /opt/lanmouse/backup.sh

# 6. 重启服务
echo "[6/6] 重启服务..."
pkill -f lanmouse
cd /opt/lanmouse && nohup java -jar target/lanmouse-1.0.0.jar > /tmp/lanmouse.log 2>&1 &

sleep 5

echo ""
echo "========================================"
echo "部署完成！"
echo "========================================"
echo ""
echo "访问地址："
echo "  HTTP:  http://120.77.81.144"
echo "  HTTPS: https://120.77.81.144"
echo ""
echo "API 接口："
echo "  http://120.77.81.144/api/health"
echo "  http://120.77.81.144/api/auth/login"
echo ""
echo "管理页面："
echo "  http://120.77.81.144/"
echo ""
echo "数据库备份："
echo "  /opt/lanmouse/backup.sh"
echo ""
