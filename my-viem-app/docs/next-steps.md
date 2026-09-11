
# Next Steps for Web3 Social App

## 🚧 Blocking: finish Step 0 (type errors) first

`npx tsc --noEmit` reports **3 errors**, all in `src/sign.ts` (unused imports `recoverMessageAddress`, `Hex`, `isSameAddress`) — the project cannot build until they are resolved.

Progress: 13 → 10 → **3** errors.

1. ✅ Delete leftover `images` / `setImages` state in `Post.tsx`
2. ✅ Unify `NewPost.onSubmit` to `images?: string[]` (note: declared optional, not required — see review doc)
3. ✅ `currentAccount` on `NewPost` — option (b) chosen: attribute dropped from `App.tsx`. **Side effect still open:** unconnected users clicking "Post" get no feedback at all
4. ✅ `mockPosts.ts` — `comments: []` added, unused `Address` import dropped
5. ⬜ `sign.ts` — drop the 3 unused imports (or write `signPost` / `verifyPost` now, which uses them)

Also open: is the removal of `Post`'s `onSubmit` intentional? And should post signatures cover `images`?

📋 Full checklist with reasons: **[step0-review.md](./step0-review.md)**

## Testing & Verification

1. **Run the app** - Test the wallet connection and account switching functionality to verify the fix works
2. **Test the posting feature** - Make sure creating posts works correctly

## Feature Enhancements

3. **Add delete post functionality** - Allow users to delete their own posts
4. **Add like/reaction system** - Let users react to posts
5. **Add comments** - Allow users to comment on posts
6. **Add user profiles** - Show more info about post authors
7. **Add post editing** - Let users edit their posts

## Code Improvements

8. **Add error handling** - Better error messages for wallet connection failures
9. **Add loading states** - Show spinners during wallet connection
10. **Add timestamp formatting** - Display "2 hours ago" instead of raw dates
11. **Add empty state** - Show a message when there are no posts

## Technical Improvements

12. **Add tests** - Write unit tests for the app
13. **Improve TypeScript types** - Add better type definitions for window.ethereum
14. **Add disconnect wallet button** - Allow users to disconnect

## Recent Fixes

### Account Change Listener Fix (2026-08-21)

Fixed the `useEffect` hook that listens for MetaMask account changes:

- **Type error fixed**: Changed `accounts: string` to `accounts: string[]` (line 34 of `App.tsx`)
- **Cleanup function added**: Properly removes event listener on component unmount
- **Dependency array added**: Effect now only runs once on mount instead of on every render

The fix prevents memory leaks and ensures proper event listener cleanup.
