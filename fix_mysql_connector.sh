#!/bin/bash
# 修复 MySQL 连接器依赖问题

cd /opt/lanmouse

# 备份原 pom.xml
cp pom.xml pom.xml.bak

# 修复 MySQL 连接器依赖 - 使用正确的包名
sed -i 's|<groupId>mysql</groupId>|<groupId>com.mysql</groupId>|g' pom.xml
sed -i 's|<artifactId>mysql-connector-java</artifactId>|<artifactId>mysql-connector-j</artifactId>|g' pom.xml

# 清理 Maven 缓存中的 MySQL 相关依赖
rm -rf ~/.m2/repository/mysql
rm -rf ~/.m2/repository/com/mysql

# 清理项目
mvn clean -q

# 重新构建
mvn package -DskipTests -q

# 检查是否成功
if [ -f target/lanmouse-backend-1.0.0.jar ]; then
    echo "BUILD SUCCESS"
    ls -la target/lanmouse-backend-1.0.0.jar
else
    echo "BUILD FAILED - checking pom.xml:"
    head -60 pom.xml
fi
