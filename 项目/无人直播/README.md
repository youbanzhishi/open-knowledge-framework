# 无人直播

搭建无人值守直播推流体系，将直播流转推到B站/抖音等平台，实现24h稳定运行。

## 快速上手

- INDEX入口：`./INDEX.md`
- 关联角色：ECS运维
- 关联技能：无人直播推流技能（`./技能/无人直播推流技能/`）

## 关键地址

- SRS推流：`rtmp://39.103.203.162:1935/live/test`
- HLS播放：`http://39.103.203.162:8080/live/test.m3u8`
- 推流脚本：`/root/stream_relay/stream_relay.sh`
- systemd服务：`stream-relay.service`
