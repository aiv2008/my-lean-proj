# 图片上传功能实现文档

## 功能概述
为 Web3 Social 应用添加图片上传功能，支持：
- 多图片选择和上传
- 图片预览（发布前）
- 删除已选图片
- 在帖子中展示图片
- 图片数据持久化（base64 格式存储）

---

## 1. NewPost 组件更新 (src/Post.tsx)

### 完整的 NewPost 组件代码

```typescript
export function NewPost({
  onSubmit,
  currentAccount,
  onLike,
}: {
  onSubmit: (content: string, images?: string[]) => void;
  currentAccount: Address | null;
  onLike?: (id: string) => void;
}) {
  const [text, setText] = useState("");
  const [images, setImages] = useState<string[]>([]);

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files) return;


Array.from(files).forEach((file) => {
      if (file.type.startsWith("image/")) {
        const reader = new FileReader();
        reader.onload = (event) => {
          if (event.target?.result) {
            setImages((prev) => [...prev, event.target!.result as string]);
          }
        };
        reader.readAsDataURL(file);
      }
    });
  };

  const removeImage = (index: number) => {
    setImages((prev) => prev.filter((_, i) => i !== index));
  };

  const handleSubmit = () => {
    onSubmit(text.trim(), images.length > 0 ? images : undefined);
    setText("");
    setImages([]);
  };

  return (
    <article className="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <textarea
        className="w-full resize-none rounded-md border border-slate-300 p-2 text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="写点什么..."
        value={text}
        onChange={(e) => setText(e.target.value)}
      />

      {/* Image previews */}
      {images.length > 0 && (
        <div className="mt-3 grid grid-cols-2 gap-2">
          {images.map((img, index) => (
            <div key={index} className="relative">
              <img
                src={img}
                alt={`Preview ${index + 1}`}
                className="h-32 w-full rounded-md object-cover"
              />
              <button
                onClick={() => removeImage(index)}
                className="absolute right-1 top-1 rounded-full bg-red-500 px-2 py-0.5 text-xs text-white hover:bg-red-600"
              >
                ×
              </button>
            </div>
          ))}
        </div>
      )}

      <div className="mt-2 flex items-center gap-2">
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
        <button
          className="ml-auto rounded-md bg-blue-500 px-4 py-2 text-sm text-white hover:bg-blue-600 disabled:opacity-40 disabled:cursor-not-allowed"
          disabled={text.trim() === "" && images.length === 0}
          onClick={handleSubmit}
        >
          发布
        </button>
      </div>
    </article>
  );
}
```

### 关键改动说明
1. **新增状态**: `const [images, setImages] = useState<string[]>([]);`
2. **修改 onSubmit 签名**: 接受 `(content: string, images?: string[])` 参数
3. **handleImageUpload**: 使用 FileReader 将图片转换为 base64
4. **removeImage**: 删除预览中的图片
5. **handleSubmit**: 提交时包含图片数据
6. **UI 改动**: 添加图片预览网格和上传按钮

---

## 2. Post 组件更新 - 显示图片 (src/Post.tsx)

在 `<p className="whitespace-pre-wrap text-slate-900">{post.content}</p>` 之后添加：

```typescript
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
```

### 插入位置示例
```typescript
<p className="whitespace-pre-wrap text-slate-900">{post.content}</p>

{/* 在这里插入上面的图片显示代码 */}

<footer className="mt-3 space-y-3">
  {/* Like button */}
  ...
</footer>
```

---

## 3. App.tsx 更新 - createPost 函数

### 完整的 createPost 函数代码

```typescript
  /**
   * 发帖
   */
  function createPost(content: string, images?: string[]) {
    if (!account) {
      return;
    }

    const newPost: PostData = {
      id: crypto.randomUUID(),
      content,
      createdAt: new Date(),
      author: account,
      likes: [],
      comments: [],
      images: images || [],
    };

    setPosts([newPost, ...posts]);
  }
```

### 关键改动
1. **函数签名**: 添加 `images?: string[]` 参数
2. **newPost 对象**: 添加 `images: images || []` 字段

---

## 4. 类型定义 (src/type.ts)

确认 Post 类型已包含 images 字段（当前代码已有）：

```typescript
export type Post = {
  id: string;
  author: Address;
  content: string;
  createdAt: Date;
  likes: Address[];
  comments: Comment[];
  images?: string[];  // ✅ 已存在
};
```

---

## 技术细节

### 图片存储方式
- 使用 **base64 编码**存储图片
- 存储在 localStorage 中（随帖子数据一起）
- 适合小型应用和演示项目

### 优化建议（可选）
1. **图片大小限制**: 添加文件大小检查（如限制 5MB）
2. **图片压缩**: 使用 canvas API 压缩大图片
3. **图片数量限制**: 限制每个帖子最多上传图片数量（如 4 张）
4. **外部存储**: 对于生产环境，考虑使用 IPFS、Cloudinary 或 AWS S3

### 示例：添加图片大小限制

```typescript
const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
  const files = e.target.files;
  if (!files) return;

  const MAX_SIZE = 5 * 1024 * 1024; // 5MB

  Array.from(files).forEach((file) => {
    if (!file.type.startsWith("image/")) {
      alert("请选择图片文件");
      return;
    }
    
    if (file.size > MAX_SIZE) {
      alert("图片大小不能超过 5MB");
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
};
```

---

## 测试清单

- [ ] 可以选择单个图片
- [ ] 可以选择多个图片
- [ ] 图片预览正确显示
- [ ] 可以删除预览中的图片
- [ ] 发布后图片在帖子中显示
- [ ] 刷新页面后图片仍然存在（localStorage 持久化）
- [ ] 只有图片（无文字）也可以发布
- [ ] 按钮禁用状态正确（文字和图片都为空时禁用）

---

## 实现步骤

1. 更新 `src/Post.tsx` 中的 `NewPost` 组件
2. 在 `src/Post.tsx` 中的 `Post` 组件添加图片显示代码
3. 更新 `src/App.tsx` 中的 `createPost` 函数
4. 测试功能是否正常工作

---

创建时间: 2026-09-07
