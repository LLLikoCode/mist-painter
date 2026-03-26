#!/bin/bash
# 本地构建脚本 - 模拟 CI/CD 构建流程
# 用于「迷雾绘者」项目

set -e

# ============================================
# 配置
# ============================================
GODOT_VERSION="4.2.2"
EXPORT_NAME="mist-painter"
PROJECT_PATH="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${PROJECT_PATH}/build"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 函数
# ============================================

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_godot() {
    if ! command -v godot &> /dev/null; then
        print_error "Godot not found!"
        print_info "Please install Godot ${GODOT_VERSION}"
        print_info "Download from: https://godotengine.org/download"
        exit 1
    fi
    
    local version=$(godot --version | head -1)
    print_info "Found Godot: $version"
}

check_export_presets() {
    if [ ! -f "${PROJECT_PATH}/export_presets.cfg" ]; then
        print_error "export_presets.cfg not found!"
        print_info "Please configure export presets in Godot editor first."
        exit 1
    fi
    print_success "Export presets found"
}

import_assets() {
    print_header "导入项目资源"
    
    cd "${PROJECT_PATH}"
    
    # 使用 headless 模式导入资源
    timeout 180 godot --headless --editor --quit 2>&1 | tee "${BUILD_DIR}/import.log" || true
    
    print_success "资源导入完成"
}

build_linux() {
    print_header "构建 Linux 版本"
    
    local output_dir="${BUILD_DIR}/linux"
    mkdir -p "${output_dir}"
    
    cd "${PROJECT_PATH}"
    
    godot --headless --export-release "Linux/X11" \
        "${output_dir}/${EXPORT_NAME}" \
        2>&1 | tee "${BUILD_DIR}/build_linux.log"
    
    if [ -f "${output_dir}/${EXPORT_NAME}" ]; then
        chmod +x "${output_dir}/${EXPORT_NAME}"
        print_success "Linux 构建成功"
        
        # 打包
        cd "${output_dir}"
        tar -czf "${BUILD_DIR}/${EXPORT_NAME}-linux.tar.gz" .
        print_success "Linux 包已创建: ${EXPORT_NAME}-linux.tar.gz"
    else
        print_error "Linux 构建失败"
        return 1
    fi
}

build_windows() {
    print_header "构建 Windows 版本"
    
    local output_dir="${BUILD_DIR}/windows"
    mkdir -p "${output_dir}"
    
    cd "${PROJECT_PATH}"
    
    godot --headless --export-release "Windows Desktop" \
        "${output_dir}/${EXPORT_NAME}.exe" \
        2>&1 | tee "${BUILD_DIR}/build_windows.log"
    
    if [ -f "${output_dir}/${EXPORT_NAME}.exe" ]; then
        print_success "Windows 构建成功"
        
        # 打包
        cd "${output_dir}"
        zip -r "${BUILD_DIR}/${EXPORT_NAME}-windows.zip" . > /dev/null
        print_success "Windows 包已创建: ${EXPORT_NAME}-windows.zip"
    else
        print_error "Windows 构建失败"
        return 1
    fi
}

build_web() {
    print_header "构建 Web 版本"
    
    local output_dir="${BUILD_DIR}/web"
    mkdir -p "${output_dir}"
    
    cd "${PROJECT_PATH}"
    
    godot --headless --export-release "Web" \
        "${output_dir}/index.html" \
        2>&1 | tee "${BUILD_DIR}/build_web.log"
    
    if [ -f "${output_dir}/index.html" ]; then
        print_success "Web 构建成功"
        
        # 打包
        cd "${output_dir}"
        zip -r "${BUILD_DIR}/${EXPORT_NAME}-web.zip" . > /dev/null
        print_success "Web 包已创建: ${EXPORT_NAME}-web.zip"
    else
        print_error "Web 构建失败"
        return 1
    fi
}

run_linter() {
    print_header "运行代码检查"
    
    if ! command -v gdlint &> /dev/null; then
        print_warning "gdlint not found. Installing..."
        pip install gdtoolkit || {
            print_error "Failed to install gdtoolkit"
            return 1
        }
    fi
    
    cd "${PROJECT_PATH}"
    
    local has_errors=0
    while IFS= read -r -d '' file; do
        print_info "Checking: $file"
        gdlint "$file" || has_errors=1
    done < <(find src -name "*.gd" -print0 2>/dev/null)
    
    if [ $has_errors -eq 0 ]; then
        print_success "代码检查通过"
    else
        print_warning "代码检查发现问题"
    fi
}

