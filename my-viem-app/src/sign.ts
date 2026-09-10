import {recoverMessageAddress} from 'viem';
import type {Address, Hex} from 'viem';
import {isSameAddress} from './address';

/**
   * 把帖子内容拼成一段人类可读的待签名文本。
   * 发帖时签它，验证时用同样的规则重新拼一次 —— 两边必须逐字一致，
   * 差一个空格 recover 出来的地址就完全不同。
   */
export function buildPostMessage(input: {
    author: Address;
    content: string;
    createdAt: Date;
}){
    return [ "Web3 Social — 发帖签名",
      `作者: ${input.author.toLowerCase()}`,
      `时间: ${input.createdAt.toISOString()}`,
      "内容:",
      input.content,
    ].join("\n");
}
