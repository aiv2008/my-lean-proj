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

**刻意不做（延后）：** 关注、私信、NFT 头像、链上合约发帖、wagmi/RainbowKit、**服务端**签名验证。

> ✅ 2026-09-16 更新：「帖子签名验证」原本在延后清单里，现已作为**第 4 关**完成（前端验签，见 [step0-review.md](./step0-review.md) E 节）。
> 但**必须说清楚它的能力边界**：前端验签只能证明「这份内容与这个签名是配套的」，
> **不能**证明「作者真的发过」——因为改数据的人顺手换一个自己签的签名，前端照样显示「签名有效」。
> 真正的认证要在第 5 关由服务端验签才算数。别把它当成防伪，它是**防篡改检测**。

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

### 第 1 关：假数据 Feed + 顶栏钱包连接（✅ 已完成）

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

### 第 4 关：进阶 Web3 味（✅ 已完成，2026-09-16）

- 发帖前 `signMessage`，签名写入 Post，证明「该地址同意发过这句」 → ✅ `src/sign.ts` 的 `signPost`
- 验证侧 `verifyPost` 用 `recoverMessageAddress` 反推地址，和 `post.author` 比对 → ✅ `Post.tsx` 的 `SignatureBadge`
- 签名覆盖 `images`（签每张图的 `keccak256` 哈希，不签 base64 原文）→ ✅

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

- 已有依赖：`react`、`react-dom`、`viem`（+ `vite`、`tailwindcss`、`typescript`）
- 连接逻辑可参考备份：`src/main.ts.bak` —— ⚠️ **该文件已不存在**，实际参考 `src/App.tsx` 的 `getWalletClient()` / `connectWallet()`
- 路由（Feed / Compose / Profile）可在第 1 关末或第 2 关初引入 `react-router` —— 目前**未引入**，仍是单页
- 手写 viem 连通后再考虑 `wagmi` 等封装库 —— 目前仍是手写 viem（符合原则）
- 签名相关的唯一入口是 `src/sign.ts` 的 `buildPostMessage`：**签名侧和验证侧都必须调它**，任何一侧自己拼字符串都会验签失败
- `window.ethereum` 的类型**已经声明好**（`src/vite-env.d.ts` 里 `Window.ethereum?: EIP1193Provider`，用的是 viem 自带的类型）——这一项原本记在「待改进」里，其实已经做完了

---

## 进度记录

