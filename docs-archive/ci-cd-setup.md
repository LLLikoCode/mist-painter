# CI/CD 配置说明文档

本文档详细说明「迷雾绘者」项目的 CI/CD 流程配置。

## 📋 概述

本项目使用 **GitHub Actions** 作为 CI/CD 平台，实现自动化构建、测试和发布流程。

### 工作流概览

| 工作流 | 文件 | 触发条件 | 功能 |
|--------|------|----------|------|
| CI | `.github/workflows/ci.yml` | PR/Push 到 main/develop | 代码检查、单元测试 |
| Build | `.github/workflows/build.yml` | PR/Push 到 main/develop, Tags | 多平台构建 |
| Release | `.github/workflows/release.yml` | Tag push (v*) | 自动发布 Release |

---

## 🔧 工作流详解

### 1. CI 工作流 (`ci.yml`)

**触发条件：**
- Push 到 `main` 或 `develop` 分支
- Pull Request 到 `main` 或 `develop` 分支
- 修改 GDScript、场景文件、项目配置时

**任务：**

#### 1.1 代码质量检查 (code-quality)
- **GDScript 静态分析**：使用 `gdtoolkit` 进行代码风格检查
- **项目结构验证**：检查关键文件和目录是否存在
- **语法检查**：使用 Godot 编辑器进行语法验证

#### 1.2 单元测试 (unit-tests)
- 安装 GUT (Godot Unit Test) 测试框架
- 运行 `tests/` 目录下的所有测试
- 上传测试结果作为构建产物

#### 1.3 构建验证 (build-validation)
- 导入项目资源
- 验证导出预设配置

### 2. 构建工作流 (`build.yml`)

**触发条件：**
- Push 到 `main` 或 `develop` 分支
- Tag push (v*)
- 手动触发 (workflow_dispatch)

**支持平台：**
- 🐧 **Linux** (x86_64)
- 🪟 **Windows** (x86_64)
- 🌐 **Web** (HTML5)

**任务流程：**
1. 提取版本信息（从 git tag 或 project.godot）
2. 设置 Godot 环境
3. 下载并安装导出模板
4. 导入项目资源
5. 执行平台特定构建
6. 打包构建产物
7. 上传构建产物

**手动触发参数：**
```yaml
platform: [all, windows, linux, web]
```

### 3. 发布工作流 (`release.yml`)

**触发条件：**
- Tag push (格式: `v*`, 如 `v1.0.0`)
- 手动触发

**功能：**
- 自动构建所有平台版本
- 生成发布说明（包含最近提交记录）
- 创建 GitHub Release
- 上传构建产物到 Release

**版本号规则：**
- 正式版本：`v1.0.0`, `v1.2.3`
- 预发布版本：`v1.0.0-beta.1`, `v1.0.0-rc.1`

---

## 📦 导出配置

### export_presets.cfg

项目包含三个导出预设：

#### Linux/X11
```ini
[preset_0]
name="Linux/X11"
platform="Linux/X11"
export_path="build/linux/mist-painter"
```

#### Windows Desktop
```ini
[preset_1]
name="Windows Desktop"
platform="Windows Desktop"
export_path="build/windows/mist-painter.exe"
```

#### Web
```ini
[preset_2]
name="Web"
platform="Web"
export_path="build/web/index.html"
```

---

## 🚀 使用方法

### 本地开发

#### 运行代码检查
```bash
# 安装 gdtoolkit
pip install gdtoolkit

# 运行代码检查
gdlint src/
```

#### 本地构建
```bash
# Linux
godot --headless --export-release "Linux/X11" "build/linux/mist-painter"

# Windows
godot --headless --export-release "Windows Desktop" "build/windows/mist-painter.exe"

# Web
godot --headless --export-release "Web" "build/web/index.html"
```

### 触发 CI/CD

#### 自动触发
- Push 代码到 `main` 或 `develop` 分支
- 创建 Pull Request

#### 手动触发构建
1. 进入 GitHub 仓库
2. 点击 **Actions** 标签
3. 选择 **Build - Multi-Platform Export**
4. 点击 **Run workflow**
5. 选择目标平台 (all/windows/linux/web)

#### 创建发布
```bash
# 创建并推送 tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

---

## 🧪 本地模拟 CI 环境

### 使用 act 工具

`act` 可以在本地运行 GitHub Actions 工作流。

#### 安装 act
```bash
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

