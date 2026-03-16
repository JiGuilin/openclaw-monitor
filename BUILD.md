# OpenClaw Monitor - 打包构建指南

## 📋 前置准备

### 1. 生成应用图标

访问 https://tauri.app/v1/guides/features/icons 生成图标，或使用以下命令：

```bash
# 安装 tauri-cli
npm install -D @tauri-apps/cli

# 生成图标（需要一张 1024x1024 的 PNG）
npx tauri icon /path/to/app-icon.png
```

图标会生成在 `src-tauri/icons/` 目录。

### 2. 安装系统依赖

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install -y \
    libwebkit2gtk-4.0-dev \
    build-essential \
    curl \
    wget \
    libssl-dev \
    libgtk-3-dev \
    libayatana-appindicator3-dev \
    librsvg2-dev \
    libjavascriptcoregtk-4.0-dev \
    libsoup2.4-dev \
    pkg-config \
    libdbus-1-dev
```

#### macOS
```bash
xcode-select --install
```

#### Windows
安装 [Visual Studio Build Tools](https://visualstudio.microsoft.com/downloads/)（包含 C++ 构建工具）

---

## 🚀 构建命令

### 开发模式
```bash
npm run tauri dev
```

### 生产构建

#### 构建所有平台（当前系统）
```bash
npm run tauri build
```

#### 构建特定平台

**Windows (.exe + .msi)**
```bash
npm run tauri build -- --target x86_64-pc-windows-msvc
```
输出位置：`src-tauri/target/release/bundle/msi/` 和 `src-tauri/target/release/bundle/nsis/`

**macOS (.app + .dmg)**
```bash
npm run tauri build -- --target x86_64-apple-darwin
# 或 Apple Silicon
npm run tauri build -- --target aarch64-apple-darwin
```
输出位置：`src-tauri/target/release/bundle/dmg/` 和 `src-tauri/target/release/bundle/macos/`

**Linux (.deb + .AppImage)**
```bash
npm run tauri build -- --target x86_64-unknown-linux-gnu
```
输出位置：`src-tauri/target/release/bundle/deb/` 和 `src-tauri/target/release/bundle/appimage/`

---

## 📦 构建产物

构建完成后，产物位于：

```
src-tauri/target/release/bundle/
├── deb/           # Debian/Ubuntu 包
├── appimage/      # Linux AppImage
├── dmg/           # macOS DMG
├── macos/         # macOS .app
├── msi/           # Windows MSI
└── nsis/          # Windows NSIS 安装程序
```

---

## ⚙️ 自定义配置

### 修改应用信息

编辑 `src-tauri/tauri.conf.json`：

```json
{
  "package": {
    "productName": "OpenClaw Monitor",
    "version": "0.1.0"
  },
  "tauri": {
    "bundle": {
      "identifier": "com.openclaw.monitor",
      "category": "DeveloperTool",
      "shortDescription": "OpenClaw 系统监控仪表盘",
      "longDescription": "实时监控 OpenClaw Gateway、Session、系统资源和 Cron 任务状态"
    }
  }
}
```

### 修改版本号

```bash
# 编辑 package.json
npm version patch  # 0.1.0 -> 0.1.1
npm version minor  # 0.1.0 -> 0.2.0
npm version major  # 0.1.0 -> 1.0.0
```

---

## 🔍 故障排查

### 构建失败：找不到 webkit2gtk
```bash
# Ubuntu/Debian
sudo apt install libwebkit2gtk-4.0-dev
```

### 构建失败：SSL 错误
```bash
# Ubuntu/Debian
sudo apt install libssl-dev pkg-config
```

### macOS 签名问题
在 `tauri.conf.json` 中添加：
```json
{
  "tauri": {
    "bundle": {
      "macOS": {
        "signingIdentity": "Developer ID Application: Your Name"
      }
    }
  }
}
```

### Windows 构建慢
确保已安装 Visual Studio Build Tools 并选择 "Desktop development with C++"

---

## 📤 分发

### Windows
- 分发 `.msi` 或 `.exe` 安装程序
- 或使用 `.zip` 绿色版（需手动提取）

### macOS
- 分发 `.dmg` 文件
- 注意：未签名的应用会显示警告，用户需手动允许

### Linux
- Debian/Ubuntu: 分发 `.deb` 包
- 其他发行版：分发 `.AppImage`

---

## 🔄 自动更新（可选）

配置自动更新需要：

1. 搭建更新服务器（或使用 GitHub Releases）
2. 在 `tauri.conf.json` 中配置：

```json
{
  "tauri": {
    "updater": {
      "active": true,
      "endpoints": [
        "https://releases.openclaw.com/{{target}}/{{arch}}/{{current_version}}"
      ],
      "dialog": true,
      "pubkey": "YOUR_PUBLIC_KEY"
    }
  }
}
```

详见：https://tauri.app/v1/guides/distribution/updater

---

*最后更新：2026-03-17*
