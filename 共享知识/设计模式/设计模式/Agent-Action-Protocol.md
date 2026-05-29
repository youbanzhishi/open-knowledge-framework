# Agent Action Protocol

> Agent间协作的标准化协议定义。Agent通过 `/.well-known/agent.json` 暴露能力，其他Agent按契约调用。

## 设计原则

1. **发现即接入**：通过 `/.well-known/agent.json` 自动发现Agent能力，无需预注册
2. **契约驱动**：每个Action定义清晰的输入输出Schema，调用方无需了解实现细节
3. **节点平等**：所有Agent节点地位平等，不存在中枢调度
4. **协议驱动**：交互基于HTTP+JSON，任何语言/框架均可实现

## Agent描述格式

每个Agent通过 `/.well-known/agent.json` 暴露以下信息：

```json
{
  "schema_version": "1.0",
  "name": "Agent名称",
  "description": "Agent功能描述",
  "version": "语义版本号",
  "base_url": "Agent服务基础URL",
  "capabilities": [
    {
      "name": "action名称",
      "description": "action功能描述",
      "endpoint": "HTTP方法和路径",
      "input": { /* 输入Schema */ },
      "output": { /* 输出Schema */ }
    }
  ],
  "links": {
    "docs": "文档URL",
    "source": "源码URL",
    "health": "健康检查URL"
  }
}
```

## Action描述格式

每个Action包含以下字段：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ✅ | Action名称，全小写下划线分隔（如 `semantic_search`） |
| description | string | ✅ | 功能描述，一句话说明做什么 |
| endpoint | string | ✅ | HTTP方法+路径（如 `POST /api/v1/search`） |
| input | object | ✅ | 输入Schema，键值对描述每个参数的类型和含义 |
| output | object | ✅ | 输出Schema，描述返回数据的结构 |
| triggers | string[] | ❌ | 触发场景描述，说明何时应该调用此Action |

### Action命名规范

- 全小写，下划线分隔
- 动词开头：`search_`, `find_`, `ingest_`, `get_`, `sync_`, `publish_`
- 避免模糊名称：用 `semantic_search` 而非 `search`

## Workflow描述格式

Workflow定义跨Agent的协作流程：

```json
{
  "name": "workflow名称",
  "description": "workflow功能描述",
  "steps": [
    {
      "agent": "Agent名称",
      "action": "Action名称",
      "input": { /* 输入参数，可引用前序步骤的输出 */ },
      "output_as": "本步骤输出的变量名"
    }
  ]
}
```

### 变量引用

步骤间通过 `output_as` 传递数据：
- 前序步骤的输出通过 `${步骤名.字段路径}` 引用
- 例如：`${search.results[0].content}` 引用search步骤第一个结果的content字段

## 示例Workflow

### search_and_mix（知识搜索→音频混合→发布）

```json
{
  "name": "search_and_mix",
  "description": "搜索知识库内容，生成混音，发布到互联网",
  "steps": [
    {
      "agent": "OpenMind",
      "action": "semantic_search",
      "input": {
        "query": "${user_query}",
        "mode": "hybrid",
        "limit": 5
      },
      "output_as": "search"
    },
    {
      "agent": "OpenDAW",
      "action": "generate_mix",
      "input": {
        "prompt": "${search.results[0].content}",
        "style": "ambient"
      },
      "output_as": "mix"
    },
    {
      "agent": "OpenLink",
      "action": "publish",
      "input": {
        "content": "${mix.audio_url}",
        "title": "Generated from ${search.results[0].source}"
      },
      "output_as": "published"
    }
  ]
}
```

### find_and_act（查找待办→执行操作）

```json
{
  "name": "find_and_act",
  "description": "查找待办事项并执行相关操作",
  "steps": [
    {
      "agent": "OpenMind",
      "action": "find_todos",
      "input": {
        "query": "${user_query}",
        "filters": { "type": "todo" }
      },
      "output_as": "todos"
    }
  ]
}
```

## 当前已实现Agent

| Agent | Base URL | Actions |
|-------|----------|---------|
| OpenMind | http://localhost:9090 | semantic_search, find_todos, ingest, get_related |
| OpenDAW | http://localhost:8080 | （待注册） |
| OpenLink | http://localhost:7070 | （待注册） |

## 实现检查清单

新Agent接入生态时，需完成以下步骤：

- [ ] 实现 `/.well-known/agent.json` 端点
- [ ] 按Action描述格式定义所有capabilities
- [ ] 确保所有endpoint的输入输出与Schema一致
- [ ] 在本文档的"当前已实现Agent"表中注册
- [ ] 在入口中更新版本号