run_tests() {
    print_header "运行单元测试"
    
    cd "${PROJECT_PATH}"
    
    if [ ! -d "tests" ] || [ -z "$(ls -A tests 2>/dev/null)" ]; then
        print_warning "No tests found in tests/ directory"
        return 0
    fi
    
    # 检查 GUT 是否安装
    if [ ! -d "addons/gut" ]; then
        print_info "Installing GUT..."
        mkdir -p addons
        git clone --depth 1 --branch v9.2.1 https://github.com/bitwes/Gut.git addons/gut
    fi
    
    # 创建测试运行脚本
    cat > "${BUILD_DIR}/run_tests.gd" << 'EOF'
extends SceneTree

func _init():
    var gut = load("res://addons/gut/GutScene.tscn").instantiate()
    get_root().add_child(gut)
    
    gut.auto_run = true
    gut.directory1 = "res://tests"
    gut.include_subdirectories = true
    
    await gut.test_execution_finished
    
    var exit_code = 0 if gut.get_pass_count() > 0 and gut.get_fail_count() == 0 else 1
    print("Tests completed: " + str(gut.get_pass_count()) + " passed, " + str(gut.get_fail_count()) + " failed")
    
    quit(exit_code)
EOF
    
    godot --headless --script "${BUILD_DIR}/run_tests.gd" 2>&1 | tee "${BUILD_DIR}/test_results.log"
    
    print_success "测试运行完成"
}

show_summary() {
    print_header "构建摘要"
    
    echo ""
    echo "构建目录: ${BUILD_DIR}"
    echo ""
    
    if [ -d "${BUILD_DIR}" ]; then
        echo "生成的文件:"
        ls -lh "${BUILD_DIR}"/*.{tar.gz,zip} 2>/dev/null || echo "  (无构建包)"
        echo ""
        
        echo "日志文件:"
        ls -lh "${BUILD_DIR}"/*.log 2>/dev/null || echo "  (无日志)"
    fi
    
    echo ""
    print_success "本地 CI 模拟完成!"
}

show_help() {
    cat << EOF
本地构建脚本 - 迷雾绘者项目

用法: $0 [选项] [命令]

命令:
    all         运行完整 CI 流程 (默认)
    lint        仅运行代码检查
    test        仅运行测试
    import      仅导入资源
    linux       仅构建 Linux 版本
    windows     仅构建 Windows 版本
    web         仅构建 Web 版本
    clean       清理构建目录

选项:
    -h, --help  显示此帮助信息

示例:
    $0              # 运行完整流程
    $0 lint         # 仅运行代码检查
    $0 linux        # 仅构建 Linux 版本
    $0 clean        # 清理构建目录

EOF
}

clean_build() {
    print_header "清理构建目录"
    
    if [ -d "${BUILD_DIR}" ]; then
        rm -rf "${BUILD_DIR}"
        print_success "构建目录已清理"
    else
        print_info "构建目录不存在"
    fi
}

# ============================================
# 主程序
# ============================================

main() {
    # 处理参数
    local command="${1:-all}"
    
    case "$command" in
        -h|--help)
            show_help
            exit 0
            ;;
        clean)
            clean_build
            exit 0
            ;;
    esac
    
    print_header "迷雾绘者 - 本地 CI/CD 模拟"
    print_info "项目路径: ${PROJECT_PATH}"
    print_info "Godot 版本: ${GODOT_VERSION}"
    
    # 检查环境
    check_godot
    check_export_presets
    
    # 创建构建目录
    mkdir -p "${BUILD_DIR}"
    
    # 执行命令
    case "$command" in
        lint)
            run_linter
            ;;
        test)
            run_tests
            ;;
        import)
            import_assets
            ;;
        linux)
            import_assets
            build_linux
            ;;
        windows)
            import_assets
            build_windows
            ;;
        web)
            import_assets
            build_web
            ;;
        all|*)
            run_linter
            import_assets
            run_tests
            build_linux
            build_windows
            build_web
            ;;
    esac
    
    show_summary
}

# 运行主程序
main "$@"

