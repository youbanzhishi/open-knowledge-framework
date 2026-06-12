# 掘金API Cookie配置

## 关键发现（2026-04-27）

**`csrf_session_id` 已不存在！**

掘金API现在不需要 `csrf_session_id`，只需要完整的Cookie字符串。

## 正确的Cookie格式

```
sessionid=19e1b53cbf58a31bd88dd35b7c78ed7e; sid_guard=19e1b53cbf58a31bd88dd35b7c78ed7e%7C1777509475%7C31536000%7CFri%2C+30-Apr-2027+00%3A37%3A55+GMT; sessionid_ss=19e1b53cbf58a31bd88dd35b7c78ed7e; uid_tt=1af9ccbdd2151c416b3c544a5a6b57ac; uid_tt_ss=1af9ccbdd2151c416b3c544a5a6b57ac; n_mh=e4x5jqdtfkdY7w4-3d7fXEa9Ey-4gO3YqukXhRn8jxk; s_v_web_id=verify_mokqr7q7_vCkmJ9Zf_eWwh_41ZC_AgxQ_LmSOawn0dEix; passport_csrf_token=5404b83eb1f07ebbe7dc7fbaac7d8a31; passport_csrf_token_default=5404b83eb1f07ebbe7dc7fbaac7d8a31
```

## 必需的Cookie项

| Cookie名称 | 说明 | 必须 |
|-----------|------|------|
| sessionid | 会话ID | ✅ 是 |
| uid_tt | 用户追踪ID | ✅ 是 |
| passport_csrf_token | CSRF令牌 | ✅ 是 |
| s_v_web_id | 验证ID | ✅ 是 |
| sid_guard | 会话保护 | ✅ 是 |

## Cookie获取方法

### 方法1：浏览器工具
```bash
agent-browser cookies list
```

### 方法2：JavaScript
```javascript
document.cookie
```

## API调用示例

### 签到状态查询
```bash
curl -s "https://api.juejin.cn/growth_api/v1/get_today_status" \
  -H "Cookie: $COOKIE" \
  -H "Referer: https://juejin.cn/"
```

### 签到
```bash
curl -X POST "https://api.juejin.cn/growth_api/v1/check_in" \
  -H "Cookie: $COOKIE" \
  -H "Content-Type: application/json" \
  -H "Referer: https://juejin.cn/" \
  -d '{}'
```

### 抽奖
```bash
curl -X POST "https://api.juejin.cn/growth_api/v1/lottery/draw" \
  -H "Cookie: $COOKIE" \
  -H "Content-Type: application/json" \
  -H "Referer: https://juejin.cn/user/center/lottery" \
  -d '{}'
```

## 测试结果（2026-04-27）

| API | 状态 | 结果 |
|-----|------|------|
| 签到状态 | ✅ | 成功 |
| 签到 | ✅ | 成功 |
| 抽奖 | ✅ | 抽中33矿石 |

## 注意事项

1. Cookie有效期有限，过期需要重新获取
2. 使用完整Cookie字符串，不要只传部分Cookie
3. Referer头必须设置正确
4. 抽奖需要先签到获得免费次数


## 2026-04-28 更新：抽奖需要动态Token

**关键发现**：抽奖API现在需要 `x-secsdk-csrf-token` 请求头

这个Token是字节跳动安全SDK（secsdk）动态生成的，每次请求都不同，无法从Cookie直接获取。

### API端点现状

| API | 状态 | 说明 |
|-----|------|------|
| 签到API | ✅ API可用 | 只需Cookie |
| 签到状态API | ✅ API可用 | 只需Cookie |
| 矿石查询API | ✅ API可用 | 只需Cookie |
| 抽奖配置API | ❌ 需要Token | 返回空响应 |
| 抽奖执行API | ❌ 需要Token | 返回空响应 |

### 解决方案

**签到**：继续使用API方案（稳定、风控风险低）
**抽奖**：使用浏览器方案（自动处理动态Token）

### x-secsdk-csrf-token 示例

```
x-secsdk-csrf-token: 00010000000153fa4d7b3e5a9796a6d6e78790415b6fb6c04298d9b212476c127475491fb3d118aa57eb8478e2d1
```

这个Token由前端JavaScript动态计算，每次请求值都不同。
