import { useEffect, useState } from "react";
import { createWalletClient, custom } from "viem";
import { mainnet } from "viem/chains";
import type { Address } from "viem";
import Post, { NewPost } from "./Post";
import { shortAddress } from "./address";
import { mockPosts } from "./mockPosts";
import type { Post as PostData, Comment } from "./type";
import { buildPostMessage, signPost } from "./sign";

const STORAGE_KEY = "web3-social-posts";

export default function App() {
  const [account, setAccount] = useState<Address | null>(null);
  const [posts, setPosts] = useState<PostData[]>(() => {
      const stored = localStorage.getItem(STORAGE_KEY);
      console.log(`stored: ${JSON.stringify(stored)}`);
    if (stored) {
      try {
        return JSON.parse(stored).map((p: any) => ({
          ...p,
          createdAt: new Date(p.createdAt),
          comments:
            p.comments?.map((c: any) => ({
              ...c,
              createAt: new Date(c.createAt),
            })) || [],
        }));
      } catch (e) {
        return mockPosts;
      }
    }
    return mockPosts;
  });
  useEffect(() => {
    // 图片走 base64，配额很容易被撑爆；不兜住的话 useEffect 抛异常会直接
    // 把整棵组件树带崩（白屏），帖子明明还在内存里却发不出去。
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(posts));
    } catch (err) {
      console.error("保存到 localStorage 失败：", err);
      alert(
        "浏览器本地存储已满，这条内容无法持久化（图片太占空间，刷新后会丢失）",
      );
    }
  }, [posts]);
  // listen for account changes
  useEffect(() => {
    if (!window.ethereum) return;
    const handleAccountsChanged = (accounts: string[]) => {
      if (accounts.length === 0) {
        setAccount(null);
      } else {
        setAccount(accounts[0] as Address);
      }
    };
    window.ethereum.on("accountsChanged", handleAccountsChanged);
    return () => {
      window.ethereum?.removeListener("accountsChanged", handleAccountsChanged);
    };
  }, []);

  function getWalletClient() {
    if (!window.ethereum) {
      return null;
    }
    return createWalletClient({
      chain: mainnet,
      transport: custom(window.ethereum),
    });
  }

  async function connectWallet() {
    const walletClient = getWalletClient();
    if (!walletClient) {
      alert("Please install MetaMask!");
      return;
    }
    const [address] = await walletClient.requestAddresses();
    setAccount(address);
  }
  function disconnectWallet() {
    setAccount(null);
  }
  /**
   * 发帖
   */
  async function createPost(content: string, images?: string[]) {
    if (!account) {
      return false;
    }
    const walletClient = getWalletClient();
    if (!walletClient) return false;
    // 1) 先把 post 完整组装好 —— 和最终要存的完全一致
    const newPost: PostData = {
      id: crypto.randomUUID(),
      content,
      createdAt: new Date(),
      author: account,
      likes: [],
      comments: [],
      images: images,
    };
    // 2) 构造待签名文本 —— 走 sign.ts 的唯一入口，验证侧调的是同一个函数
    console.log("signing message:\n" + buildPostMessage(newPost));
    try {
      // 3) 签名
      const signature = await signPost({
        ...newPost,
        signMessage: (args) => walletClient.signMessage(args),
      });
      // 4) 签名成功才入库
      setPosts([{ ...newPost, signature }, ...posts]);
      return true;
    } catch (err) {
      // 5) 失败绝不能入库
      if ((err as { code?: number }).code === 4001) {
        alert("你取消了签名，帖子没有发布");
      } else {
        console.error(err);
        alert("签名失败，帖子没有发布");
      }
      return false;
    }
  }
  /**
   *
   **/
  function deletePost(id: string) {
    setPosts(posts.filter((p) => p.id !== id));
  }
  /**
   * 点赞/取消点赞
   */
  function toggleLike(postId: string) {
    if (!account) {
      return;
    }

    setPosts(
      posts.map((post) => {
        if (post.id !== postId) {
          return post;
        }

        const hasLiked = post.likes?.some(
          (addr) => addr.toLowerCase() === account.toLowerCase(),
        );
        if (hasLiked) {
          // 取消点赞
          return {
            ...post,
            likes: post.likes.filter(
              (addr) => addr.toLowerCase() !== account.toLowerCase(),
            ),
          };
        } else {
          // 添加点赞
          return {
            ...post,
              likes: [...post?.likes, account],
          };
        }
      }),
    );
  }

  /**
   * 添加评论
   **/
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
          createAt: new Date(),
        };
        return {
          ...post,
          comments: [...(post.comments ?? []), newComment],
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
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900">
      <header className="flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3">
        <h1 className="text-lg font-semibold text-primary">Web3 Social</h1>
        {account ? (
          <div>
            <span className="rounded-md bg-slate-100 px-3 py-1.5 font-mono text-sm text-slate-700">
              {shortAddress(account)}
            </span>
            <button
              type="button"
              className="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-white"
              onClick={disconnectWallet}
            >
              Disconnect
            </button>
          </div>
        ) : (
          <button
            type="button"
            className="rounded-md bg-primary px-3 py-1.5 text-sm font-medium text-white"
            onClick={connectWallet}
          >
            Connect
          </button>
        )}
      </header>

      <main className="mx-auto flex max-w-xl flex-col gap-4 px-4 py-6">
        {posts.map((post: PostData) => (
          <Post
            key={post.id}
            post={post}
            currentAccount={account}
            onDelete={deletePost}
            onLike={toggleLike} // NEW: Connected like functionality
            onAddComment={addComment}
            onDeleteComment={deleteComment}
          />
        ))}
        <NewPost currentAccount={account} onSubmit={createPost} />
      </main>
    </div>
  );
}
