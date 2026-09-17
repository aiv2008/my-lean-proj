import { recoverMessageAddress } from "viem";
import type { Address, Hex } from "viem";
import { keccak256, stringToBytes } from "viem";
import { isSameAddress } from "./address";

/**
 * 待签名帖子的最小形状 —— 凡是「要签的 / 要验的东西」都按这个形状传。
 * 刻意不用完整的 Post：这样签名侧就不会顺手把 likes、id 这类
 * 不该进签名的字段混进去。
 */
export type SignablePost = {
  author: Address;
  content: string;
  createdAt: Date;
  images?: string[];
};

/**
 * 把帖子内容拼成一段人类可读的待签名文本。
 * 发帖时签它，验证时用同样的规则重新拼一次 —— 两边必须逐字一致，
 * 差一个空格 recover 出来的地址就完全不同。
 */
export function buildPostMessage(input: SignablePost) {
  const imageHashes = (input.images ?? []).map((img) =>
    keccak256(stringToBytes(img)),
  );
  return [
    "Web3 Social — 发帖签名 v1",
    `作者: ${input.author.toLowerCase()}`,
    `时间: ${input.createdAt.toISOString()}`,
    `图片数: ${imageHashes.length}`,
    ...imageHashes,
    "内容:",
    input.content,
  ].join("\n");
}

/**
 * 发帖时签名：用同一个 post 对象构造待签名文本，返回 65 字节签名。
 *
 * 传入的必须就是「最终要存下来的那个对象」——如果签名后又改了
 * content / createdAt / images，验签必然失败。
 */
export async function signPost(
  input: SignablePost & {
    signMessage: (args: { account: Address; message: string }) => Promise<Hex>;
  },
): Promise<Hex> {
  const message = buildPostMessage(input);
  return input.signMessage({ account: input.author, message });
}

export type VerifyResult =
  /** 验签通过：签名确实是这个作者对这份内容签的 */
  | { status: "valid"; signer: Address }
  /** 验签不通过：内容被改过，或者签名不是这个作者签的（signer 为实际签名者） */
  | { status: "invalid"; signer: Address; author: Address }
  /** 验签不通过，而且签名本身已经坏掉，recover 不出地址 */
  | { status: "broken"; author: Address }
  /** 没有签名（mockPosts 和 localStorage 里的老帖子） */
  | { status: "unsigned" };

/**
 * 验证帖子签名：从签名里反推出签名者地址，再和 post.author 比对。
 *
 * 注意是异步的（recoverMessageAddress 返回 Promise），所以调用方
 * 不能在 render 里直接调——几 MB 的图每次 render 都重算会卡死。
 */
export async function verifyPost(
  input: SignablePost & { signature?: Hex },
): Promise<VerifyResult> {
  if (!input.signature) {
    return { status: "unsigned" };
  }
  const message = buildPostMessage(input);
  try {
    const signer = await recoverMessageAddress({
      message,
      signature: input.signature,
    });
    if (isSameAddress(signer, input.author)) {
      return { status: "valid", signer };
    }
    return { status: "invalid", signer, author: input.author };
  } catch (err) {
    // 签名残缺（比如被人手动改坏）时 recover 会抛异常 —— 这同样是验签失败，
    // 不能让它把整棵组件树带崩。
    console.warn("verifyPost failed to recover signer:", err);
    return { status: "broken", author: input.author };
  }
}
