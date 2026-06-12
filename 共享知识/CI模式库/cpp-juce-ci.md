# C++ (JUCE/AudioFX) CI 模式

> 从 AudioFX 项目提炼的 C++ VST3 插件 CI 最佳实践

## AudioFX 现有 CI 架构

```
build.yml (push/PR触发):
  detect → gen2-verify → build(矩阵) → test(三层) → release(手动)

release.yml (tag触发):
  detect → build-vst3(矩阵) → build-cli(三平台) → release(6产物)
```

## 关键模式

### 1. 变更检测（最值得借鉴）

不是每次全量构建26个插件，只构建有改动的：

```yaml
detect:
  - push → git diff检测哪些VC-*/有变化
  - workflow_dispatch → 手动指定构建哪些
  - workflow变更 → 全量构建
  输出 → matrix JSON → 后续job只构建变化的插件
```

### 2. 分层验证（快速反馈优先）

```
g++ standalone(秒编) → 快速验证编译通过
    ↓
JUCE完整构建(分钟级) → 生成VST3
    ↓
三层CLI测试 → 可运行→功能→效果
```

### 3. 三层测试体系

| 层级 | 验证内容 | 工具 |
|------|---------|------|
| Tier 1 可运行性 | CLI不崩溃、输出有效WAV | sox生成测试音频 |
| Tier 2 功能性 | DSP正确性 | 脉冲/正弦响应分析 |
| Tier 3 效果性 | 信号链合理性 | RMS/峰值范围检查 |

### 4. JUCE缓存

```yaml
cache:
  path: JUCE
  key: juce-${{ runner.os }}-v${{ env.JUCE_VERSION }}
```

JUCE仓库约1GB，缓存后构建提速3-5倍。

## 可被 open-dev-tools 标准化的部分

1. **justfile模板**：C++版（cmake + ninja）
2. **Docker基础镜像**：含JUCE预装
3. **测试框架**：三层CLI测试模板
4. **Release产物**：VST3打包标准流程

## macOS 交叉编译模式（2026-06-12 沉淀，从 OpenDAW 借鉴）

> **核心经验**：项目已有同类成功先例时，直接复用方案，不要从零摸索。

### 问题

AudioFX CI 原本用 `macos-13`（Intel runner）编译 x86_64 产物，但 Intel runner 排队严重（超过1小时），导致 CI 几乎不可用。

### 解法：借鉴 OpenDAW 的交叉编译方案

OpenDAW desktop.yml 已成功用 `macos-latest`（ARM runner）+ 交叉编译产出 Universal Binary。CMake 项目只需一个环境变量：

```yaml
jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]  # 去掉 macos-13
    steps:
      - name: Build
        env:
          CMAKE_OSX_ARCHITECTURES: 'x86_64;arm64'  # 关键！CMake 自动检测
        run: cmake --build build --config Release
```

### 对比

| 方案 | Runner | 等待时间 | 产出 |
|------|--------|---------|------|
| ❌ 旧方案 | macos-13 (Intel) | 排队1小时+ | 仅 x86_64 |
| ✅ 新方案 | macos-latest (ARM) | 秒启 | Universal (x86_64+arm64) |

### 打包逻辑变更

旧方案需要 Intel 包 + ARM 包两个 artifact，新方案只需一个 Universal 包：

```yaml
# 旧：分平台打包
# - macos-13 → x86_64/VST3
# - macos-14 → arm64/VST3
# 新：单个 Universal 包
- name: Package
  if: runner.os == 'macOS'
  run: |
    # CMAKE_OSX_ARCHITECTURES 已产出 Universal Binary，直接打包
    cd build/VST3
    zip -r "${{ github.workspace }}/plugin-mac-universal.zip" *.vst3
```

### 复用判断标准

遇到 macOS CI 问题时，先检查：
1. **同组织其他项目是否已解决？** → 直接复用
2. **是 Rust 项目？** → `--target universal-apple-darwin`
3. **是 CMake 项目？** → `CMAKE_OSX_ARCHITECTURES='x86_64;arm64'`
4. **都不是？** → 先搜索 GitHub Issues / 社区方案
