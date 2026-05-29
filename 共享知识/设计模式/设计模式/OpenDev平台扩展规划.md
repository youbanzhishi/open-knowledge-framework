# OpenDev 平台扩展规划

> OpenDev生态不只是服务器项目，而是覆盖全平台的Agent生态。本文档定义从服务器到嵌入式到XR的全平台扩展策略，核心洞察是：**Agent Action Protocol基于HTTP+JSON，天然设备无关；Rust交叉编译让一套代码覆盖所有平台；轻量设备不需要跑完整服务，当Agent客户端调API就行。**

---

## 1. 愿景

OpenDev生态的四个核心项目——OpenDAW（数字音频工作站）、OpenLink（短链与发现服务）、OpenVault（加密存储）、OpenMind（知识引擎）——目前运行在服务器和桌面上。但Agent的价值不在于它跑在哪台机器上，而在于它能在你需要的时候出现在你手边的任何设备上。

**演进路线：服务器 → 桌面 → NAS → 移动 → 嵌入式 → XR**

每个阶段不是替换前一阶段，而是叠加。服务器永远是全功能节点，移动端是它的眼睛和手，路由器是它的神经末梢，VR是它的空间延伸。所有设备通过Agent Action Protocol对话，协议不关心对方是8核Xeon还是128MB的MIPS路由器。

这个规划的核心判断是：**不是每个设备都要跑完整服务，但每个设备都能成为生态的一个节点。** 能力强的设备提供能力，能力弱的设备消费能力，中间用HTTP+JSON沟通——这就是Agent Action Protocol的设计初衷。

---

## 2. 平台适配矩阵

| 平台 | 角色 | Rust编译目标 | 资源需求 | 接入方式 |
|------|------|-------------|---------|---------|
| 服务器(x86) | 全功能节点 | `x86_64-unknown-linux-gnu` | 无限 | 完整服务 |
| 桌面(Windows/Mac/Linux) | 全功能+GUI | `x86_64-pc-windows-msvc` / `aarch64-apple-darwin` / `x86_64-unknown-linux-gnu` | 4G+ | Tauri应用 |
| NAS(群晖/威联通/自组) | 家庭全功能节点 | `x86_64-unknown-linux-gnu` / `aarch64-unknown-linux-gnu` | 2G+ | Docker完整服务 |
| 移动(Android/iOS) | Agent客户端 | `aarch64-linux-android` / `aarch64-apple-ios` | 2G+ | API调用+本地缓存 |
| 路由器(OpenWrt) | 边缘Agent节点 | `mips-unknown-linux-musl` / `aarch64-unknown-linux-musl` | 64-256MB | 轻量Agent |
| VR/AR | Agent客户端+3D渲染 | `x86_64-pc-windows-msvc`(SteamVR) / `aarch64-linux-android`(Quest) | 4G+ | Rust FFI→Unity/Unreal |
| WASM | 浏览器Agent | `wasm32-unknown-unknown` | 浏览器限制 | API调用 |

**矩阵解读：**

- **角色分三档**：全功能节点（跑所有服务，含NAS）、Agent客户端（调API不跑服务）、边缘Agent节点（跑轻量服务+调API）
- **编译目标是Rust的强项**：`cargo build --target`一行命令切换，同一份核心逻辑编译到六个平台
- **资源需求决定角色**：不是主观选择跑什么，而是硬件能力决定你能跑什么
- **接入方式因平台而异**：服务器跑完整二进制，移动端调HTTP API，路由器跑musl静态二进制，VR通过FFI桥接

---

## 3. NAS接入方案

**优先级：P0（最自然的家庭服务器，比云ECS更近用户）**

NAS是OpenDev生态的**完美家庭节点**——它有存储、有算力、有网络、7×24在线、Docker原生支持，而且就在你家里。

### 3.1 NAS能做什么

NAS是**家庭全功能节点**，地位等同于云服务器，但优势是存储无限、带宽不收费、延迟极低：

- **OpenVault主存储**：NAS天生就是存文件的。3-2-1备份策略的第一份就在NAS上，本地读写零延迟，远端备份走S3/异地NAS
- **OpenMind完整实例**：NAS 2G+ RAM足够跑Qdrant+SQLite，家庭的私人知识库跑在家里比跑在云上更合理——数据不出家门
- **OpenLink边缘节点**：短链解析和agent.json缓存，配合云上OpenLink做地理分发
- **OpenDAW构建机**：NAS CPU虽然不强，但7×24不间断，适合做持续编译+自动发布
- **OpenVault就近备份**：手机/电脑的文件自动备份到NAS上的Vault实例，局域网速度跑满

