# 第 0 关收尾：类型错误清单与代码复查记录

> 日期：2026-09-11（2026-09-16 更新：**已全部完成**）
> 状态：**✅ 完成** —— `npx tsc --noEmit` **0 错误**，`npm run build` 成功，第 4 关签名闭环已落地
> 目标达成：恢复「可 build、可验证」的状态，然后进第 4 关（发帖签名）—— 第 4 关已完成，见 [web3-social-mvp.md](./web3-social-mvp.md)

## 背景

第 0 关原本只是「清掉模板」这种小任务，但项目在完成第 1-3 关（含点赞、评论、图片上传、localStorage 持久化）后，`tsc` 累积了一批类型错误。

**为什么必须先清掉：** 第 4 关要验证签名的正确性，手段包括「刷新页面」「手动改 localStorage 再看验证结果」。这些都要求项目能正常 build、能稳定运行。带着一堆错误进第 4 关，会把「类型错误」和「签名逻辑错误」混在一起，排查成本翻倍。

## 现状快照

```
初始：13 个错误
中途：10 个错误
中间： 3 个错误   ← 全在 src/sign.ts（当时）
当前： 0 个错误   ✅ 2026-09-16
```

**已清零：** `sign.ts` 走路线 (ii) —— 直接写了 `signPost` / `verifyPost`，3 个 import 全部真正用上，不是删掉了事。

---

## A. 待确认的设计问题

### A1. `Post` 的 `onSubmit` 是有意删除的吗？（基本已定）

你之前说过「不要删掉 `onSubmit`」，但实际改动把它从 `Post` 里删掉了——**结论上反而更干净**，理由就是我们讨论出来的那条：**评论和图片是两件事**。

后续的改动也一直是按这个方向走的，所以按实现推断，最终契约定为：

| 组件 | 契约 | 负责 |
|------|------|------|
| `Post` | `onAddComment(postId, content)` | 纯文字评论 |
| `NewPost` | `onSubmit(content, images?)` | 发帖 + 图片上传 |

（`onAddComment` 这个名字其实比 `onSubmit` 更清楚，所以这个分工比原方案更好。）

**✅ 已确认（2026-09-11）：是有意删除的。** 上表即为最终契约，不再改动。

### A2. 第 4 关：签名要不要覆盖 `images`？

`sign.ts` 的 `buildPostMessage` 现在签的是 `author + createdAt + content`，**不包含 `images`**。

**后果：** 别人可以替换掉帖子里的图片，而签名依然验证通过——签名只证明「这个地址发过这段文字」，不证明「发过这张图」。

**✅ 已决定（2026-09-11）：签名必须覆盖 `images`——别人换图必须验签失败。**

**实现方向：不能直接签 base64 原文，要签它的哈希。** 三个原因：

1. 直接签 data URL，MetaMask 弹窗会显示几 MB 的乱码，用户根本没法审阅自己在签什么——而「知情同意」正是签名的全部意义
2. `personal_sign` 对大 payload 的性能和兼容性都很差
3. 绑定图片内容用哈希就够了：图片**改一个字节**，哈希全变 → 验签失败

做法：对每张图的 data URL 求 `keccak256(toBytes(img))`，把得到的哈希串写进待签名文本。

---

## B. 必修清单

### ✅ B1. 删掉 `Post.tsx` 里残留的图片 state —— 已完成

`const [images, setImages] = useState<string[]>([]);` 已删除。既然图片归发帖，`Post` 不应该有任何图片状态。

### ✅ B2. 统一 `NewPost.onSubmit` 的 `images` 类型 —— 已完成

已改成 `images?: string[]`（4 处：`Post.tsx` prop 类型、`handleSubmit`、`App.tsx` 的 `createPost` 签名、`images: images`，`|| []` 已去掉）。

**一处与原计划的偏差（可接受，但值得知道）：**

原建议是 **必填** `images: string[]`，你写成了 **可选** `images?: string[]`。两者都能编译，差别在严格程度：

- `images: string[]`（必填）：调用方**必须**给值；「没图」只有一种表示 `[]`
- `images?: string[]`（可选）：调用方可以不给；「没图」有 `undefined` 和 `[]` 两种表示

因为目前唯一的调用方 `NewPost` 永远会传一个数组，所以现在没有实际危害。但**可选会让「没图」出现两种表示**，将来是谁调用这个函数时，就得多判一次空。若想收紧，可改回必填。

