# LanMouse 自动化调试 - 使用指南

## 🎯 为您的 LanMouse 项目配置的自动化调试系统

---

## 📁 已创建的文件

| 文件 | 说明 |
|------|------|
| `lanmouse-debug.ps1` | 完整自动化调试脚本 |
| `quick-debug.ps1` | 快速调试入口（交互式） |
| `.codebuddy/rules` | CodeBuddy 行为规则 |

---

## 🚀 使用方法

### 方式 1：一键调试（推荐）

```powershell
cd D:\CodeBuddy_Project\LanMouse
.\quick-debug.ps1
```

选择要调试的组件：
```
1. 后端 (Spring Boot + Java)
2. 移动端 (Flutter)
3. PC端 (Node.js)
4. 全部组件
5. CodeBuddy 分析模式
```

### 方式 2：完整调试脚本

```powershell
# 调试后端（带自动修复）
.\lanmouse-debug.ps1 -Component backend -AutoFix

# 调试移动端
.\lanmouse-debug.ps1 -Component mobile

# 调试 PC端
.\lanmouse-debug.ps1 -Component pc-server

# 调试全部
.\lanmouse-debug.ps1 -Component all
```

### 方式 3：CodeBuddy IDE

在 CodeBuddy 中使用 **Plan 模式**：

```
帮我调试 LanMouse 后端，检测 Maven 打包是否有问题
```

或：

```
执行自动化调试：运行后端构建，捕获错误，自动分析并修复
```

### 方式 4：管道方式

```powershell
# Maven 错误分析
cd D:\CodeBuddy_Project\LanMouse\backend
mvn clean package 2>&1 | codebuddy "analyze and fix"

# Flutter 错误分析
cd D:\CodeBuddy_Project\LanMouse\mobile
flutter pub get 2>&1 | codebuddy "fix dependency issues"

# npm 错误分析
cd D:\CodeBuddy_Project\LanMouse\pc-server
npm install 2>&1 | codebuddy "solve problems"
```

---

## 🔧 自动化调试流程

```
┌─────────────────────────────────────────────────────────────┐
│                     用户需求                                │
│            "帮我调试后端部署问题"                            │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              CodeBuddy 自动识别                             │
│         后端项目 → Maven → Spring Boot                      │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              执行 lanmouse-debug.ps1                        │
│                   Maven 打包                                │
│              捕获输出 + 分析错误                             │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                  自动修复（可选）                            │
│              dependency:resolve                             │
│                 clean + compile                             │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    生成报告                                 │
│              错误摘要 + 解决方案                             │
└─────────────────────────┬───────────────────────────────────┘
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    用户反馈                                 │
│              简洁结果 + 下一步建议                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 支持的组件

| 组件 | 路径 | 技术 | 常用命令 |
|------|------|------|---------|
| 后端 | `backend/` | Spring Boot | `mvn clean package` |
| 移动端 | `mobile/` | Flutter | `flutter pub get` |
| PC端 | `pc-server/` | Node.js | `npm install` |

---

## 🎨 常见使用场景

### 场景 1：后端打包失败
```powershell
.\lanmouse-debug.ps1 -Component backend -AutoFix
```

### 场景 2：移动端依赖冲突
```powershell
.\lanmouse-debug.ps1 -Component mobile
```

### 场景 3：PC端安装失败
```powershell
.\lanmouse-debug.ps1 -Component pc-server -AutoFix
```

### 场景 4：全面检测
```powershell
.\lanmouse-debug.ps1 -Component all
```

### 场景 5：CodeBuddy 智能分析
```
在 CodeBuddy Plan 模式输入：
"帮我检测 LanMouse 项目的潜在问题，并给出修复方案"
```

---

## ✨ 功能特点

- ✅ **自动识别**：识别不同组件的技术栈
- ✅ **智能分析**：分类错误类型和原因
- ✅ **自动修复**：尝试常见问题的自动修复
- ✅ **详细报告**：生成可读性强的调试报告
- ✅ **CodeBuddy 集成**：输出可直接用于 CodeBuddy 分析

---

## 📝 示例输出

运行 `.\lanmouse-debug.ps1 -Component backend -AutoFix` 后：

```
========================================
  LanMouse Auto Debug
========================================

[步骤] 检查 Maven 环境...
[成功] Maven 正常

[步骤] 执行 Maven 打包...
[Maven 输出...]
[错误] Maven 打包失败
  > error: cannot find symbol
  > location: class UserService.java

[步骤] 尝试自动修复...
[步骤] 清理并重新编译...
[成功] 后端打包成功

========================================
  调试报告
========================================
耗时: 45.23 秒

  backend  : SUCCESS
  mobile   : SKIPPED
  pc-server: SKIPPED

状态: 后端已修复

日志文件: C:\Users\...\temp\lanmouse_debug_xxx.txt
报告已复制到剪贴板
========================================
```

---

## 🎯 下一步

1. 运行 `.\quick-debug.ps1` 测试
2. 在 CodeBuddy 中使用 Plan 模式
3. 如有问题，错误信息会自动复制到剪贴板
4. 在 CodeBuddy 中粘贴并请求修复

---

**自动化调试已配置完成！** 🎉
