#!/bin/bash
# 在服务器上执行的完整部署脚本

# 1. 创建项目目录
mkdir -p /opt/lanmouse
cd /opt/lanmouse

# 2. 创建 pom.xml
cat > pom.xml << 'POMEOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.7.18</version>
    </parent>
    <groupId>com.lanmouse</groupId>
    <artifactId>lanmouse-backend</artifactId>
    <version>1.0.0</version>
    <properties>
        <java.version>17</java.version>
    </properties>
    <dependencies>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
        <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
        <dependency><groupId>com.mysql</groupId><artifactId>mysql-connector-j</artifactId><version>8.0.33</version></dependency>
        <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin>
        </plugins>
    </build>
</project>
POMEOF

# 3. 创建目录结构
mkdir -p src/main/java/com/lanmouse/controller
mkdir -p src/main/java/com/lanmouse/entity
mkdir -p src/main/java/com/lanmouse/repository
mkdir -p src/main/resources

# 4. 创建主类
cat > src/main/java/com/lanmouse/LanmouseApplication.java << 'JAVAEOF'
package com.lanmouse;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
@SpringBootApplication
public class LanmouseApplication {
    public static void main(String[] args) {
        SpringApplication.run(LanmouseApplication.class, args);
    }
}
JAVAEOF

# 5. 创建实体类
cat > src/main/java/com/lanmouse/entity/User.java << 'JAVAEOF'
package com.lanmouse.entity;
import lombok.Data;
import javax.persistence.*;
@Data
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String phone;
    private String password;
    private String name;
}
JAVAEOF

# 6. 创建 Repository
cat > src/main/java/com/lanmouse/repository/UserRepository.java << 'JAVAEOF'
package com.lanmouse.repository;
import com.lanmouse.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByPhone(String phone);
}
JAVAEOF

# 7. 创建 Controller
cat > src/main/java/com/lanmouse/controller/AuthController.java << 'JAVAEOF'
package com.lanmouse.controller;
import com.lanmouse.entity.User;
import com.lanmouse.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired
    private UserRepository userRepository;
    
    @PostMapping("/register")
    public Map<String, Object> register(@RequestBody User user) {
        Map<String, Object> result = new HashMap<>();
        if (userRepository.findByPhone(user.getPhone()).isPresent()) {
            result.put("code", 400);
            result.put("message", "手机号已存在");
            return result;
        }
        userRepository.save(user);
        result.put("code", 200);
        result.put("message", "注册成功");
        return result;
    }
    
    @PostMapping("/login")
    public Map<String, Object> login(@RequestBody User user) {
        Map<String, Object> result = new HashMap<>();
        Optional<User> existing = userRepository.findByPhone(user.getPhone());
        if (existing.isPresent() && existing.get().getPassword().equals(user.getPassword())) {
            result.put("code", 200);
            result.put("message", "登录成功");
            result.put("token", "mock-token-" + user.getPhone());
        } else {
            result.put("code", 401);
            result.put("message", "用户名或密码错误");
        }
        return result;
    }
}
JAVAEOF

# 8. 创建 HealthController
cat > src/main/java/com/lanmouse/controller/HealthController.java << 'JAVAEOF'
package com.lanmouse.controller;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.Map;
@RestController
@RequestMapping("/api")
public class HealthController {
    @GetMapping("/health")
    public Map<String, Object> health() {
        Map<String, Object> result = new HashMap<>();
        result.put("code", 200);
        result.put("message", "服务运行正常");
        return result;
    }
}
JAVAEOF

# 9. 创建配置文件
cat > src/main/resources/application.yml << 'YAMLEOF'
server:
  port: 8080
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/lanmouse?useUnicode=true&characterEncoding=utf-8&useSSL=false&serverTimezone=Asia/Shanghai
    username: root
    password: 740528@Ww
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    hibernate:
      ddl-auto: update
    show-sql: true
YAMLEOF

# 10. 创建数据库初始化脚本
mkdir -p sql
cat > sql/init.sql << 'SQLEOF'
CREATE DATABASE IF NOT EXISTS lanmouse CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE lanmouse;
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    name VARCHAR(50)
);
INSERT INTO users (phone, password, name) VALUES ('13800138000', '123456', '测试用户');
SQLEOF

echo "项目文件创建完成！"
echo "接下来执行："
echo "1. mysql -u root -p740528@Ww < sql/init.sql"
echo "2. mvn clean package -DskipTests"
echo "3. java -jar target/lanmouse-backend-1.0.0.jar"
