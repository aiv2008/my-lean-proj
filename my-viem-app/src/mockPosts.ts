import type { Post } from './type'

export const mockPosts: Post[] = [
  {
    id: '1',
    author: '0x71C7656EC7ab88b098defB751B7401B5f6d8976F',
    content: 'Just connected my wallet. Hello Web3 Social.',
      createdAt: new Date('2026-08-13T09:12:00'),
      likes: [],
  },
  {
    id: '2',
    author: '0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B',
    content: 'Feed is still mock data. Compose comes next.',
      createdAt: new Date('2026-08-12T18:40:00'),
       likes: [],
  },
  {
    id: '3',
    author: '0x1234567890abcdef1234567890abcdef12345678',
    content: 'Unconnected visitors can still browse the timeline.',
      createdAt: new Date('2026-08-11T14:05:00'),
       likes: [],
  },
    
]
