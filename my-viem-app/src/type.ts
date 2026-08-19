import type { Address } from "viem";

export type Post = {
  id: string;
  author: Address;
  content: string;
  createdAt: Date;
};
export type User = {
  address: Address;
  displayName?: string;
};
