# Extension Registry 设计模式

> 适用项目：OpenLink / OpenVault / OpenDAW
> 核心思想：新功能=注册扩展，架构本身永远不需要改

## 模式定义

四柱模型，覆盖所有扩展场景，永不需要新增：

| 柱 | 功能 | 注册什么 |
|----|------|---------|
| Action API | 注册新行为 | 执行动作（重定向/文件传输/工作流/插件加载...） |
| Condition API | 注册新条件 | 路由判断（设备类型/身份/网络/Agent类型...） |
| Hook API | 注册新拦截器 | 流程拦截（安全/日志/认证/改写/降级...） |
| Protocol API | 注册新协议适配器 | 通信协议（HTTP/MCP/A2A/自定义...） |

## 为什么有效

传统做法：新需求 → 改核心代码 → 加if/else → 越来越乱
Registry做法：新需求 → 写Extension → 注册 → 核心0改动

**举例**：加入人形机器人支持
- 传统：核心代码加`if is_robot { ... }`
- Registry：注册`PhysicalAgent` Condition + Action，核心不变

## 三个项目的映射

| OpenDAW | OpenLink | OpenVault | 共同模式 |
|---------|----------|-----------|---------|
| Plugin API | Action API | Policy API | 行为可插拔 |
| Script Runtime | Condition API | Classifier API | 逻辑可编程 |
| Model Bus | Context Bus | Inventory Bus | 数据可流转 |
| Hook System | Hook System | Verifier | 流程可拦截 |

## 共享crate可能

```
open-registry  → 通用扩展注册表实现
open-hooks     → 通用Hook调度器
open-bus       → 通用消息总线
```

三个项目共享底层crate，一套代码三个项目用。

## 使用原则

1. **核心层零业务逻辑** — 只做通用调度，不关心具体业务
2. **一切扩展通过Registry** — 新Action/Condition/Hook/Protocol，注册即用
3. **配置优于代码** — 扩展启停、优先级、参数，全部可配置
4. **已有扩展不改核心** — 扩展bug只改扩展，核心稳定

## Python+Rust混合架构模式

> 提炼项目：OpenDAW | 提炼时间：2026-05-09

### 模式定义

Python做业务层（API/CLI/Agent），Rust做性能层（音频引擎/插件宿主），两者通过FFI桥接。

```
Python FastAPI (55 API) ←→ opendaw-core/bridge.rs ←→ Rust引擎
    ↑                                                    ↑
  业务逻辑                                          实时性能
  快速迭代                                          零成本抽象
  AI/ML友好                                        内存安全
```

### 为什么有效

| 纯Python | 纯Rust | Python+Rust混合 |
|----------|--------|----------------|
| 开发快但性能差 | 性能好但开发慢 | 开发快且性能好 |
| GIL限制实时处理 | 异步生态不成熟 | Python管业务，Rust管实时 |
| AI/ML生态最强 | AI生态弱 | 直接用Python AI生态 |
| CLI/API极快搭 | CLI/API开发成本高 | FastAPI极快出API |

### 关键设计

1. **桥接层**：opendaw-core/bridge.rs，f32↔f64转换，AudioBuffer统一
2. **AppState**：Tauri统一持有AudioEngine + ExtensionRegistry + Python Backend
3. **API优先**：所有功能先出API，Rust引擎可选加

### 适用场景

- 需要实时性能但业务逻辑复杂的项目
- AI/ML集成需求强的项目
- 快速原型+逐步用Rust替换热点的策略

### 反面教训

1. serde版本约束要统一（Python侧的依赖没有版本上限问题，但Rust workspace有）
2. dev-dependencies不能在非测试代码中使用（混合项目更容易犯）
3. Tauri v2的Linux GLIBC要求比预期高得多
