# 第 0 关收尾：类型错误清单与代码复查记录

> 日期：2026-09-11
> 状态：**接近完成** —— `npx tsc --noEmit` 只剩 **3 个错误**，全在 `sign.ts`
> 目标：把所有编译错误清零，恢复「可 build、可验证」的状态，然后才能进第 4 关（发帖签名）

## 背景

第 0 关原本只是「清掉模板」这种小任务，但项目在完成第 1-3 关（含点赞、评论、图片上传、localStorage 持久化）后，`tsc` 累积了一批类型错误。

**为什么必须先清掉：** 第 4 关要验证签名的正确性，手段包括「刷新页面」「手动改 localStorage 再看验证结果」。这些都要求项目能正常 build、能稳定运行。带着一堆错误进第 4 关，会把「类型错误」和「签名逻辑错误」混在一起，排查成本翻倍。

## 现状快照

```
初始：13 个错误
中途：10 个错误
当前： 3 个错误   ← 全部在 src/sign.ts
```

**当前唯一阻塞 build 的就是 B5。**

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

### ✅ B3. `NewPost` 的 `currentAccount` —— 已完成，选了方案 (b)

`App.tsx:212` 的 `currentAccount={account}` 已删掉，那个「隐藏的第二个错误」也随之消失。

⚠️ **但方案 (b) 的代价仍然存在：**

`createPost` 在 `!account` 时是**静默 return**——未连接用户点 Post **完全没有反应，也没有任何提示**。文档第 2 关要求「未连接则禁用或引导去连接」，这个缺口**还没补**。

推荐的做法（将来补）：把 `currentAccount` 加回 `NewPost` 并用起来：

```
disabled={!currentAccount || (text.trim() === "" && images.length === 0)}
```

再加一句「请先连接钱包」的提示。

### ✅ B4. `mockPosts.ts` —— 已完成

3 条帖子都补了 `comments: []`，多余的 `Address` import 已删除。

### ⬜ B5. `sign.ts` 的 3 个未使用 import —— **唯一的阻塞项**

```
src/sign.ts(1,1): error TS6133: 'recoverMessageAddress' is declared but its value is never read.
src/sign.ts(2,23): error TS6196: 'Hex' is declared but never used.
src/sign.ts(3,1): error TS6133: 'isSameAddress' is declared but its value is never read.
```

这 3 个 import 是**第 4 关要用的料**（`recoverMessageAddress` 用于验证签名、`Hex` 用于 `signature` 类型、`isSameAddress` 用于比对地址）。`noUnusedLocals` 在这里其实在帮你：**它在提醒你「第 4 关还没写完」**。

**两条路，选一条：**

- **(i) 现在先删掉这 3 个 import（推荐）**
  理由是**绿色基线**原则：开始一个新功能之前，`tsc` 必须是 0。否则第 4 关写代码时报出的错误，你分不清是「新写的 bug」还是「早就存在的旧错误」。
  代价：第 4 关开始时再加回来，10 秒的事。
- **(ii) 不删，直接开始写 `signPost` / `verifyPost`**
  它们立刻就被用上，错误自然消失。但在此之前项目**无法 build**，中间状态没法验证。

> **不要为了让报错消失而写空函数占位**——那是把问题藏起来，不是解决。

---

## C. 次要问题（不阻塞编译，但记下来）

### C1. `NewPost` 的图片上传**缺少校验**

从 `Post` 删掉的那份 `handleImageUpload` 是**带类型检查 + 5MB 限制**的，而 `NewPost` 里那份（`Post.tsx` 约 168-183 行）**两者都没有**。

现在它是唯一的图片入口，意味着用户可以塞进任意大的文件 → base64 撑爆 localStorage。

**建议**：把 `Post` 里删掉的那段校验搬进 `NewPost`：

```ts
if (!file.type.startsWith("image/")) { alert("请选择图片文件"); return; }
if (file.size > 5 * 1024 * 1024) { alert("图片大小不能超过 5MB"); return; }
```

### C2. `localStorage` 配额风险

`App.tsx` 的 `localStorage.setItem`（在 `useEffect` 里）**没有 try/catch**：

```
QuotaExceededError → useEffect 抛异常 → 整棵组件树崩掉
```

