
# Next Steps for Web3 Social App

## ✅ Step 0 done, Step 4 (post signing) closed loop (2026-09-16)

`npx tsc --noEmit` → **0 errors**; `npm run build` → **success**.

1. ✅ Delete leftover `images` / `setImages` state in `Post.tsx`
2. ✅ Unify `NewPost.onSubmit` to `images?: string[]`
3. ✅ `currentAccount` on `NewPost` — re-added and actually used: Post button is disabled while disconnected, with a "请先连接钱包再发帖" hint
4. ✅ `mockPosts.ts` — `comments: []` added, unused `Address` import dropped
5. ✅ `sign.ts` — chose route (ii): wrote `signPost` / `verifyPost`, so the 3 imports are used for real
6. ✅ `Post.tsx` — fixed the `isSubmittingg` typo; button now shows "等待签名…" and is disabled while signing
7. ✅ Signature badge in `Post.tsx` (✅ valid / ⚠️ mismatch / ⚠️ broken / 未签名)
8. ✅ Image upload validation (type + 5MB) and try/catch around `localStorage.setItem`

📋 Full checklist with reasons: **[step0-review.md](./step0-review.md)**
📋 Current task + manual acceptance list: **[web3-social-mvp.md](./web3-social-mvp.md)**

## Testing & Verification

1. **Browser walkthrough** — run `npm run dev` and follow the 6-item acceptance list in `web3-social-mvp.md`
2. **Tamper test (the convincing one)** — edit a post's `content` in localStorage, refresh, badge must turn red

## Feature Enhancements

3. **Sign comments too** — right now only posts carry a signature
4. **Add like/reaction polish** — likes are not signed, so they stay locally trusted (fine for MVP)
5. **Add user profiles** - Show more info about post authors
6. **Add post editing** - Let users edit their posts (note: editing requires re-signing)

## Code Improvements

7. **Add error handling** - Better error messages for wallet connection failures
8. **Add loading states** - Show spinners during wallet connection
9. **Add timestamp formatting** - Display "2 hours ago" instead of raw dates
10. **Add empty state** - Show a message when there are no posts

## Technical Improvements

11. **Add tests** - Write unit tests for the app (the sign/verify cases checked manually are a good starting suite)
12. **`window.ethereum` types** - ✅ already done (`src/vite-env.d.ts` declares `Window.ethereum?: EIP1193Provider`)
13. **Migrate off base64-in-localStorage** — quota is the hard ceiling; real image hosting is the fix
14. **Delete or use the `User` type** — declared in `type.ts` but never referenced (dead code)

## Where to go next

`docs/web3-social-mvp.md` now has a per-level acceptance table plus the honest limits of client-side
signature verification. The highest-value next step is **Level 5: backend / multi-device sync** —
server-side verification is the first place a signature actually proves something.

## Recent Fixes

### Account Change Listener Fix (2026-08-21)

Fixed the `useEffect` hook that listens for MetaMask account changes:

- **Type error fixed**: Changed `accounts: string` to `accounts: string[]` (line 34 of `App.tsx`)
- **Cleanup function added**: Properly removes event listener on component unmount
- **Dependency array added**: Effect now only runs once on mount instead of on every render

The fix prevents memory leaks and ensures proper event listener cleanup.