#### 运行 CI 工作流
```bash
# 运行所有工作流
act

# 运行特定工作流
act -j code-quality
act -j unit-tests

# 使用特定镜像
act -P ubuntu-latest=nektos/act-environments-ubuntu:18.04
```

#### 运行构建工作流
```bash
# 构建所有平台
act -j build-linux
act -j build-windows
act -j build-web
```

### 使用 Docker 模拟

```bash
# 拉取 Godot 镜像
docker pull barichello/godot-ci:4.2.2

# 运行构建
docker run --rm -v $(pwd):/project -w /project \
  barichello/godot-ci:4.2.2 \
  godot --headless --export-release "Linux/X11" "build/linux/mist-painter"
```

### 本地脚本

创建本地构建脚本 `scripts/build.sh`：

```bash
#!/bin/bash
set -e

GODOT_VERSION="4.2.2"
EXPORT_NAME="mist-painter"

# 检查 Godot 是否安装
if ! command -v godot &> /dev/null; then
    echo "Godot not found. Please install Godot ${GODOT_VERSION}"
    exit 1
fi

# 导入资源
echo "Importing assets..."
godot --headless --editor --quit

# 构建 Linux
echo "Building Linux..."
mkdir -p build/linux
godot --headless --export-release "Linux/X11" "build/linux/${EXPORT_NAME}"
chmod +x "build/linux/${EXPORT_NAME}"

# 构建 Windows
echo "Building Windows..."
mkdir -p build/windows
godot --headless --export-release "Windows Desktop" "build/windows/${EXPORT_NAME}.exe"

# 构建 Web
echo "Building Web..."
mkdir -p build/web
godot --headless --export-release "Web" "build/web/index.html"

echo "Build complete!"
```

---

## 🔐 密钥配置

### GitHub Secrets

以下 Secrets 需要配置（如需要）：

| Secret | 用途 |
|--------|------|
| `GITHUB_TOKEN` | 自动提供，用于创建 Release |

### 代码签名（可选）

对于 Windows 发布，可以配置代码签名：

```yaml
- name: Sign Windows Binary
  uses: dlemstra/code-sign-action@v1
  with:
    certificate: ${{ secrets.CERTIFICATE }}
    password: ${{ secrets.CERTIFICATE_PASSWORD }}
    folder: build/windows
```

---

## 📊 构建产物

### 产物命名规则

```
{project-name}-{version}-{platform}.{ext}
```

例如：
- `mist-painter-1.0.0-linux.tar.gz`
- `mist-painter-1.0.0-windows.zip`
- `mist-painter-1.0.0-web.zip`

### 产物保留策略

- **CI 构建产物**: 保留 7 天
- **Release 产物**: 永久保留

---

## 🐛 故障排除

### 常见问题

#### 1. 导出模板未找到
```
Error: No export template found
```

**解决方案：**
```bash
# 手动下载模板
godot --headless --export-release "Linux/X11" /dev/null
```

#### 2. 资源导入失败
```
Error: Failed to load resource
```

**解决方案：**
```bash
# 强制重新导入
godot --headless --editor --quit
```

#### 3. 构建超时

**解决方案：**
- 增加 `timeout` 值
- 优化项目资源
- 使用缓存

#### 4. Web 构建失败

**解决方案：**
- 确保安装了 Web 导出模板
- 检查 `export_presets.cfg` 中的 Web 配置

---

## 📝 最佳实践

1. **提交前本地测试**
   ```bash
   gdlint src/
   godot --headless --check-only -e --quit
   ```

2. **使用语义化版本**
   - `v1.0.0` - 正式版本
   - `v1.0.0-beta.1` - 预发布版本

3. **编写测试**
   - 在 `tests/` 目录下添加 GUT 测试
   - 确保测试覆盖率

4. **更新版本号**
   - 发布前更新 `project.godot` 中的版本

---

## 🔗 参考链接

- [Godot CI/CD Documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GUT Testing Framework](https://github.com/bitwes/Gut)
- [Godot Export Templates](https://godotengine.org/download)

---

## 📅 更新日志

| 日期 | 版本 | 变更 |
|------|------|------|
| 2026-03-23 | 1.0.0 | 初始 CI/CD 配置 |
