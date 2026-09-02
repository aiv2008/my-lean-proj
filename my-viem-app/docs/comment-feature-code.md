# 评论功能实现代码

## 1. 更新 src/type.ts

```typescript
import type { Address } from "viem";

export type Comment = {
  id: string;
  author: Address;
  content: string;
  createdAt: Date;
};

export type Post = {
  id: string;
  author: Address;
  content: string;
  createdAt: Date;
  likes: Address[];
  comments: Comment[];
};

export type User = {
  address: Address;
  displayName?: string;
};
```

---

## 2. 更新 src/App.tsx

### 2.1 在文件顶部添加 Comment 类型导入

```typescript
import type { Post as PostData, Comment } from "./type";
```

### 2.2 在 createPost 函数中添加 comments 字段

找到这段代码：
```typescript
const newPost: PostData = {
  id: crypto.randomUUID(),
  content,
  createdAt: new Date(),
  author: account,
  likes: [],
};
```

改为：
```typescript
const newPost: PostData = {
  id: crypto.randomUUID(),
  content,
  createdAt: new Date(),
  author: account,
  likes: [],
  comments: [],
};
```

### 2.3 在 toggleLike 函数之后添加评论相关函数

```typescript
/**
 * 添加评论
 */
function addComment(postId: string, content: string) {
  if (!account) {
    return;
  }

  setPosts(
    posts.map((post) => {
      if (post.id !== postId) {
        return post;
      }

      const newComment: Comment = {
        id: crypto.randomUUID(),
        author: account,
        content,
        createdAt: new Date(),
      };

      return {
        ...post,
        comments: [...post.comments, newComment],
      };
    }),
  );
}

/**
 * 删除评论
 */
function deleteComment(postId: string, commentId: string) {
  setPosts(
    posts.map((post) => {
      if (post.id !== postId) {
        return post;
      }

      return {
        ...post,
        comments: post.comments.filter((c) => c.id !== commentId),
      };
    }),
  );
}
```

### 2.4 更新 Post 组件调用

找到这段代码：
```typescript
<Post
  key={post.id}
  post={post}
  currentAccount={account}
  onDelete={deletePost}
  onLike={toggleLike} // NEW: Connected like functionality
/>
```

改为：
```typescript
<Post
  key={post.id}
  post={post}
  currentAccount={account}
  onDelete={deletePost}
  onLike={toggleLike}
  onAddComment={addComment}
  onDeleteComment={deleteComment}
/>
```

---

## 3. 完整替换 src/Post.tsx