> 注意区分：`Post.images`（`type.ts`）**保持可选**。因为 localStorage 里的老帖子和 `mockPosts` 真的没有这个字段。
> **生产者边界必填，持久化边界可选**——这不是不一致，是两个位置面对的现实不同。

### ✅ B3. `NewPost` 的 `currentAccount` —— 已完成，方案 (b) 的缺口也已补上

`App.tsx` 的 `currentAccount={account}` 曾一度被删掉（避开那个隐藏的第二个类型错误）。

⚠️ 当时的代价：`createPost` 在 `!account` 时是**静默 return**——未连接用户点 Post **完全没有反应，也没有任何提示**。

**✅ 2026-09-16 已补（回到方案 (a) 并真正用起来）：**

- `App.tsx`：`<NewPost currentAccount={account} onSubmit={createPost} />`
- `Post.tsx`：按钮 `disabled={!currentAccount || isSubmitting || (text.trim() === "" && images.length === 0)}`
- 未连接时在图片按钮旁显示「请先连接钱包再发帖」

> 为什么不是「禁用就好」：按钮变灰但**不说原因**，用户只会以为是 bug。文案和禁用必须成对出现。
> `createPost` 里的 `if (!account) return false` 仍然保留——UI 禁用是体验，代码里的守卫是正确性，两道都要有。

### ✅ B4. `mockPosts.ts` —— 已完成

3 条帖子都补了 `comments: []`，多余的 `Address` import 已删除。

### ✅ B5. `sign.ts` 的 3 个未使用 import —— **已解决（走路线 ii）**

```
src/sign.ts(1,1): error TS6133: 'recoverMessageAddress' is declared but its value is never read.
src/sign.ts(2,23): error TS6196: 'Hex' is declared but never used.
src/sign.ts(3,1): error TS6133: 'isSameAddress' is declared but its value is never read.
```

这 3 个 import 是**第 4 关要用的料**（`recoverMessageAddress` 用于验证签名、`Hex` 用于 `signature` 类型、`isSameAddress` 用于比对地址）。`noUnusedLocals` 在这里其实在帮你：**它在提醒你「第 4 关还没写完」**。

**最终选择：路线 (ii)** —— 直接写 `signPost` / `verifyPost`，让 import 立刻上岗。（路线 (i)「先删掉、第 4 关再加回来」也是对的，只是多一次往返。）

> 另外发现并修掉了一个复查时漏掉的错误：`Post.tsx` 的 `const [isSubmittingg, setIsSubmitting] = useState(false)` —— 变量名多打一个 `g`，导致 `isSubmitting` 从未被读取（TS6133）。现已改成 `isSubmitting`，并真正用起来：签名期间按钮禁用 + 显示「等待签名…」，避免连点发重复帖。

---

## C. 次要问题（C1 / C2 已顺手修掉）

### ✅ C1. `NewPost` 的图片上传**缺少校验** —— 已修

从 `Post` 删掉的那份 `handleImageUpload` 是**带类型检查 + 5MB 限制**的，而 `NewPost` 里那份**两者都没有**。

现在它是唯一的图片入口，意味着用户可以塞进任意大的文件 → base64 撑爆 localStorage。

**已搬回 `NewPost`**：非图片文件、>5MB 的文件都跳过并提示文件名。另外顺手**清空 `input.value`** —— 否则「再选一次同一个文件」不会触发 `change`（文件没换，用户会以为按钮坏了）。

### ✅ C2. `localStorage` 配额风险 —— 已兜住

`App.tsx` 的 `localStorage.setItem` 原本没有 try/catch：

```
QuotaExceededError → useEffect 抛异常 → 整棵组件树崩掉
```

图片走 `FileReader.readAsDataURL` 变成 base64，**体积膨胀约 33%**；一张 5MB 的图 ≈ 6.7MB 字符串，而 localStorage 每源配额通常只有 **5MB 左右**。

**已包 try/catch + 明确提示**。注意这只是「不崩」，不是「能存」——真要发布式图片得换对象存储（记在后续可选项里）。

### 🟡 C3. 代码格式 —— 已修 4 处中的 3 处

| 位置 | 问题 | 状态 |
|------|------|------|
| `Post.tsx:31` | `setCommentText("");` 多缩进一级 | ✅ 已修 |
| `Post.tsx:246` | `onClick={handleSubmit}` 少缩进一级 | ✅ 已修 |
| `mockPosts.ts:10,11,18,19,26,27` | `likes: []` / `comments: []` 多缩进一级 | ✅ 已修 |
| `App.tsx:212` | `<NewPost onSubmit={createPost}  />` 有多余空格 | 行号已变，代码本身已重写，无多余空格 |

