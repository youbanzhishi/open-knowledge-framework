### TOOLS.md v7.0

# ⛔ 铁律（违反=不可逆损害，按优先级排序）

## P0 数据安全（违反=数据丢失）
1. 删除→回收站：用mv移至`回收站/<名称>-<日期>/`，严禁rm
2. 改文件前先备份：修改前复制到回收站，覆盖=犯罪
3. 先读后动：必须读取文件内容再操作，禁止盲写

## P1 记忆安全（违反=知识丢失，智能体会失忆）
4. **体系角色必跑act.sh**：切换角色时先跑 `cd open-knowledge-system && bash scripts/act.sh "意图" . "角色/角色名"` 查知识和前科，避免踩重复的坑。act.sh v3.4用db.json索引加速（1-3秒），索引缺失会自动重建。执行失败时必须读取`.sync-conflict`文件汇报主人，严禁忽略冲突
5. 任务完成=执行+反哺：产出结果≠完成，必须过反哺检查门——更新项目INDEX、踩坑记knowledge、升级hot-rules、沉淀跨项目/角色经验。sub-agent未汇报反哺=任务未完成
6. 读写闭环+收工Flush：每干完一件实质性的活，回复用户前必须自检：改了什么→写回哪了→追踪更新了吗。收工时Flush所有未写知识。光干不写=白干
7. 文件定位：TOOLS只存放跨角色通用铁律；MEMORY只存放活跃/暂停/待办；已完成→项目INDEX，经验→角色knowledge，体系决策→体系优化追踪

## P2 权限安全（违反=越权风险）
8. 角色边界+执行门：每个角色有明确职责边界和执行门，不越界不跳步。14角色全覆盖：系统开发者六步门，其余角色五步门（①查后定方案→②执行→③自检验证→④反哺沉淀→⑤交付闭环）。ECS运维/前端开发另含专属交付门
9. **🔴 ECS凭据加密访问（所有角色强制）**：ECS Gateway Token加密存`共享知识/凭据/ecs-tokens.enc`，连接ECS前必须向主人获取密码→`openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -pass pass:<密码> -in 共享知识/凭据/ecs-tokens.enc -base64`解密→提取角色token(ops/dev/readonly/admin)。密码用完即丢禁止存文件；仓库凭据密钥存SECRET.md
10. 权限最小化：只用自己角色的token，严禁借用admin或他人token
11. 禁止越界操作服务器：ECS操作只能由ECS运维角色执行，其他角色需要时通过ECS运维
12. 体系推送：修改open-knowledge-system/下文件，验收通过后必须git push，过了不推=失职。推送用 `bash scripts/push.sh "描述"` 禁止手动git push
13. 重试熔断：写操作/部署操作/外部API调用失败2次→必须上报主人，禁止第3次自作主张。同类错误连续3次=卡死，必须切换方案或人工介入。智能体无权用主人的token无限试错

## 多智能体仓库操作铁律
1. 只add自己改的文件：`git add 文件1 文件2`，严禁`git add -A`或`git add .`
2. 严禁git stash：会收走他人未暂存变更
3. git操作排队：一个命令执行完再发下一个，避免抢index.lock
4. 锁文件处理：ops.lock/index.lock时，先`ps aux | grep git`确认：自己卡死→kill+rm；他人→等或上报
5. 推送用push.sh：`bash scripts/push.sh "描述"`，禁止手动git push
6. 索引自动维护：rebuild-index.sh自动维护，act.sh自动重建缺失索引，index/已加入.gitignore

## P3 效率规范
13. 禁扫无关目录，只读所需文件
14. 止损：同一错误≤2次，第3次换方案/上报
15. 知识沉淀：高价值及时写，跨项目→角色knowledge，当前项目→项目docs
16. 更新规则：流程→SKILL，踩坑→角色knowledge，进展→MEMORY，偏好→USER
17. 新工具注册：项目→INDEX，跨项目→角色RULES
18. 内容膨胀开独立仓库，体系留索引+指引
19. image_generate：count=1逐张；多图单配提示词；抽象补具象+反向；逐一查特征；批量分批次

## 工作方式：讨论和执行分开

> 2026-05-14 主人批评：边聊边改=反复修改=浪费token

1. 讨论阶段不动文件 — 只聊不改
2. 方案制定后给主人审核 — 整理清晰结构等确认
3. 确认后集中执行 — 一次性改完推一次

## Rust Web UI经验
1. HTML含`"#`时用`r##""##`非`r""""` | Axum版本：OL 0.7/OV 0.6/OM 0.7/胶带 0.8 | 胶带分支main非master
2. 修完bug立即提回归工单，不攒着


## 2026-05-19 push.sh & 体系操作经验
- **铁律**：永远用push.sh推送，禁止手动git push，无例外
- **push.sh反哺检查被拦截时**：把检查要求的文件重新add+commit进最新commit，再跑push.sh。不要绕过脚本
- **典型场景**：merge后体系优化追踪在merge commit里不在最新commit→单独commit一次再推
- **push.sh SSH模式**：另一agent改为v4.1默认SSH模式，当前环境无SSH key→用`GIT_MODE=https bash scripts/push.sh [-y] "描述"`
- **push.sh -y参数**：仅用于sub-agent无法交互场景，默认仍阻塞模式确保严格反哺
- **act.sh已内置交接台检查**：五步门不需要加"〇 读交接台"，物理拦截>流程提醒
- **角色成熟度评估**："无数据≠高分"，没有执行记录的维度不应默认给高分