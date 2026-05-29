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