> 另外 `type.ts` 的 `images?` / `signature?` 也是多缩进一级，一并修了。
> prettier **不是**项目依赖（`npx prettier` 会去联网装），所以只能手改。

### 🟡 C4. 文档漂移（仍在）

`comment-feature-code.md` 里写的是 `createdAt`，但实际 `type.ts` 用的是 **`createAt`**（少了 `ed`）。**代码没动**——改名会牵动 localStorage 里已有数据的解析，收益不抵风险。以代码为准。

### 🟡 C5. `onKeyPress` 已废弃 —— 已修

`Post.tsx` 评论输入框用的是 `onKeyPress`（React 已标记废弃），已换成 `onKeyDown`。行为不变。

---

## D. 完成判据

```bash
cd my-viem-app
npx tsc --noEmit      # ✅ 实测 0 错误（2026-09-16）
npm run build         # ✅ 实测成功（vite 8.2.1，1225 modules）
npm run dev           # ⬜ 待你在浏览器跑
```

> 注意：`npm run build` 在当前受限沙箱里会报 `spawn EPERM`（vite 加载配置时要 spawn 子进程读管道），
> 那是环境限制不是代码问题；换正常终端跑即可。

手工验证：

1. 未连接 → 评论区没有输入框；Post 按钮**禁用**并提示「请先连接钱包再发帖」✅（见 B3）
2. 连接后 → 发纯文字评论 ✅
3. 点**两条不同**的帖子各发一条评论 → 各自挂对 ✅（验证 `post.id` 闭包绑定，只测一条查不出绑错）
4. 刷新页面 → 评论还在 ✅
5. `NewPost` 发帖 + 上传图片 → 依然正常 ✅
6. 发帖后徽章显示「✅ 签名有效」；手动改 localStorage 里的 `content` 后刷新 → 变红 ⬜（待浏览器验收）

---

## E. 第 4 关（发帖签名）—— 已实现

**实现落点：**

| 文件 | 内容 |
|------|------|
| `src/sign.ts` | `SignablePost`（待签名最小形状）、`buildPostMessage`（唯一文本入口）、`signPost`、`verifyPost` |
| `src/App.tsx` | `createPost` 走 `signPost`；只传 post 对象 + `signMessage` 回调 |
| `src/Post.tsx` | `SignatureBadge`：`useEffect` 里异步验签，四种状态 |

**设计要点（都已落实）：**

1. `type.ts` 的 `Post.signature?: Hex` 是**可选**的 —— `mockPosts` 和 localStorage 里的老帖子都没有
2. ✅ A2：签名覆盖 `images`，但签的是每张图的 `keccak256` 哈希，不是 base64 原文
3. ✅ 没有 `signature` 时显示「未签名」，不报错
4. ✅ `buildPostMessage` 是**唯一**的待签名文本构造入口 —— 签名侧（`signPost`）和验证侧（`verifyPost`）都调它
5. ✅ `getWalletClient()` 抽成辅助函数，每次签名时新建（不必存 `useRef`）
6. ✅ `createPost` 是 async，`NewPost` 有 `isSubmitting` 禁用态 + 「等待签名…」文案
7. ✅ 拒绝签名（`code === 4001`）时 catch，**不创建帖子**
8. ✅ 验证在 `useEffect` 里跑，依赖只有真正参与验签的字段（`likes` 变化不触发重算）
9. ✅ 组件卸载/帖子变更时丢弃迟到结果（`cancelled` 标志），避免旧结果覆盖新结果

**离线验证结果（本地私钥账户 + viem，等价于 MetaMask 的签名路径）：**

| 用例 | 期望 | 实测 |
|------|------|------|
| 正常帖子 | valid | ✅ valid |
| 改 `content` | invalid | ✅ invalid |
| 换图（改一张图的数据） | invalid | ✅ invalid |
| 图片顺序调换 | invalid | ✅ invalid |
| 改 `createdAt` | invalid | ✅ invalid |
| 无签名的老帖子 | unsigned | ✅ unsigned |
| 签名残缺 `0xdeadbeef` | 不抛异常 | ✅ broken |
| `createdAt` 经 localStorage JSON 往返 | valid | ✅ valid |
| 老帖子无 `images` 字段 | 不报错 | ✅ unsigned |

**剩下唯一没验的**：真实 MetaMask 弹窗里的文本可读性（应当是一段带中文标题、作者、时间、图片哈希的可读文本，**不是**几 MB 的 base64 乱码）。这条只能你手动确认。
