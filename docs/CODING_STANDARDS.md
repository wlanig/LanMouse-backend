# LanMouse 项目开发规范

## 代码风格

### Java (后端)
- 遵循Google Java Style Guide
- 使用Lombok减少样板代码
- 统一使用脊状命名法(camelCase)

### Dart/Flutter (移动端)
- 遵循Dart Style Guide
- 使用flutter_lints规则
- 组件名使用PascalCase

### JavaScript (PC端)
- 遵循Airbnb JavaScript Style Guide
- 使用ES6+语法

## Git提交规范

```
feat: 新功能
fix: 修复bug
docs: 文档更新
style: 代码格式
refactor: 重构
test: 测试
chore: 构建/工具
```

## 分支管理

- main: 主分支
- develop: 开发分支
- feature/*: 功能分支
- fix/*: 修复分支

## 数据库规范

### 命名
- 表名: 蛇形命名法 (snake_case)
- 字段名: 蛇形命名法
- 索引名: idx_{表名}_{字段名}

### 主键
- 使用BIGINT自增主键
- 命名: id

### 时间戳
- 创建时间: created_at
- 更新时间: updated_at
- 使用DATETIME类型

## API规范

### RESTful设计
- GET: 查询
- POST: 创建
- PUT: 更新
- DELETE: 删除

### 响应格式
```json
{
  "code": 0,
  "msg": "success",
  "data": {}
}
```

### 错误码
- 0: 成功
- 1001: 参数错误
- 2001: 用户不存在
- 2002: 密码错误
- 3001: 设备不存在
- 4001: 订单不存在
- 5001: 余额不足
