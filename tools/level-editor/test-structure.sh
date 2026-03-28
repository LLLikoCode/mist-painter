#!/bin/bash
# 谜题编辑器结构验证脚本

echo "========================================"
echo "迷雾绘者 - 谜题编辑器结构验证"
echo "========================================"
echo ""

# 检查文件是否存在
check_file() {
    if [ -f "$1" ]; then
        echo "✓ $1"
        return 0
    else
        echo "✗ $1 (缺失)"
        return 1
    fi
}

# 检查目录是否存在
check_dir() {
    if [ -d "$1" ]; then
        echo "✓ $1/"
        return 0
    else
        echo "✗ $1/ (缺失)"
        return 1
    fi
}

echo "【配置文件】"
check_file "package.json"
check_file "tsconfig.json"
check_file "vite.config.ts"
check_file "index.html"

echo ""
echo "【文档】"
check_file "README.md"
check_file "docs/DESIGN.md"
check_file "docs/USAGE.md"

echo ""
echo "【示例】"
check_file "examples/level_01.json"

echo ""
echo "【类型定义】"
check_file "src/types/index.ts"

echo ""
echo "【配置】"
check_file "src/config/editor.config.ts"

echo ""
echo "【编辑器核心】"
check_file "src/editor/LevelEditor.ts"
check_file "src/editor/MapEditor.ts"
check_file "src/editor/PuzzleEditor.ts"
check_file "src/editor/MistEditor.ts"

echo ""
echo "【导出器】"
check_file "src/export/LevelExporter.ts"

echo ""
echo "【UI】"
check_file "src/ui/UIManager.ts"

echo ""
echo "【入口】"
check_file "src/main.ts"

echo ""
echo "========================================"
echo "验证完成！"
echo "========================================"
echo ""
echo "文件统计:"
echo "- TypeScript 源文件: $(find src -name '*.ts' | wc -l) 个"
echo "- Markdown 文档: $(find . -name '*.md' | wc -l) 个"
echo "- JSON 配置: $(find . -name '*.json' | wc -l) 个"
echo ""
echo "使用方法:"
echo "  cd tools/level-editor"
echo "  npm install"
echo "  npm run dev"
echo ""