### 3.2 NAS vs 云ECS vs 云电脑

| 维度 | NAS | 云ECS | 云电脑 |
|------|-----|-------|--------|
| 存储 | 大(TB级) | 小(几十GB) | 中(40G) |
| 带宽 | 局域网极速，出站家用宽带 | 1Mbps出站硬伤 | 出站不限速 |
| 算力 | 中(ARM/x86 2-4核) | 中(1.8G RAM紧) | 中(2核3.8G) |
| 在线时间 | 7×24 | 7×24 | 按需 |
| 数据主权 | 完全本地 | 云上 | 云上 |
| 公网访问 | 需DDNS/frp | 有公网IP | 无开放端口 |
| 成本 | 一次性硬件 | 月付 | 月付 |

**结论**：NAS+云ECS互补——NAS当家庭数据中心和存储节点，云ECS当公网入口和路由层。这与"云电脑+ECS互补架构"同理。

### 3.3 主流NAS支持情况

| NAS | CPU架构 | Docker | RAM | 推荐度 |
|-----|--------|--------|-----|--------|
| 群晖DS224+ | Intel Celeron J4125 (x86) | ✅原生支持 | 2G(可扩展) | ⭐⭐⭐⭐ |
| 群晖DS923+ | AMD Ryzen R1600 (x86) | ✅原生支持 | 4G(可扩展) | ⭐⭐⭐⭐⭐ |
| 威联通TS-464C | Intel Celeron N5095 (x86) | ✅原生支持 | 4G | ⭐⭐⭐⭐⭐ |
| 威联通TS-233 | ARM Cortex-A55 | ✅Container Station | 2G | ⭐⭐⭐ |
| 自组NAS(UNRAID/TrueNAS) | 任意x86 | ✅原生 | 自定义 | ⭐⭐⭐⭐⭐ |

### 3.4 技术路径

```
已有Docker镜像 → NAS Docker Compose → 一键部署全家桶
```

关键步骤：
1. **Docker Compose全家桶**：一个`docker-compose.yml`拉起OpenDAW+OpenLink+OpenVault+OpenMind+Qdrant
2. **数据持久化**：NAS挂载目录做volume，数据跟着NAS走，容器随时重建
3. **局域网发现**：mDNS/Bonjour让局域网设备自动发现NAS上的服务
4. **外网访问**：通过ECS的frp隧道暴露到公网，或DDNS直连
5. **备份策略**：NAS本地→异地NAS/S3（3-2-1的第二、三份）

### 3.5 NAS独特优势

- **数据不出家门**：私人知识库、文件保险箱，敏感数据不需要上云
- **局域网速度**：1Gbps局域网，文件传输/知识搜索比云上快10倍
- **存储成本归零**：已有NAS的话，跑OpenDev服务是零额外成本
- **家庭共享**：一台NAS服务全家设备，手机/电脑/电视都通过局域网访问

---

## 4. 移动平台接入方案

**优先级：P1（用户需求最强）**

### 3.1 移动端能做什么

移动端是**Agent客户端**，不是全功能节点。这意味着它消费生态能力，但不提供能力：

- **OpenLink短链**：天生适配移动场景。短链在微信/Twitter/任何App里都能点击，移动端负责解析和跳转。更重要的是，移动端是短链的**分发入口**——用户在手机上创建短链、分享短链，这是最高频的操作
- **OpenMind搜索**：手机上直接调搜索API，结果渲染成卡片。不需要在手机上跑Qdrant向量数据库，只需要把查询发给服务器上的OpenMind实例
- **OpenVault**：手机端做加密缓存——上传文件时加密再发送，下载后解密再展示。密钥在本地，服务器只存密文
- **OpenDAW**：移动端做不了音频处理（CPU/内存不够），但可以做远程控制——调API触发服务器上的渲染任务，下载成品

### 3.2 移动端不能做什么

- **不能跑Qdrant/OpenMind重服务**：向量搜索需要大量内存，手机不是干这个的
- **不能做全功能OpenDAW**：实时音频处理需要低延迟和专用音频驱动，移动端只能做回放和控制
- **不能当发现节点**：移动IP不固定，NAT后面，不适合暴露agent.json

### 3.3 技术路径

```
Rust核心库 → uniffi/FFI → mobile crate → Kotlin(Android) / Swift(iOS) 壳
```

具体步骤：

