# Next Steps for Web3 Social App

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
