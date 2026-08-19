import { useState } from "react";
import { shortAddress } from "./address";
import type { Post as PostData } from "./type";

export default function Post({ post }: { post: PostData }) {
  return (
    <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <header className="mb-2 flex items-center justify-between gap-3 text-sm text-slate-500">
        <span className="font-medium text-slate-700">
          {shortAddress(post.author)}
        </span>
        <time dateTime={post.createdAt.toISOString()}>
          {post.createdAt.toLocaleString()}
        </time>
      </header>
      <p className="whitespace-pre-wrap text-slate-900">{post.content}</p>
    </article>
  );
}

export function NewPost({ onSubmit }: { onSubmit: (content: string) => void }) {
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
        onClick={() => { onSubmit(text.trim()); setText(""); }}
      >
        Post
      </button>
    </article>
  );
}