1. **抽取共享Rust crate**：把HTTP客户端、加密、协议解析等逻辑抽取为独立的`opendev-mobile` crate
2. **uniffi生成绑定**：Mozilla的uniffi从Rust代码自动生成Kotlin/Swift绑定，比手写FFI可靠一个数量级
3. **平台壳**：Android用Kotlin写UI和生命周期管理，iOS用Swift写UI和生命周期管理，核心逻辑全在Rust里
4. **为什么不用Tauri Mobile**：Tauri移动端还不够成熟（截至2025年初），而uniffi方案已经被Firefox、1Password等生产级App验证过

### 3.4 移动端Agent Action Protocol集成

移动端虽然是客户端，但也需要"说话"Agent Action Protocol：

- 发送HTTP请求调其他Agent的Action
- 本地缓存最近的agent.json发现结果（离线时也能展示已知能力）
- 通过WebSocket接收服务器推送（任务完成通知、渲染进度等）

---

## 5. 路由器/嵌入式接入方案

**优先级：P2（IoT场景）**

### 4.1 路由器能做什么

路由器是**边缘Agent节点**，它既是客户端也是轻量服务端：

- **OpenLink边缘节点**：短链解析是极轻量操作——收到短链请求，查本地缓存，命中就302跳转，没命中就回源。路由器天然在网络入口，做短链解析比回服务器快一个数量级
- **agent.json缓存**：路由器缓存局域网内所有Agent的agent.json，设备入网时先问路由器"附近有什么Agent"，不需要每个设备都去远端发现
- **OpenVault就近备份**：局域网内的设备把数据加密后备份到路由器挂的USB硬盘，路由器只负责存密文，不解密不看内容
- **IoT网关**：智能家居设备通过路由器接入OpenDev生态，路由器把Zigbee/BLE协议翻译成Agent Action Protocol

### 4.2 路由器不能做什么

- **不能跑Qdrant**：向量数据库动辄数GB内存，路由器64MB RAM根本不够
- **不能跑OpenMind**：语义搜索需要GPU或大量CPU，MIPS核心算力不够
- **不能跑OpenDAW**：音频处理需要实时性保证，Linux内核调度器在路由器上不是RT配置
- **不能当全功能节点**：只能跑最轻量的Agent逻辑

### 4.3 技术路径

```
Rust → musl静态编译 → opkg/ipk包 → OpenWrt安装
```

关键决策：

- **musl静态链接**：`x86_64-unknown-linux-musl`和`mips-unknown-linux-musl`编译出的二进制零依赖，不依赖glibc版本，直接跑在OpenWrt上
- **编译目标**：
  - 常见路由器（小米/TP-Link/华硕）：`mips-unknown-linux-musl`（MT7621等MIPS芯片）
  - 新款Wi-Fi 6/7路由器：`aarch64-unknown-linux-musl`（IPQ807x等ARM芯片）
- **包管理**：打包为opkg格式（.ipk），通过OpenWrt的包管理器安装更新
- **内存预算**：64MB RAM的极限分配——Agent核心逻辑8MB + HTTP服务4MB + 缓存8MB + 系统44MB = 刚好够用

### 4.4 资源预算（64MB RAM极限）

| 组件 | 内存占用 | 说明 |
|------|---------|------|
| OpenWrt系统 | ~30MB | 含内核+基础服务 |
| opendev-agent核心 | ~8MB | Agent运行时+协议解析 |
| HTTP服务（hyper/actix） | ~4MB | 轻量HTTP服务 |
| 缓存（短链+agent.json） | ~8MB | LRU缓存，过期淘汰 |
| 预留 | ~14MB | 网络缓冲+突发 |

**结论**：64MB能跑，但很紧。128MB是舒适线，256MB可以加更多缓存。这也是为什么路由器角色是"边缘Agent"而不是"全功能节点"。

---

## 6. VR/AR接入方案

**优先级：P3（技术前沿，需求尚远）**

### 5.1 VR/AR能做什么

VR/AR是Agent的**空间延伸**，把二维的API调用变成三维的交互体验：

- **Agent客户端（HTTP调生态API）**：语音说"帮我找关于Rust内存安全的资料"→ 调OpenMind搜索API → 结果以3D卡片形式浮现在空间中
- **OpenDAW音频引擎 → VR空间音频**：服务器上渲染的音频通过空间化处理在VR中播放，用户可以在3D空间中"走动混音"——靠近某条音轨声音变大，远离则变小
- **OpenMind知识图谱 → 3D知识空间**：语义搜索结果不是列表，而是一个可导航的3D知识图谱。概念是节点，关系是连线，用户可以"飞"进去探索
- **Agent Action Protocol在VR里 = 语音指令串联多项目能力**：说"把这个知识节点做成音频笔记"→ 调OpenMind获取内容 → 调OpenDAW生成语音 → 调OpenVault存档，一条语音串联三个项目

