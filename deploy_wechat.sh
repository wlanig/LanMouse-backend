#!/bin/bash
# LanMouse 微信登录功能部署脚本
# 在服务器上执行: chmod +x deploy_wechat.sh && ./deploy_wechat.sh

set -e

echo "=========================================="
echo "LanMouse 微信登录功能部署脚本"
echo "=========================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置
PROJECT_DIR="/opt/lanmouse"
JAR_FILE="$PROJECT_DIR/target/lanmouse-backend-1.0.0.jar"
SQL_FILE="$PROJECT_DIR/sql/add_openid.sql"

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 权限运行此脚本 (sudo ./deploy_wechat.sh)${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] 检查当前服务状态...${NC}"
systemctl status lanmouse --no-pager || true

echo -e "${YELLOW}[2/5] 停止服务...${NC}"
systemctl stop lanmouse
sleep 2

echo -e "${YELLOW}[3/5] 执行数据库更新...${NC}"
if [ -f "$SQL_FILE" ]; then
    echo "执行数据库更新脚本..."
    mysql -u root -p lanmouse << EOF
-- 添加 openid 字段
ALTER TABLE users ADD COLUMN IF NOT EXISTS openid VARCHAR(128) DEFAULT NULL COMMENT '微信openid' AFTER password_hash;

-- 创建唯一索引
ALTER TABLE users ADD UNIQUE INDEX idx_openid (openid);
EOF
    echo -e "${GREEN}数据库更新完成${NC}"
else
    echo -e "${YELLOW}SQL文件不存在，跳过数据库更新${NC}"
fi

echo -e "${YELLOW}[4/5] 重新打包项目...${NC}"
cd $PROJECT_DIR
mvn clean package -DskipTests -q

if [ ! -f "$JAR_FILE" ]; then
    echo -e "${RED}打包失败，JAR文件不存在${NC}"
    exit 1
fi
echo -e "${GREEN}打包完成: $JAR_FILE${NC}"

echo -e "${YELLOW}[5/5] 启动服务...${NC}"
systemctl daemon-reload
systemctl start lanmouse
sleep 3

# 检查服务状态
if systemctl is-active --quiet lanmouse; then
    echo -e "${GREEN}=========================================="
    echo -e "服务启动成功！"
    echo -e "==========================================${NC}"
else
    echo -e "${RED}服务启动失败，查看日志：${NC}"
    journalctl -u lanmouse -n 20 --no-pager
    exit 1
fi

# 测试API
echo -e "${YELLOW}测试健康检查...${NC}"
sleep 2
curl -s http://localhost:8080/api/health | head -1 || echo "健康检查可能需要更多时间"

echo ""
echo -e "${GREEN}=========================================="
echo "部署完成！"
echo "=========================================="
echo ""
echo "API端点："
echo "  微信登录: POST http://localhost:8080/api/auth/wechat-login"
echo "  健康检查: GET  http://localhost:8080/api/health"
echo ""
echo "微信登录测试命令："
echo "  curl http://localhost:8080/api/auth/wechat-login \\"
echo "    -X POST -H 'Content-Type: application/json' \\"
echo "    -d '{\"code\":\"test_code\"}'"
echo ""
