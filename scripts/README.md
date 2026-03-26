# 本地 CI/CD 模拟工具

本目录包含用于本地模拟 CI/CD 流程的脚本和工具。

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `build.sh` | 本地构建脚本，模拟 CI/CD 流程 |
| `README.md` | 本说明文档 |

## 🚀 使用方法

### 快速开始

```bash
# 进入脚本目录
cd scripts

# 运行完整 CI 流程
./build.sh

# 或指定特定任务
./build.sh lint      # 仅代码检查
./build.sh test      # 仅运行测试
./build.sh linux     # 仅构建 Linux
./build.sh windows   # 仅构建 Windows
./build.sh web       # 仅构建 Web
./build.sh clean     # 清理构建目录
```

### 使用 Act 工具

Act 可以在本地运行 GitHub Actions 工作流。

#### 安装 Act

**macOS:**
```bash
brew install act
```

**Linux:**
```bash
curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

**Windows (使用 Chocolatey):**
```bash
choco install act-cli
```

#### 运行工作流

```bash
# 列出可用工作流
act -l

# 运行 CI 工作流
act -j code-quality
act -j unit-tests
act -j build-validation

# 运行构建工作流
act -j build-linux
act -j build-windows
act -j build-web

# 运行完整工作流
act push

# 使用特定事件触发
act pull_request

# 使用特定镜像
act -P ubuntu-latest=nektos/act-environments-ubuntu:18.04

# 显示详细输出
act -v
```

### 使用 Docker 模拟

```bash
# 使用 Godot CI 镜像
docker run --rm -v $(pwd)/..:/project -w /project \
  barichello/godot-ci:4.2.2 \
  godot --headless --export-release "Linux/X11" "build/linux/mist-painter"
```

## 🔧 环境要求

### 必需

- Godot 4.2.2 或兼容版本
- Bash shell

### 可选

- `gdtoolkit` (用于代码检查)
- `act` (用于本地运行 GitHub Actions)
- Docker (用于容器化构建)

## 📋 构建输出

构建产物将保存在项目根目录的 `build/` 文件夹中：

```
build/
├── linux/
│   └── mist-painter
├── windows/
│   └── mist-painter.exe
├── web/
│   └── index.html
├── *.log          # 构建日志
└── *.tar.gz       # 打包文件
└── *.zip          # 打包文件
```

## 🐛 故障排除

### Godot 未找到

确保 Godot 在系统 PATH 中：

```bash
# 检查 Godot 是否可访问
which godot
godot --version

# 如果未找到，创建符号链接
sudo ln -s /path/to/godot /usr/local/bin/godot
```

### 导出模板缺失

首次运行需要在 Godot 编辑器中下载导出模板：

1. 打开 Godot 编辑器
2. 点击 **编辑器** → **管理导出模板**
3. 下载对应版本的模板

或使用命令行：

```bash
# 下载并安装导出模板
mkdir -p ~/.local/share/godot/export_templates/4.2.2.stable
wget https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_export_templates.tpz
cd ~/.local/share/godot/export_templates/4.2.2.stable
unzip /path/to/Godot_v4.2.2-stable_export_templates.tpz
```

### Act 运行失败

```bash
# 更新 act
brew upgrade act

# 使用特定镜像
act -P ubuntu-latest=node:16-buster-slim
```

## 📚 参考

- [Act 文档](https://nektosact.com/)
- [Godot CI/CD](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
