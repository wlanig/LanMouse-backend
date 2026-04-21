#!/bin/bash
# LanMouse 自动调试脚本 - 在服务器上运行

LOG_FILE="/tmp/lanmouse-debug.log"
APP_DIR="/opt/lanmouse"
PASS="740528@Ww"

echo "========================================" > $LOG_FILE
echo "LanMouse 自动调试开始 $(date)" >> $LOG_FILE
echo "========================================" >> $LOG_FILE

# 1. 修复数据库字段
echo -e "\n[1] 修复数据库字段..." >> $LOG_FILE
mysql -u root -p"$PASS" -e "USE lanmouse; 
ALTER TABLE users MODIFY name VARCHAR(50) NULL;
ALTER TABLE users MODIFY id_card_hash VARCHAR(255) NULL;
ALTER TABLE users MODIFY wx_openid VARCHAR(100) NULL;
ALTER TABLE users MODIFY avatar_url VARCHAR(255) NULL;" 2>&1 >> $LOG_FILE

# 2. 检查并启动服务
echo -e "\n[2] 检查服务状态..." >> $LOG_FILE
if pgrep -f lanmouse-1.0.0.jar > /dev/null; then
    echo "服务已运行" >> $LOG_FILE
else
    echo "启动服务..." >> $LOG_FILE
    cd $APP_DIR && nohup java -jar target/lanmouse-1.0.0.jar > /tmp/lanmouse.log 2>&1 &
    sleep 10
fi

# 3. 健康检查
echo -e "\n[3] 健康检查..." >> $LOG_FILE
curl -s http://localhost:8080/api/health >> $LOG_FILE 2>&1

# 4. 测试注册
echo -e "\n[4] 测试注册..." >> $LOG_FILE
curl -s -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138999","password":"123456","email":"test@test.com"}' >> $LOG_FILE 2>&1

# 5. 测试登录
echo -e "\n[5] 测试登录..." >> $LOG_FILE
curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138999","password":"123456"}' >> $LOG_FILE 2>&1

# 6. 查看错误日志
echo -e "\n[6] 最新日志..." >> $LOG_FILE
tail -30 /tmp/lanmouse.log >> $LOG_FILE 2>&1

echo -e "\n========================================" >> $LOG_FILE
echo "调试完成 $(date)" >> $LOG_FILE
echo "========================================" >> $LOG_FILE

cat $LOG_FILE
