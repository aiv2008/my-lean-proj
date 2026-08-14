import { shortAddress } from './address'
import type { Post as PostData } from './type'

export default function Post({ post }: { post: PostData }) {
  return (
    <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <header className="mb-2 flex items-center justify-between gap-3 text-sm text-slate-500">
        <span className="font-medium text-slate-700">{shortAddress(post.author)}</span>
        <time dateTime={post.createdAt.toISOString()}>
          {post.createdAt.toLocaleString()}
        </time>
      </header>
      <p className="whitespace-pre-wrap text-slate-900">{post.content}</p>
    </article>
  )
}