```typescript
import { useState } from "react";
import { shortAddress, isSameAddress } from "./address";
import type { Post as PostData, Comment } from "./type";
import type { Address } from "viem";

export default function Post({
  post,
  currentAccount,
  onDelete,
  onLike,
  onAddComment,
  onDeleteComment,
}: {
  post: PostData;
  currentAccount: Address | null;
  onDelete?: (id: string) => void;
  onLike?: (id: string) => void;
  onAddComment?: (postId: string, content: string) => void;
  onDeleteComment?: (postId: string, commentId: string) => void;
}) {
  const [commentText, setCommentText] = useState("");
  const [showComments, setShowComments] = useState(false);
  
  const canDelete = !!onDelete && isSameAddress(post.author, currentAccount);
  const hasLiked = currentAccount
    ? post.likes?.some((addr) => isSameAddress(addr, currentAccount))
    : false;

  const handleAddComment = () => {
    if (commentText.trim() && onAddComment) {
      onAddComment(post.id, commentText.trim());
      setCommentText("");
    }
  };

  return (
    <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <header className="mb-2 flex items-center justify-between gap-3 text-sm text-slate-500">
        <span className="font-medium text-slate-700">
          {shortAddress(post.author)}
        </span>
        <div>
          <time dateTime={post.createdAt.toISOString()}>
            {post.createdAt.toLocaleString()}
          </time>
          {canDelete && onDelete && (
            <button
              onClick={() => onDelete(post.id)}
              className="ml-2 text-red-500 hover:text-red-700"
              aria-label="Delete post"
            >
              ✕
            </button>
          )}
        </div>
      </header>
      <p className="whitespace-pre-wrap text-slate-900">{post.content}</p>
      
      <footer className="mt-3 space-y-3">
        {/* Like button */}
        {onLike && (
          <div className="flex items-center gap-2">
            <button
              onClick={() => onLike(post.id)}
              disabled={!currentAccount}
              className={`flex items-center gap-1.5 rounded-md px-3 py-1.5 text-sm font-medium transition-colors ${
                hasLiked
                  ? "bg-red-50 text-red-600 hover:bg-red-100"
                  : "bg-slate-100 text-slate-600 hover:bg-slate-200"
              } disabled:opacity-40 disabled:cursor-not-allowed`}
              aria-label={hasLiked ? "Unlike post" : "Like post"}
            >
              <span className="text-base">{hasLiked ? "❤️" : "🤍"}</span>
              <span className="text-base">{post?.likes?.length || 0}</span>
            </button>

            {/* Comments toggle button */}
            <button
              onClick={() => setShowComments(!showComments)}
              className="flex items-center gap-1.5 rounded-md bg-slate-100 px-3 py-1.5 text-sm font-medium text-slate-600 transition-colors hover:bg-slate-200"
            >
              <span>💬</span>
              <span>{post.comments?.length || 0}</span>
            </button>
          </div>
        )}

        {/* Comments section */}
        {showComments && (
          <div className="border-t border-slate-100 pt-3 space-y-3">
            {/* Existing comments */}
            {post.comments && post.comments.length > 0 && (
              <div className="space-y-2">
                {post.comments.map((comment: Comment) => (
                  <div
                    key={comment.id}
                    className="rounded-md bg-slate-50 p-3 text-sm"
                  >
                    <div className="mb-1 flex items-center justify-between text-xs text-slate-500">
                      <span className="font-medium text-slate-700">
                        {shortAddress(comment.author)}
                      </span>
                      <div className="flex items-center gap-2">
                        <time dateTime={comment.createdAt.toISOString()}>
                          {comment.createdAt.toLocaleString()}
                        </time>
                        {isSameAddress(comment.author, currentAccount) &&
                          onDeleteComment && (
                            <button
                              onClick={() =>
                                onDeleteComment(post.id, comment.id)
                              }
                              className="text-red-500 hover:text-red-700"
                              aria-label="Delete comment"
                            >
                              ✕
                            </button>
                          )}
                      </div>
                    </div>
                    <p className="text-slate-900">{comment.content}</p>
                  </div>
                ))}
              </div>
            )}

            {/* Add comment input */}
            {currentAccount && onAddComment && (
              <div className="flex gap-2">
                <input
                  type="text"
                  value={commentText}
                  onChange={(e) => setCommentText(e.target.value)}
                  onKeyPress={(e) => {
                    if (e.key === "Enter" && !e.shiftKey) {
                      e.preventDefault();
                      handleAddComment();
                    }
                  }}
                  placeholder="写评论..."
                  className="flex-1 rounded-md border border-slate-300 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <button
                  onClick={handleAddComment}
                  disabled={!commentText.trim()}
                  className="rounded-md bg-blue-500 px-3 py-1.5 text-sm font-medium text-white hover:bg-blue-600 disabled:opacity-40 disabled:cursor-not-allowed"
                >
                  发送
                </button>
              </div>
            )}
          </div>
        )}
      </footer>
    </article>
  );
}

export function NewPost({
  onSubmit,
  currentAccount,
  onLike,
}: {
  onSubmit: (content: string) => void;
  currentAccount: Address | null;
  onLike?: (id: string) => void;
}) {
  const [text, setText] = useState("");
  return (
    <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <textarea
        className="w-full resize-none rounded-md border border-slate-300 p-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="Write a post..."
        value={text}
        onChange={(e) => setText(e.target.value)}
      />
      <button
        className="mt-2 rounded-md bg-blue-500 px-4 py-2 text-sm text-white hover:bg-blue-600 disabled:opacity-40"
        disabled={text.trim() === ""}
        onClick={() => {
          onSubmit(text.trim());
          setText("");
        }}
      >
        Post
      </button>
    </article>
  );
}
```

---

## 4. 更新 src/mockPosts.ts

在每个 mock post 对象中添加：
```typescript
comments: [],
```

---

## 实现的功能

✅ 显示评论数量  
✅ 点击💬按钮展开/收起评论  
✅ 添加新评论（需要连接钱包）  
✅ 删除自己的评论  
✅ 按Enter键快速发送评论  
✅ 评论会保存到 localStorage
