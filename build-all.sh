#!/bin/bash

set -e

echo "🦀 OpenClaw Monitor - 全平台打包构建"
echo "======================================"
echo ""

# 检查依赖
echo "📦 检查依赖..."
if ! command -v cargo &> /dev/null; then
    echo "❌ Rust/Cargo 未安装"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ Node.js/npm 未安装"
    exit 1
fi

# 安装依赖
echo ""
echo "📥 安装依赖..."
npm install

# 构建前端
echo ""
echo "🔨 构建前端..."
npm run build

# 构建 Tauri 应用
echo ""
echo "🚀 构建 Tauri 应用..."
npm run tauri build

echo ""
echo "✅ 构建完成！"
echo ""
echo "📦 构建产物位置："
echo "   Linux:   src-tauri/target/release/bundle/deb/"
echo "   Linux:   src-tauri/target/release/bundle/appimage/"
echo "   Windows: src-tauri/target/release/bundle/msi/"
echo "   Windows: src-tauri/target/release/bundle/nsis/"
echo "   macOS:   src-tauri/target/release/bundle/dmg/"
echo "   macOS:   src-tauri/target/release/bundle/app/"
echo ""
echo "🎉 恭喜！"
