# Python (OpenDAW/VCMix) CI 模式

> 从 OpenDAW 项目提炼的 Python 项目 CI 最佳实践

## OpenDAW 现有 CI 架构

```
test.yml (push/PR触发):
  test(3OS × 4版本矩阵) → build-wheel

docker.yml (tag/手动触发):
  build-core(精简镜像) → build-full(全功能镜像)

release.yml (tag触发):
  test → build-and-publish-pypi + build-and-push-docker → create-release
```

## 关键模式

### 1. 多版本测试矩阵

```yaml
matrix:
  os: [ubuntu-latest, macos-latest, windows-latest]
  python-version: ["3.9", "3.10", "3.11", "3.12"]
```

覆盖主流环境，确保兼容性。

### 2. Docker多Profile

| Profile | 内容 | 镜像大小 | 用途 |
|---------|------|---------|------|
| core | 纯Python，无AI依赖 | ~200MB | 基础混音/分析 |
| full | 含PyTorch/Demucs | ~3GB | AI分离/增强 |

标签策略：`core-latest` + `core-v1.2.3` + `full-latest` + `full-v1.2.3`

### 3. PyPI可信发布

```yaml
permissions:
  id-token: write  # OIDC trusted publishing
```

不需要API Token，GitHub直接OIDC认证发布到PyPI。

### 4. Docker GHA缓存

```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

这是从OpenDAW提炼的——GHA原生缓存比自己管理registry缓存简单得多。

## 可被 open-dev-tools 标准化的部分

1. **justfile模板**：Python版（pip + pytest + build）
2. **Docker模板**：多Profile Dockerfile
3. **Release模板**：PyPI + GHCR + GitHub Release三连发

## OpenDAW 的进阶模式（可被其他项目借鉴）

### 5. WebSocket实时推送

API修改数据后，通过WebSocket广播变更事件给前端，用户实时看到操作结果。

```python
from vcmix.web.websocket import emit_stream_event_sync

# API handler中，操作成功后广播
emit_stream_event_sync({
    "type": "project_updated",
    "project_id": project_id,
    "action": "param_change",
    "detail": {"track": track_name, "param": param_name, "value": new_value},
    "ts": time.time() * 1000,
})
```

**设计要点**：
- broadcast只推轻量摘要，不推整个项目数据
- 前端收到后自己调GET API获取最新数据
- emit_stream_event_sync包裹在try/except中，WebSocket不可用时不影响API功能
- 只在修改类API（POST/PUT/DELETE）中加，查询类不加

### 6. MCP Server（让外部Agent框架能操控你的应用）

通过MCP（Model Context Protocol）暴露API，让OpenClaw/Hermes等外部Agent能直接操控。

```python
class VCMixMCPServer:
    def list_tools(self) -> list[MCPTool]:
        """返回API映射的MCP工具列表"""
    
    def call_tool(self, name: str, arguments: dict) -> MCPResult:
        """执行MCP工具调用 → 复用现有ToolExecutor"""
```

**设计要点**：
- MCP Server复用现有API调用逻辑，不重复实现
- 支持SSE传输（HTTP）+ JSON-RPC 2.0
- 外部Agent操作在前端标记来源（"[外部Agent] 执行了xxx操作"）
- 这样你的应用不是孤岛，而是Agent生态的一个能力节点

### 7. Agent Plugin（嵌入式领域专家）

不是独立Agent框架，而是嵌入应用的领域专家。核心差异：

| 独立Agent框架 | 嵌入式Agent |
|-------------|-----------|
| 独立服务，调API | 同进程零延迟 |
| 通用，不懂数字音频 | 领域专家，懂EQ/压缩参数 |
| 黑盒操作 | 每步操作可见+附理由 |
| 无记忆 | 三层记忆+反馈学习 |
| 不可进化 | 用户调教出专属助手 |

**架构**：AgentRuntime(ReAct循环) + ModelBus(多LLM) + ToolBox(API工具映射) + Memory + Persona

### 8. 混音链系统（兼容竞品格式）

YAML定义链 + 兼容Waves StudioRack .xps格式（双向导入导出）。

```yaml
chain:
  serial:
    - plugin: vc-deesser
      params: {threshold: -30}
    - plugin: vc-eq
      params: {high_gain: 3}
  parallel:
    - mix: 0.3
      chain:
        - plugin: vc-saturator
          params: {drive: 3}
macro:
  - name: "亮度"
    mapping:
      - plugin: vc-eq
        param: high_gain
        range: [0, 6]
```

**设计要点**：
- 开源格式YAML优先，私有格式.xps双向兼容
- 8个Macro控制：一个旋钮控制链内多个参数
- 社区分享（ChainVerse）：上传/搜索/评分/AI推荐

### 9. Tauri v2桌面壳 + Python后端混合架构

桌面app用Tauri壳（WebView），后端用Python FastAPI，Rust引擎做实时音频。

```
Tauri(AppState) → Python后端(55 API) → 前端WebView
                 → Rust引擎(AudioEngine + ExtensionRegistry)
```

**教训**：
- Tauri v2 Linux最低需要ubuntu-24.04（webkit2gtk-4.1要GLIBC 2.39）
- AppImage不等于完全自包含——glibc仍依赖系统
- Cargo workspace加入Tauri后要检查serde版本约束兼容性
