# Hermes Agent 部署与模型配置

## 核心结论

**Hermes Agent 需要单独的大模型 API，不能直接用扣子的"大脑"**

| 对比项 | 扣子平台 | Hermes Agent |
|--------|----------|--------------|
| 模型来源 | 平台内部接口 | 需自行配置 LLM API |
| API 暴露 | 不对外暴露 | 需要 OpenAI 兼容 API |
| 计费方式 | 平台统一 | 按各模型提供商计费 |

---

## 支持的模型来源

| 来源 | 说明 | 成本 | 推荐度 |
|------|------|------|--------|
| OpenRouter | 聚合 200+ 模型，一个 Key 通吃 | 按量付费 | ⭐⭐⭐ 推荐 |
| OpenAI | GPT-4o、o1、o3 等 | 付费 | ⭐⭐⭐ |
| Anthropic | Claude 系列 | 付费 | ⭐⭐⭐ |
| Ollama（本地） | 开源模型，免费运行 | 免费 | ⭐⭐（需硬件支持） |
| Google Gemini | Gemini 系列 | 按量付费 | ⭐⭐ |
| DeepSeek | 国产模型 | 按量付费 | ⭐⭐ |
| MiniMax | 国产模型 | 按量付费 | ⭐⭐ |

**推荐方案**：OpenRouter 最灵活，一个 Key 访问 200+ 模型，支持按需切换

---

## 本地模型可行性分析

### 云电脑当前配置

| 配置项 | 参数 |
|--------|------|
| CPU | 2核 AMD EPYC |
| 内存 | 3.8GB（可用约 1.3GB） |
| GPU | 无 |
| 磁盘 | 40GB（可用 17GB） |

### 结论

**勉强能跑，体验不好**

- 无 GPU，纯 CPU 推理很慢
- 内存紧张，只能跑极小模型（0.5b/1.5b）
- 小模型能力有限，响应速度慢

### 本地部署方案（如果坚持）

```yaml
# config.yaml 配置本地 Ollama
model:
  provider: ollama
  name: qwen2.5:1.5b  # 或 llama3.2:1b
  base_url: http://localhost:11434/v1
  api_key: NA
```

**前提**：需先安装 Ollama 并拉取模型
```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5:1.5b
```

---

## 扣子技能商店部署技能

**已安装**：「一键部署Hermes」（skill_id: 7632463335904215055）

- 用途：在扣子云电脑上一键部署 Hermes agent
- 前置条件：需准备好 LLM API Key 或配置本地 Ollama

---

## 配置示例

### OpenRouter 配置

```yaml
# ~/.hermes/config.yaml
provider:
  default: openrouter
  models:
    openrouter: anthropic/claude-3-5-sonnet

# ~/.hermes/.env
OPENROUTER_API_KEY=sk-or-xxxxxxxxxxxx
```

### 本地 Ollama 配置

```yaml
# ~/.hermes/config.yaml
provider:
  default: ollama
  models:
    ollama: qwen2.5:1.5b
```

---

## 沉淀时间

2026-04-28
