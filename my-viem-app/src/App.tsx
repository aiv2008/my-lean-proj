import { useEffect, useState } from "react";
import { createWalletClient, custom } from "viem";
import { mainnet } from "viem/chains";
import type { Address } from "viem";
import Post, { NewPost } from "./Post";
import { shortAddress } from "./address";
import { mockPosts } from "./mockPosts";
import type { Post as PostData } from "./type";

const STORAGE_KEY = "web3-social-posts";

export default function App() {
  const [account, setAccount] = useState<Address | null>(null);
  const [posts, setPosts] = useState<PostData[]>(() => {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored) {
      try {
        return JSON.parse(stored).map((p: any) => ({
          ...p,
          createdAt: new Date(p.createdAt),
        }));
      } catch (e) {
        return mockPosts;
      }
    }
    return mockPosts;
  });
  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(posts));
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
  async function connectWallet() {
    if (!window.ethereum) {
      alert("Please install MetaMask!");
      return;
    }

    const walletClient = createWalletClient({
      chain: mainnet,
      transport: custom(window.ethereum),
    });

    const [address] = await walletClient.requestAddresses();
    setAccount(address);
  }
  function disconnectWallet() {
    setAccount(null);
  }
  /**
   * 发帖
   */
  function createPost(content: string) {
    if (!account) {
      return;
    }

    const newPost: PostData = {
      id: crypto.randomUUID(),
      content,
      createdAt: new Date(),
      author: account,
    };

    setPosts([newPost, ...posts]);
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
          <Post key={post.id} post={post} />
        ))}
        <NewPost onSubmit={createPost} />
      </main>
    </div>
  );
}