### 5.2 VR/AR不能做什么

- **不能跑向量搜索**：VR头显的CPU/GPU全给了渲染，没有余力跑重计算
- **不能长时间后台运行**：VR应用受电池和散热限制，不能当常驻服务
- **不能独立做完整Agent**：必须依赖服务器端的全功能节点

### 5.3 技术路径

```
Rust FFI → C ABI → Unity/Unreal插件
```

分层架构：

```
┌─────────────────────────┐
│   Unity/Unreal 渲染层    │  C#/Blueprint，负责3D渲染和交互
├─────────────────────────┤
│   Rust FFI 桥接层        │  C ABI，暴露Agent核心API给引擎
├─────────────────────────┤
│   opendev-vr crate      │  Rust，Agent客户端+协议+加密
├─────────────────────────┤
│   Agent Action Protocol  │  HTTP+JSON，与服务器通信
└─────────────────────────┘
```

编译目标：

- **PC VR（SteamVR/Index/Vive）**：`x86_64-pc-windows-msvc`，编译为DLL
- **一体机（Quest/Pico）**：`aarch64-linux-android`，编译为.so
- **Apple Vision Pro**：`aarch64-apple-ios`，通过Swift桥接

### 5.4 为什么是P3

VR/AR的Agent场景极具想象力，但当前面临三个现实：

1. **用户基数小**：VR头显装机量远不如手机，投入产出比低
2. **交互范式未定**：VR中的Agent交互是语音？手势？眼动？还没有公认范式
3. **技术栈复杂**：需要同时懂Rust FFI + Unity/Unreal + 空间计算，人才稀缺

但它值得规划，因为Agent的终极形态就是在空间中和人自然交互。Phase 4是远期目标，现在把架构留好就行。

---

## 7. WASM/浏览器接入方案

**优先级：P1（已有Web API，前端天然适配）**

### 6.1 WASM能做什么

浏览器是最轻量的Agent客户端，打开即用，零安装：

- **OpenLink短链服务前端**：用户在浏览器中创建短链、查看统计、管理链接。短链的命中/回源数据可以实时展示
- **OpenMind搜索界面**：浏览器调搜索API，结果用React/Vue渲染。WASM可以做客户端排序、高亮、缓存
- **OpenVault文件管理**：浏览器中上传下载加密文件。加密/解密逻辑用WASM在客户端完成，密钥不离开浏览器
- **Agent发现面板**：浏览器展示局域网/云端所有Agent的agent.json，可视化Agent拓扑

### 6.2 WASM不能做什么

- **不能跑重计算**：浏览器有5秒卡顿限制，长时间任务会弹"页面无响应"
- **不能直接访问硬件**：没有文件系统、没有GPU计算（WebGPU还在普及中）
- **不能做服务端**：浏览器只能发起请求，不能监听端口

### 6.3 技术路径

```
Rust → wasm32-unknown-unknown 编译 → wasm-pack打包 → npm包 → 前端集成
```

关键点：

- **wasm-pack**：Rust官方推荐的WASM打包工具，自动生成JS绑定和TypeScript类型
- **不需要完整的Rust运行时**：只编译需要的模块（HTTP客户端、加密、协议解析），WASM包体积可以控制在100KB以内
- **Web Workers**：重计算放Worker线程，不阻塞UI
- **已有Web API**：OpenLink和OpenMind已经暴露HTTP API，WASM前端是增量工作而非从零开始

### 6.4 为什么是P1

- 已有HTTP API，前端适配是自然延伸
- 浏览器用户基数最大，覆盖最广
- 技术成熟度高，wasm-pack生态稳定
- 是移动端之前的"轻量验证"——先在浏览器验证Agent客户端模式，再移植到手机

---

## 8. Agent Action Protocol 平台适配规范

Agent Action Protocol的设计初衷就是设备无关，但不同平台的设备能力差异巨大，需要在协议层做能力声明和降级协商。

### 7.1 协议层设备无关

HTTP+JSON是最低公共分母——任何能发HTTP请求的设备都能说Agent Action Protocol。不需要gRPC的二进制协议（嵌入式跑不了），不需要WebSocket长连接（路由器内存不够维持），就是最简单的HTTP请求-响应：