图片走 `FileReader.readAsDataURL` 变成 base64，**体积膨胀约 33%**；一张 5MB 的图 ≈ 6.7MB 字符串，而 localStorage 每源配额通常只有 **5MB 左右**。

**建议**：写入包 `try/catch` 并给用户明确提示，或调小图片上限。**独立问题，单独修，别混进第 0 关。**

### C3. 代码格式（当前仍存在）

| 位置 | 问题 |
|------|------|
| `Post.tsx:31` | `setCommentText("");` 多缩进一级（8 空格，应为 6） |
| `Post.tsx:246` | `onClick={handleSubmit}` 少缩进一级（6 空格，应为 8） |
| `mockPosts.ts:10,11,18,19,26,27` | `likes: []` / `comments: []` 多缩进一级 |
| `App.tsx:212` | `<NewPost onSubmit={createPost}  />` 有多余空格 |

手改一下或跑 prettier。

### C4. 文档漂移（顺带发现）

`comment-feature-code.md` 里写的是 `createdAt`，但实际 `type.ts` 用的是 **`createAt`**（少了 `ed`）。文档和代码已经对不上了，建议统一命名。

### C5. `onKeyPress` 已废弃

`Post.tsx` 评论输入框用的是 `onKeyPress`，React 已标记废弃，建议换成 `onKeyDown`。

---

## D. 完成判据

```bash
cd my-viem-app
npx tsc --noEmit      # 期望：0 错误（当前 3）
npm run build         # 期望：成功
npm run dev           # 期望：页面正常
```

手工验证：

1. 未连接 → 评论区没有输入框；Post 按钮表现见 B3（目前是「静默无反应」）
2. 连接后 → 发纯文字评论 ✅
3. 点**两条不同**的帖子各发一条评论 → 各自挂对 ✅（验证 `post.id` 闭包绑定，只测一条查不出绑错）
4. 刷新页面 → 评论还在 ✅
5. `NewPost` 发帖 + 上传图片 → 依然正常 ✅

---

## E. 第 4 关（发帖签名）启动条件

**前置**：B5 清零、`tsc` 归零（绿色基线）。

**第 1 步是「定数据形态」，先别写签名代码：**

1. `type.ts` 的 `Post` 加 `signature?: Hex`（**可选**——因为 `mockPosts` 和 localStorage 里的老帖子都没有），从 viem 引入 `Hex` 类型
2. ✅ A2 已定：签名覆盖 `images`，但**签的是每张图的哈希，不是 base64 原文**（见 A2）
3. 想清楚**老帖子和 mockPosts 怎么显示**：没有 `signature` 时不能报错，要显示「未签名」
4. `buildPostMessage` 是**唯一**的待签名文本构造入口——签名侧和验证侧都必须调它。任何一侧自己拼字符串，都会因为差一个字符而验签失败

**关键坑（提前记下）：**

- `walletClient` 目前在 `connectWallet()` 里创建完就丢掉了，签名需要它——要想清楚放哪里（抽 `getWalletClient()` 辅助函数，还是存进 `useRef`？）
- `signMessage` 是异步的，`createPost` 会变成 async，需要 loading / 禁用态，否则会连点发重复帖
- 用户**拒绝签名**时要 catch，并且**不能**创建帖子
- 签名时和验证时拼出的那段文本必须**逐字一致**
- **哈希的输入必须是「最终存下来的那个字符串」**。签名时 hash 的是 `FileReader` 刚读出的 data URL，验证时 hash 的是 localStorage 读回来的——只要中间没再做 `.trim()` 或重新编码 base64，就是同一串。**一旦某一侧重新编码，合法帖子也会验签失败**（最阴的坑：假阴性，签名明明对却报错）
- 验证是**异步**的（`recoverMessageAddress` 返回 Promise），所以 `Post.tsx` 需要 `useState` + `useEffect`
- **别在 render 里算哈希**——几 MB 的图每次 render 都重算会卡死。验证只在挂载 / 帖子变化时跑一次

**验收标准（最有说服力的一条）：** DevTools → Application → localStorage → 手动改掉某条帖子的 `content` → 刷新 → 徽章应变成红色警告。这一步能证明验证是真在跑，不是摆设。
