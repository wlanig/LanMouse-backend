#!/bin/bash
# LanMouse Linux 部署脚本

set -e

PROJECT_ROOT="/opt/lanmouse"
BACKEND_DIR="$PROJECT_ROOT/backend"

echo "========================================"
echo "  LanMouse Linux 部署"
echo "========================================"
echo ""

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Java
log_info "检查 Java 环境..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    log_info "Java 版本: $JAVA_VERSION"
else
    log_error "Java 未安装"
    exit 1
fi

# 检查 Maven
log_info "检查 Maven 环境..."
if command -v mvn &> /dev/null; then
    MVN_VERSION=$(mvn -v | head -1)
    log_info "Maven: $MVN_VERSION"
else
    log_error "Maven 未安装"
    exit 1
fi

# 创建项目目录
log_info "创建项目目录..."
mkdir -p $PROJECT_ROOT

# 部署后端
deploy_backend() {
    log_info "部署后端服务..."
    
    if [ ! -d "$BACKEND_DIR" ]; then
        log_warn "后端目录不存在，请上传代码到 $BACKEND_DIR"
        exit 1
    fi
    
    cd $BACKEND_DIR
    
    # Maven 打包
    log_info "执行 Maven 打包..."
    mvn clean package -DskipTests
    
    # 检查 JAR 文件
    JAR_FILE=$(find target -name "*.jar" | head -1)
    if [ -z "$JAR_FILE" ]; then
        log_error "JAR 文件未找到"
        exit 1
    fi
    
    log_info "打包成功: $JAR_FILE"
    
    # 停止旧服务
    log_info "停止旧服务..."
    pkill -f "lanmouse" || true
    
    # 启动新服务
    log_info "启动服务..."
    nohup java -jar $JAR_FILE > /var/log/lanmouse.log 2>&1 &
    
    log_info "服务已启动"
}

# 主流程
case "${1:-all}" in
    backend)
        deploy_backend
        ;;
    all)
        deploy_backend
        ;;
    *)
        echo "用法: $0 [backend|all]"
        exit 1
        ;;
esac

echo ""
echo "========================================"
echo "  部署完成"
echo "========================================"
