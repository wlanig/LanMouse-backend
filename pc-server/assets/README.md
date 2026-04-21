# LanMouse 图标资源

此目录用于存放应用图标资源。

## 需要的图标文件

| 平台 | 文件名 | 尺寸 | 格式 |
|------|--------|------|------|
| Windows | `icon.ico` | 256x256 (多尺寸) | ICO |
| macOS | `icon.icns` | 512x512, 256x256, 128x128, 64x64, 32x32, 16x16 | ICNS |
| Linux | `icon.png` | 512x512, 256x256, 128x128 | PNG |

## 图标设计建议

- 主题：鼠标 + 网络/连接
- 颜色：绿色主色调 (#4CAF50)
- 风格：简洁、现代

## 临时图标

如果暂时没有图标文件，Electron 应用会使用默认图标。
可以将任意 PNG 图片重命名为 icon.png 用于 Linux 开发测试。

## 工具推荐

- **Windows ICO**: https://www.favicon.cc/
- **macOS ICNS**: 使用 macOS 自带图标工具或 iconutil
- **跨平台**: https://icon.kitchen/
