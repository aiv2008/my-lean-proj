import type { Address } from "viem";

export type Post = {
  id: string;
  author: Address;
  content: string;
  createdAt: Date;
  likes: Address[];
  comments: Comment[];
};
export type User = {
  address: Address;
  displayName?: string;
};
export type Comment = {
  id: string;
  author: Address;
  content: string;
  createAt: Date;
};
