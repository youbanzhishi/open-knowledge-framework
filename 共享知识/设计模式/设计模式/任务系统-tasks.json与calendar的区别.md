# 任务系统：tasks.json 与 calendar 的区别

> 记录时间：2026年4月25日  
> 来源：排查定时任务问题时发现两个系统不同步

---

## 问题背景

创建定时任务后，发现：
- `calendar_query` 能查到任务
- `tasks.json` 里却没有记录

**原因**：这是两个不同的系统。

---

## 两个系统的区别

| 系统 | 存储位置 | 说明 |
|------|---------|------|
| `tasks.json` | 本地文件 | 手动维护的任务记录 |
| `calendar_create` | 平台日历系统 | 实际的定时任务 |

---

## 详细对比

| 对比项 | tasks.json | calendar系统 |
|-------|-----------|-------------|
| **本质** | 文本文件 | 平台服务 |
| **触发** | 需要手动读取和执行 | 系统自动触发 |
| **可靠性** | 依赖Agent记忆 | 平台保证执行 |
| **持久性** | 文件存在即保留 | 永久保存 |
| **查看方式** | read_file读取 | calendar_query查询 |
| **修改方式** | edit_file编辑 | calendar_update/update |

---

## 正确的使用方式

### 创建定时任务
```python
# 使用 calendar_create 工具
calendar_create(
    summary="任务名称",
    dtstart="202604251000",
    rrule={"freq": "DAILY"},
    description="任务详情"
)
```

### 同步到 tasks.json（可选）
```
如果需要本地记录，创建任务后手动同步到 tasks.json
```

---

## 经验教训

1. **定时任务统一用 calendar_create**，不要自己造轮子
2. **tasks.json 只是辅助记录**，不要依赖它来执行任务
3. **创建任务后检查**：用 calendar_query 确认任务存在
4. **两套系统要同步**：如果用 tasks.json 记录，创建任务时记得写入

---

## 当前状态

- ✅ 定时任务统一使用 calendar_create
- ✅ tasks.json 作为任务清单的辅助记录
- ⚠️ 需要手动同步，避免遗漏

---

## 推荐做法

```
创建任务时：
1. calendar_create 创建实际任务
2. 同时写入 tasks.json 作为记录
3. 用 calendar_query 验证任务存在

查询任务时：
1. 用 calendar_query 查询实际任务
2. tasks.json 作为补充参考
```