```
客户端: POST /api/v1/search  {"query": "Rust内存安全"}
服务端: 200 OK  {"results": [...]}
```

这段对话在8核服务器上、在手机App里、在路由器的curl里、在浏览器的fetch里，完全一样。

### 7.2 发现层：agent.json两级缓存

agent.json是一级发现——每个Agent通过`/.well-known/agent.json`暴露能力。路由器可以做二级缓存：

1. **一级发现**：直接访问目标Agent的`/.well-known/agent.json`
2. **二级发现**：访问路由器缓存的`/agent-registry.json`，包含局域网内所有已知Agent的agent.json摘要

这意味着设备入网时只需要问路由器一次"附近有什么Agent"，而不需要逐个去发现。路由器定期刷新缓存，离线设备也能看到最近已知的Agent列表。

### 7.3 轻量客户端规范

不是所有设备都需要跑完整Agent服务。定义三种运行时模式：

| 模式 | 说明 | 能力 |
|------|------|------|
| `full` | 全功能节点 | 运行所有服务，暴露agent.json，接受其他Agent调用 |
| `client` | 纯客户端 | 只调其他Agent的API，不暴露agent.json，不接受调用 |
| `edge` | 边缘节点 | 跑轻量服务+调API，暴露有限agent.json，接受局域网调用 |

`client`模式是移动端和浏览器的默认模式——它们只消费能力，不提供能力。`edge`模式是路由器的模式——它提供有限的局域网服务（短链解析、缓存），但不承担重计算。

### 7.4 设备能力声明

agent.json新增`platform_capabilities`字段，让调用方知道对方的能力边界：

```json
{
  "schema_version": "1.0",
  "name": "OpenLink-Edge",
  "description": "OpenLink路由器边缘节点",
  "version": "0.1.0",
  "base_url": "http://192.168.1.1:8901",
  "platform_capabilities": {
    "runtime": "edge",
    "max_memory_mb": 256,
    "supports_streaming": false,
    "supports_websocket": false,
    "local_storage": true,
    "supported_actions": ["resolve_short_link", "cache_agent_json"],
    "network_scope": "lan"
  },
  "capabilities": [
    {
      "name": "resolve_short_link",
      "description": "解析短链并重定向",
      "endpoint": "GET /s/{code}",
      "input": { "code": "string" },
      "output": { "url": "string", "cached": "boolean" }
    }
  ]
}
```

`platform_capabilities`字段说明：

| 字段 | 类型 | 说明 |
|------|------|------|
| `runtime` | enum | `full` / `client` / `edge`，决定设备的角色 |
| `max_memory_mb` | number | 最大可用内存，调用方据此判断是否能委派任务 |
| `supports_streaming` | boolean | 是否支持SSE/流式响应，路由器通常不支持 |
| `supports_websocket` | boolean | 是否支持长连接，内存受限设备通常不支持 |
| `local_storage` | boolean | 是否有本地持久化能力 |
| `supported_actions` | string[] | 该设备实际支持的Action子集，`client`模式为空 |
| `network_scope` | enum | `lan` / `wan` / `both`，声明网络可达范围 |

**降级协商**：当调用方发现目标Agent的`runtime`是`edge`或`client`时，应避免委派重计算任务。当`supports_streaming`为false时，改用轮询模式获取长任务结果。当`network_scope`为`lan`时，云端Agent不应尝试调用它。

---

## 9. 演进路线

### Phase 1：当前——服务器+桌面+NAS，完整服务节点

- ✅ 服务器运行OpenDAW/OpenLink/OpenVault/OpenMind全功能节点
- ✅ 桌面通过Tauri应用提供GUI
- ✅ Agent Action Protocol在服务器间稳定运行
- 📌 当前状态：四个项目核心功能可用，桌面Tauri应用开发中

### Phase 2：WASM前端 + 移动端Agent客户端

- 🎯 浏览器前端：OpenLink短链管理面板、OpenMind搜索界面
- 🎯 移动端：`opendev-mobile` crate + uniffi + Kotlin/Swift壳
- 🎯 agent.json增加`platform_capabilities`字段
- 🎯 轻量客户端规范定稿（`client`模式定义）
- **关键里程碑**：手机上能调OpenMind搜索、能创建和分享OpenLink短链

### Phase 3：路由器边缘Agent节点

