# Web3 社交 App — 开发计划（方向 B）

> 状态：进行中  
> 栈：React + Vite + TypeScript + viem  
> 原则：引导自学；先闭环，后加功能

## 产品一句话

用户用 MetaMask 连接后，用钱包地址当身份，在前端发文字帖，时间线按时间倒序展示。

## MVP 范围

只做 3 件事：

1. 连接钱包
2. 发帖
3. 看 Feed

**刻意不做（延后）：** 关注、私信、NFT 头像、链上合约发帖、wagmi/RainbowKit、帖子签名验证（可放进阶关）。

---

## 第 0 关：信息架构与数据

### 页面

| 页面 | 作用 |
|------|------|
| Feed | 帖子时间线；未连接也可浏览（建议可读） |
| Compose | 发帖；未连接则禁用或引导去连接 |
| Profile | 当前地址 +「我的帖子」过滤 |
| Wallet 区 | 连接 / 断开 / 短地址展示（可放顶栏，不必单独路由） |

### 数据模型

**User（身份）**

- `address`：钱包地址（唯一 ID）
- `displayName`：可选；MVP 可用短地址 `0x1234…abcd`

**Post（帖子）**

- `id`
- `author`：地址
- `content`：字符串
- `createdAt`：时间戳
- `likes`：数字即可（先不做点赞人列表）

**App 状态**

- `account`：当前连接地址，或 `null`
- `posts`：帖子数组

---

## 建造顺序（关卡）

### 第 1 关：假数据 Feed + 顶栏钱包连接（当前任务）

目标：不用后端也能看到 Feed，并能连上 MetaMask。

步骤：

1. **清模板** — 去掉 Vite 欢迎页，`App` 改为顶栏 + 主内容区布局
2. **定义类型** — 例如 `types.ts`，写下 `Post`、当前账户相关类型
3. **假 Feed** — 2～3 条写死帖子；`PostCard` 显示短地址、内容、时间
4. **连接钱包（viem）**
   - 检测 `window.ethereum`，没有则提示安装 MetaMask
   - `createWalletClient` + `custom(window.ethereum)`
   - 在按钮点击里 `requestAddresses` / `getAddresses`（不要在组件顶层直接 `await`）
   - 地址写入 React state，顶栏显示短地址
5. **验收**
   - 未装钱包：有明确提示
   - 点 Connect：弹出 MetaMask，同意后顶栏显示地址
   - Feed 能看到假帖子
   - 刷新后连接状态可先丢失（下一关再处理）

本关不做：发帖持久化、账户切换监听、签名、后端。

### 第 2 关：发帖 Compose

- 仅当 `account` 存在时可提交
- 新帖 `author = account`，插入列表顶部
- 先存在内存；可选再加 `localStorage`

### 第 3 关：钱包体验打磨

- 短地址工具函数
- 断开连接
- 监听 `accountsChanged`（切换账户）

### 第 4 关：进阶 Web3 味（可选）

- 发帖前 `signMessage`，签名写入 Post，证明「该地址同意发过这句」

### 第 5 关：后端 / 多端同步（可选）

最小 API 形状：

- `GET /posts`
- `POST /posts`
- `POST /posts/:id/like`
- （可选）`GET /users/:id`

概念表：`User`、`Post`、`Like`。  
实现可选 Supabase / Firebase / 自建 Node+Postgres。

### 第 6 关：社交关系（有意延后）

关注、粉丝、@、私信、通知 — 等 Feed + 发帖 + 点赞稳定后再做。

---

## 技术备忘

- 已有依赖：`react`、`react-dom`、`viem`
- 连接逻辑可参考备份：`src/main.ts.bak`
- 路由（Feed / Compose / Profile）可在第 1 关末或第 2 关初引入 `react-router`
- 手写 viem 连通后再考虑 `wagmi` 等封装库

---

## 进度记录

| 日期 | 关卡 | 备注 |
|------|------|------|
| 2026-08-10 | 选定方向 B | 文档建立；下一目标：完成第 1 关 |

---

## 卡住时怎么提问

说明：卡在「类型 / UI / viem 连接 / 地址显示」哪一块，以及报错原文。优先要排查思路与下一步拆解，而不是直接要完整代码。