| 日期 | 关卡 | 备注 |
|------|------|------|
| 2026-08-10 | 选定方向 B | 文档建立；下一目标：完成第 1 关 |
| 2026-09-08 | 第 1-3 关完成 | ✅ Feed + 钱包连接<br>✅ 发帖功能<br>✅ 钱包体验打磨<br>✅ 额外完成：点赞、评论、图片上传、localStorage 持久化 |
| 2026-09-08 | 准备第 4 关 | 下一目标：发帖签名验证（signMessage） |
| 2026-09-11 | 第 0 关收尾（接近完成） | 代码复查：`tsc` 13 → 10 → **3 错误**<br>✅ 修完：`Post` 的死 prop / 死 state、`NewPost.onSubmit` 的 `images` 类型、`mockPosts` 缺字段<br>⬜ 仅剩：`sign.ts` 的 3 个未使用 import（`tsc` 未清零，**尚不能 build**）<br>📋 清单见 **[step0-review.md](./step0-review.md)** |
| 2026-09-11 | 第 4 关设计定案 | ✅ `Post` 的 `onSubmit` 确认为**有意删除**（评论走 `onAddComment`，发帖+图片走 `NewPost.onSubmit`）<br>✅ 签名**必须覆盖 `images`** —— 别人换图必须验签失败<br>　 → 实现上**签每张图的 `keccak256` 哈希，不签 base64 原文**（否则 MetaMask 弹窗几 MB 乱码，用户无法审阅）<br>下一步：`type.ts` 加 `signature?: Hex` + 扩展 `buildPostMessage` |
| 2026-09-16 | 第 0 关收尾**完成** + 第 4 关签名闭环 | ✅ `tsc --noEmit` **0 错误**（`sign.ts` 3 个 import 已用上，`isSubmittingg` 笔误已修）<br>✅ `npm run build` 成功<br>✅ `sign.ts`：`SignablePost` / `signPost` / `verifyPost`（含 `broken`、`unsigned` 分支）<br>✅ `Post.tsx`：签名徽章（✅ 有效 / ⚠️ 不符 / ⚠️ 损坏 / 未签名），`useEffect` 异步验证 + 卸载时丢弃迟到结果<br>✅ 补 B3 缺口：未连接 → Post 按钮禁用 + 「请先连接钱包再发帖」提示<br>✅ 补 C1：图片类型 + 5MB 校验（并清空 input，支持重选同一文件）<br>✅ 补 C2：`localStorage.setItem` 包 try/catch<br>📋 下一步：浏览器手工验收（见下方清单） |
| 2026-09-17 | 对照本文档逐关核验 | ✅ 第 1-4 关代码侧全部核对通过（见「逐关验收对照」）<br>✅ dev server 实测可跑：http://localhost:5173/ 返回 200<br>⚠️ 发现 3 处文档/实现偏差并已记录：`likes` 实现为地址数组（超出计划、属升级）、`User` 类型目前是死代码、Profile 页未做<br>⚠️ 澄清第 4 关能力边界：前端验签是**防篡改检测**，不是身份认证（换签名者自己签的照样"有效"）→ 真正的认证属第 5 关服务端<br>⬜ 仍待浏览器手工验收（6 项，见「当前任务」）<br>➡️ 下一个开发目标：**第 5 关：后端 / 多端同步** |

---

## 逐关验收对照（2026-09-16 核对）

对照上面各关的「步骤 / 验收」逐条核对**代码实现**的结果。`✅ 代码核对` 指读代码能确认；
`⬜ 待浏览器` 指必须你亲手在 MetaMask 里点一遍才算数——我没有浏览器和钱包，替你签不了。

### 第 1 关：Feed + 钱包连接

| 验收项 | 状态 | 证据 |
|--------|------|------|
| 没有 `window.ethereum` 时给明确提示 | ✅ 代码核对 | `App.tsx` `connectWallet()` → `alert("Please install MetaMask!")` |
| 点 Connect 弹出 MetaMask | ⬜ 待浏览器 | `createWalletClient({ transport: custom(window.ethereum) })` + `requestAddresses()` |
| 同意后顶栏显示地址 | ⬜ 待浏览器 | `shortAddress(account)` 已渲染 |
| Feed 能看到假帖子 | ✅ 代码核对 | `mockPosts` 3 条，`Post` 组件渲染 |
| 未连接也能浏览 Feed | ✅ 代码核对 | Feed 不依赖 `account`；仅点赞/评论/发帖受限制 |

### 第 2 关：发帖 Compose

| 验收项 | 状态 | 证据 |
|--------|------|------|
| 仅当 `account` 存在时可提交 | ✅ 已补 | `disabled={!currentAccount \|\| …}` + 「请先连接钱包再发帖」+ `createPost` 里的 `if (!account) return false` |
| 新帖 `author = account` | ✅ 代码核对 | `createPost` 里 `author: account` |
| 插到列表顶部 | ✅ 代码核对 | `setPosts([新帖, ...posts])` |
| （可选）localStorage 持久化 | ✅ 代码核对 | `useEffect` 写入 + 初始化时读取，含 `QuotaExceededError` 兜底 |

### 第 3 关：钱包体验打磨

| 验收项 | 状态 | 证据 |
|--------|------|------|
| 短地址工具函数 | ✅ 代码核对 | `src/address.ts` `shortAddress()` |
| 断开连接 | ✅ 代码核对 | `disconnectWallet()` → `setAccount(null)` |
| 监听 `accountsChanged` | ✅ 代码核对 | `useEffect` 注册 + **cleanup 里 `removeListener`**（防内存泄漏） |
| 切换账户后 UI 跟着变 | ⬜ 待浏览器 | 依赖 MetaMask 主动发事件 |

