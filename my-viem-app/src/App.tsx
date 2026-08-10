import Post from "./Post";

export default function App() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
        <h1 className="text-lg font-semibold text-primary">Web3 Social</h1>
        <button
          type="button"
          className="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-white"
        >
          Connect
        </button>
      </header>

      <main className="mx-auto max-w-xl px-4 py-6">
        {/* 下一步：假数据 Feed 放这里 */}
        <p className="text-sm text-slate-500">Feed 区域（稍后放帖子列表）</p>
        <Post />
        <hr className="my-4 border-slate-200" />
        <Post />
      </main>
    </div>
  )
}
