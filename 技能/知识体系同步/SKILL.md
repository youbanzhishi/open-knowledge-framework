# 知识体系同步技能

## 目标
将知识体系同步目录推送到Git仓库，保持主对话和知识体系同步。

## 步骤

### 步骤1：执行Git推送
```bash
cd /app/data/所有对话/主对话/知识体系同步
git add -A
git commit -m "知识体系自动同步"
GIT_SSH_COMMAND="ssh -i /root/.ssh/id_ed25519_openks -o StrictHostKeyChecking=no" git push origin main
```

### 步骤2：记录结果
- 推送成功：记录当前时间到执行记录
- 推送失败：记录错误信息，等待修复后重试

## 禁止事项
- ❌ 不要修改已推送的内容
- ❌ 不要强制推送（--force）
- ❌ 冲突时不要自动合并

## 前提条件
- 已配置SSH密钥：/root/.ssh/id_ed25519_openks
- Git远程仓库可访问
