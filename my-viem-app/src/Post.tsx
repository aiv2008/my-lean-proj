import { useEffect, useState } from "react";
import { shortAddress, isSameAddress } from "./address";
import type { Post as PostData, Comment } from "./type";
import type { Address } from "viem";
import { verifyPost } from "./sign";
import type { VerifyResult } from "./sign";

/**
 * 帖子签名徽章。
 * 验证是异步的，所以只有「挂载时 / 帖子变化时」跑一次 —— 绝不能在 render 里算，
 * 几 MB 的图每次 render 重算哈希会直接卡死页面。
 */
function SignatureBadge({ post }: { post: PostData }) {
  const [result, setResult] = useState<VerifyResult | null>(null);

  useEffect(() => {
    let cancelled = false;
    setResult(null);
    verifyPost(post).then((r) => {
      // 组件已经卸载或帖子已经换了，迟到的结果直接丢掉
      if (!cancelled) setResult(r);
    });
    return () => {
      cancelled = true;
    };
    // 只依赖真正参与验签的字段：likes 变化不该触发重新验签
  }, [post.author, post.content, post.createdAt, post.images, post.signature]);

  if (!result) {
    return <span className="text-xs text-slate-400">验证中…</span>;
  }
  switch (result.status) {
    case "valid":
      return (
        <span
          className="rounded-md bg-green-50 px-2 py-0.5 text-xs text-green-700"
          title={`签名者 ${result.signer}`}
        >
          ✅ 签名有效
        </span>
      );
    case "invalid":
      return (
        <span
          className="rounded-md bg-red-50 px-2 py-0.5 text-xs text-red-700"
          title={`签名者 ${result.signer}，帖子作者 ${result.author}，两者不一致`}
        >
          ⚠️ 签名不符（内容可能被改过）
        </span>
      );
    case "broken":
      return (
        <span className="rounded-md bg-red-50 px-2 py-0.5 text-xs text-red-700">
          ⚠️ 签名已损坏
        </span>
      );
    case "unsigned":
      return <span className="text-xs text-slate-400">未签名</span>;
  }
}

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
        ? post.likes?.some((addr) => { isSameAddress(addr, currentAccount)})
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
        <div className="flex items-center gap-2">
          <span className="font-medium text-slate-700">
            {shortAddress(post.author)}
          </span>
          <SignatureBadge post={post} />
        </div>
        <div className="flex items-center gap-2">
          <time dateTime={post.createdAt.toISOString()}>
            {post.createdAt.toLocaleString()}
          </time>
          {canDelete && onDelete && (
            <button
              onClick={() => onDelete(post.id)}
              className="text-red-500 hover:text-red-700"
              aria-label="Delete post"
            >
              x
            </button>
          )}
        </div>
      </header>
      <p className="whitespace-pre-wrap text-slate-900">{post.content}</p>
      {/* Display images */}
      {post.images && post.images.length > 0 && (
        <div className="mt-3 grid grid-cols-2 gap-2">
          {post.images.map((img, index) => (
            <img
              key={index}
              src={img}
              alt={`Post image ${index + 1}`}
              className="w-full rounded-md object-cover"
              style={{ maxHeight: "300px" }}
            />
          ))}
        </div>
      )}
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
              <span className="text-base">{post?.likes?.length}</span>
            </button>

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
                        <time dateTime={comment.createAt.toLocaleString()}>
                          {comment.createAt.toLocaleString()}
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
                              x
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
  currentAccount,
  onSubmit,
}: {
  currentAccount: Address | null;
  onSubmit: (content: string, images?: string[]) => Promise<Boolean>;
}) {
  const [text, setText] = useState("");
  const [images, setImages] = useState<string[]>([]);
  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;

    Array.from(files).forEach((file) => {
      // 校验必须在这里做：图片最终会变成 base64 存进 localStorage，
      // 不拦的话一张大图就能把配额撑爆（base64 比原文件大 33%）。
      if (!file.type.startsWith("image/")) {
        alert(`「${file.name}」不是图片，已跳过`);
        return;
      }
      if (file.size > 5 * 1024 * 1024) {
        alert(`「${file.name}」超过 5MB，已跳过`);
        return;
      }
      const reader = new FileReader();
      reader.onload = (event) => {
        if (event.target?.result) {
          setImages((prev) => [...prev, event.target!.result as string]);
        }
      };
      reader.readAsDataURL(file);
    });
    // 清空 input，否则「再选一次同一个文件」不会触发 change
    e.target.value = "";
  };
  const removeImage = (index: number) => {
    setImages((prev) => prev.filter((_, i) => i !== index));
  };

  const [isSubmitting, setIsSubmitting] = useState(false);
  const handleSubmit = async () => {
    if (isSubmitting) return;
    setIsSubmitting(true);
    try {
      const ok = await onSubmit(text.trim(), images);
      if (ok) {
        setText("");
        setImages([]);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <textarea
        className="w-full resize-none rounded-md border border-slate-300 p-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="Write a post..."
        value={text}
        onChange={(e) => setText(e.target.value)}
      />

      {/**Image previews**/}
      {images.length > 0 && (
        <div>
          {images.map((img, index) => (
            <div key={index} className="relative">
              <img
                src={img}
                alt={`Preview ${index + 1}`}
                className="h-32 w-full rounded-md object-cover"
              />
              <button
                onClick={() => {
                  removeImage(index);
                }}
                className="absolute right-1 top-1 rounded-full bg-red-500 px-2 py-0.5 text-xs text-white hover:bg-red-600"
              >
                x
              </button>
            </div>
          ))}
        </div>
      )}
      <div className="mt-2 flex items-center gap-3">
        <label className="cursor-pointer rounded-md bg-slate-100 px-3 py-2 text-sm text-slate-700 hover:bg-slate-200">
          <span>📷 图片</span>
          <input
            type="file"
            accept="image/*"
            multiple
            className="hidden"
            onChange={handleImageUpload}
          />
        </label>
        {!currentAccount && (
          <span className="text-sm text-slate-500">请先连接钱包再发帖</span>
        )}
      </div>
      <button
        className="mt-auto rounded-md bg-blue-500 px-4 py-2 text-sm text-white hover:bg-blue-600 disabled:opacity-40 disabled:cursor-not-allowed"
        disabled={
          !currentAccount ||
          isSubmitting ||
          (text.trim() === "" && images.length === 0)
        }
        onClick={handleSubmit}
      >
        {isSubmitting ? "等待签名…" : "Post"}
      </button>
    </article>
  );
}