- 🎯 `opendev-edge` crate，musl静态编译
- 🎯 OpenWrt opkg包，一键安装
- 🎯 OpenLink边缘节点（短链解析+agent.json缓存）
- 🎯 路由器作为局域网Agent发现中心
- **关键里程碑**：路由器上跑`opendev-agent`，局域网设备通过路由器发现所有Agent

### Phase 4：VR/AR空间计算Agent

- 🎯 `opendev-vr` crate，C ABI导出
- 🎯 Unity/Unreal插件
- 🎯 OpenMind知识图谱3D可视化
- 🎯 OpenDAW空间音频
- 🎯 语音指令串联Agent Action Protocol
- **关键里程碑**：在VR中说"帮我找……"得到3D知识空间

**每个Phase不阻塞其他**。Phase 2的WASM前端和移动端可以并行开发。Phase 3的路由器方案可以和Phase 2同步验证（用树莓派模拟路由器环境）。按需求驱动，不按阶段死等。

---

## 10. 关键技术支撑

### 9.1 Rust交叉编译：一次编写到处编译

这是整个扩展规划的技术基石。Rust的交叉编译能力意味着：

- `opendev-core` crate写一次，编译六次，得到六个平台的二进制
- 不需要为每个平台重写核心逻辑，只写平台壳（Tauri/Android/iOS/WASM/Unity）
- `cargo build --target mips-unknown-linux-musl`一行命令得到路由器二进制

交叉编译工具链：

| 目标 | 安装方式 | 验证命令 |
|------|---------|---------|
| `x86_64-unknown-linux-musl` | `rustup target add` | 本地Docker验证 |
| `aarch64-linux-android` | NDK + `cargo-ndk` | Android模拟器 |
| `aarch64-apple-ios` | Xcode + `cargo-lipo` | iOS模拟器 |
| `mips-unknown-linux-musl` | `rustup target add` + 交叉链接器 | QEMU用户态 |
| `wasm32-unknown-unknown` | `rustup target add` + `wasm-pack` | 浏览器测试 |

### 9.2 Agent Action Protocol：HTTP+JSON通用协议

协议本身不需要为不同平台做适配——这正是它的设计优势。但需要在协议层增加：

- **能力声明**（`platform_capabilities`）：让设备自报家门
- **降级协商**：弱设备用轮询代替流式，用短连接代替长连接
- **两级发现**：直接发现+路由器缓存发现

这些扩展向后兼容——老Agent不声明`platform_capabilities`，调用方默认按`full`模式处理。

### 9.3 轻量客户端模式：不需要每台设备都跑完整服务

这是最重要的架构决策：**把"使用Agent"和"运行Agent服务"解耦。**

传统思维是"要用人家的服务就得装人家的软件"，但在Agent Action Protocol的世界里，你只需要能发HTTP请求。手机不需要跑OpenMind服务，只需要`POST /api/v1/search`。路由器不需要跑Qdrant，只需要`GET /s/{code}`然后302。

这意味着：
- 移动端App的复杂度大幅降低（纯客户端，没有后台服务）
- 路由器的资源消耗可控（只跑最轻量的逻辑）
- 生态扩展的边际成本趋近于零（新设备只需要一个HTTP客户端）

### 9.4 两级发现：agent.json去中心化 + 路由器缓存

agent.json的设计是去中心化的——每个Agent自己声明能力，不需要注册中心。但这在局域网场景下有个效率问题：每次都要去目标Agent拉agent.json。

路由器缓存解决了这个问题，同时保持了去中心化的精神：

- 缓存是**优化**，不是**依赖**。路由器挂了，设备仍然可以直接发现
- 缓存有TTL，定期刷新，不依赖手动维护
- 任何设备都能缓存，不一定要路由器（树莓派、NAS、甚至另一台电脑都行）

这种"去中心化+可选缓存"的模式，和DNS的设计思路一脉相承。

---

## 附录：平台扩展决策检查清单

当考虑新平台接入时，依次回答以下问题：

1. **资源够吗？** 内存/CPU/存储是否满足最小需求
2. **角色是什么？** `full` / `client` / `edge`，选错角色会浪费资源或能力不足
3. **能编译到吗？** Rust交叉编译目标是否存在、是否Tier 1/2/3
4. **网络可达吗？** 局域网还是公网，NAT后面还是直连，决定`network_scope`
5. **有用户需求吗？** 技术可行性不等于产品必要性
6. **维护成本可控吗？** 每多一个平台就多一份CI/测试/发布负担

六个问题都答清楚了，平台的接入方案自然浮现。