### 第 4 关：签名验证

见 [step0-review.md](./step0-review.md) E 节的**离线实测表**（9 个用例全部通过，含改内容/换图/改时间/图片重排）。
剩下只有一条要你确认：MetaMask 弹窗里的文本**可读**，不是 base64 乱码。

### 第 0 关：信息架构与数据（对照数据模型）

| 文档要求 | 实现 | 备注 |
|----------|------|------|
| `Post.id / author / content / createdAt / likes` | ✅ | 多了 `comments`、`images`、`signature`（第 4 关） |
| `Post.likes`「数字即可（先不做点赞人列表）」 | ⚠️ 超出计划 | 实际存的是**地址数组** `Address[]` —— 这是升级不是偏差：能判断「我点过没有」，也能防重复点赞 |
| `User.address / displayName` | ⚠️ 未用 | `type.ts` 里定义了 `User`，但 MVP 用 `shortAddress()` 代替，`User` 目前是死类型 |
| `App 状态：account / posts` | ✅ | 一致 |
| 页面：Feed / Compose / Profile / Wallet | ⚠️ 部分 | Feed ✅、Compose ✅（内嵌在 Feed 下方）、Wallet ✅（顶栏）；**Profile 未做**，`react-router` 也未引入 |

> `import type { User }` 从未被引用 = 死代码。要么用起来（Profile 关），要么删掉。**先记着，别现在动。**

---

## 当前任务

**第 4 关浏览器手工验收** —— 自动化能验的已经验完，剩下必须在真实 MetaMask 里走一遍。

已验证（用本地私钥账户离线跑过，逻辑正确性已确认）：

- 正常帖子 → `valid`
- 改 `content` / 换图 / 改时间 / 图片顺序调换 → 全部 `invalid`
- 无签名的老帖子 → `unsigned`（不报错）
- 签名残缺（`0xdeadbeef`）→ `broken`（不抛异常）
- `createdAt` 经过 localStorage JSON 往返后仍能验通过

待你在浏览器里确认（`npm run dev`，实测 dev server 已在 http://localhost:5173/ 正常响应）：

1. 未连接 → Post 按钮禁用，显示「请先连接钱包再发帖」
2. 连接后发帖 → MetaMask 弹出可读文本（**不是** base64 乱码），签名后帖子出现在顶部
3. 刷新页面 → 帖子还在，徽章仍是「✅ 签名有效」
4. **关键验收**：DevTools → Application → localStorage → 手动改掉某条帖子的 `content` → 刷新 → 徽章变红「⚠️ 签名不符」
5. 发帖时点「拒绝签名」→ 弹「你取消了签名，帖子没有发布」，且帖子**没有**入库
6. 上传 >5MB 的图 → 提示「超过 5MB，已跳过」

## 后续可选（不阻塞）

- **第 5 关：后端 / 多端同步**（`GET /posts`、`POST /posts`…）—— 到了服务端，验签才真正有分量：
  服务端持有公钥/地址，篡改者换不掉；前端自证只是体验。这是**最有价值的下一步**。
- Profile 页 + `react-router`（顺带把死类型 `User` 用起来或删掉）
- 评论也可以签名（目前只有帖子有签名）
- 图片仍走 base64 + localStorage，配额是硬上限（5MB 左右）；真要发布式图片得换对象存储
- `buildPostMessage` 是 v1 格式，将来改字段记得升版本号，否则老帖子会集体验签失败
- `window.ethereum` 缺类型定义（依赖 `vite-env.d.ts` 之外的隐式 any 声明）——见本关「技术备忘」



---

## 卡住时怎么提问

说明：卡在「类型 / UI / viem 连接 / 地址显示」哪一块，以及报错原文。优先要排查思路与下一步拆解，而不是直接要完整代码。
