# Trait驱动分工模式

> 沉淀日期：2026-05-11
> 来源：OpenMind+胶带多Phase并行开发实践总结

## 核心原则

**依赖抽象(trait)，不依赖实现**——这是分工协作的前提，不只是代码优雅的问题。

## 类比对照

| Java | Rust | 作用 |
|------|------|------|
| interface | trait | 定义契约（能做什么） |
| implements | impl | 提供实现（怎么做） |
| Spring IoC | Registry模式 | 注册即可用，不硬编码 |
| 依赖注入 | 泛型参数 `<T: Trait>` | 用谁由调用方决定 |

## 为什么子任务不读全代码也能开发

1. **trait是墙**：把Phase隔开，Phase A不需要知道Phase B的内部实现
2. **API是门**：让Phase能串门（调接口）但不进卧室（改内部逻辑）
3. **Registry模式**：新功能注册即可用，不改核心代码

实际验证：
- 胶带Phase 8开发区块链，只用了ChainTimestamp trait，不读AES加密实现
- OpenMind Phase 5开发Action Protocol，只调KnowledgeStore trait，不读FTS5同步策略

## 如果trait没设计好会怎样

- 跨Phase耦合 → 子任务必须读相关代码才能开发
- 违反"注册即可用" → 改核心代码才能加新功能
- 这就是为什么架构铁律第一条：**Registry模式优先**

## 断点续推机制

项目写了一万行代码后agent挂了，新agent不需要读一万行代码：
- 读roadmap.md（几十行）→ 知道做到哪了
- 读要改的文件的trait签名 → 知道接口契约
- 不需要读其他Phase的实现代码

前提：每个Phase完成必须更新roadmap打勾+INDEX进度（断点续推生命线）。

## 与子任务策略的关系

- 塞满派发>分片派发（分片重建上下文代价远大于挂了抢救）
- 挂了抢救：代码在/tmp/丢不了 → git diff看进度 → commit push → 派续推任务
- trait设计好 → 续推agent只读契约不读实现 → 续推成本低
