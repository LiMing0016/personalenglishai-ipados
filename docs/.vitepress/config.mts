import { defineConfig } from 'vitepress'

const sharedSearch = {
  provider: 'local' as const
}

export default defineConfig({
  title: 'Personal English AI iPadOS',
  description: 'Personal English AI iPadOS 客户端开发路线图与架构文档',
  cleanUrls: true,
  lastUpdated: true,
  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      title: 'Personal English AI iPadOS',
      description: 'Personal English AI iPadOS 客户端开发路线图与架构文档',
      themeConfig: {
        nav: [
          { text: '首页', link: '/' },
          { text: '路线图', link: '/roadmap' },
          { text: 'AI 助手 P0', link: '/ai-assistant-p0' },
          { text: 'AI 助手 P1', link: '/ai-assistant-p1' },
          { text: '架构', link: '/architecture' },
          { text: '阶段记录', link: '/phase-log' }
        ],
        sidebar: [
          {
            text: '开始',
            items: [
              { text: '总览', link: '/' },
              { text: '路线图', link: '/roadmap' },
              { text: '阶段记录', link: '/phase-log' }
            ]
          },
          {
            text: '设计',
            items: [
              { text: '架构', link: '/architecture' },
              { text: '登录与会话设计', link: '/auth-session-design' },
              { text: 'AI 助手 P0 稳定闭环', link: '/ai-assistant-p0' },
              { text: 'AI 助手 P1 聊天体验', link: '/ai-assistant-p1' },
              { text: 'API 接入', link: '/api-integration' },
              { text: 'iPadOS 详细规划', link: '/ipados-development-plan' }
            ]
          }
        ],
        outline: {
          label: '页面导航',
          level: [2, 3]
        },
        search: sharedSearch
      }
    },
    en: {
      label: 'English',
      lang: 'en-US',
      title: 'Personal English AI iPadOS',
      description: 'Development roadmap and architecture notes for the iPadOS client.',
      themeConfig: {
        nav: [
          { text: 'Home', link: '/en/' },
          { text: 'Roadmap', link: '/en/roadmap' },
          { text: 'AI Assistant P0', link: '/en/ai-assistant-p0' },
          { text: 'AI Assistant P1', link: '/en/ai-assistant-p1' },
          { text: 'Architecture', link: '/en/architecture' },
          { text: 'Phase Log', link: '/en/phase-log' }
        ],
        sidebar: [
          {
            text: 'Start Here',
            items: [
              { text: 'Overview', link: '/en/' },
              { text: 'Roadmap', link: '/en/roadmap' },
              { text: 'Phase Log', link: '/en/phase-log' }
            ]
          },
          {
            text: 'Design',
            items: [
              { text: 'Architecture', link: '/en/architecture' },
              { text: 'Auth And Session Design', link: '/en/auth-session-design' },
              { text: 'AI Assistant P0 Stability', link: '/en/ai-assistant-p0' },
              { text: 'AI Assistant P1 Chat', link: '/en/ai-assistant-p1' },
              { text: 'API Integration', link: '/en/api-integration' },
              { text: 'iPadOS Development Plan', link: '/en/ipados-development-plan' }
            ]
          }
        ],
        outline: {
          label: 'On This Page',
          level: [2, 3]
        },
        search: sharedSearch
      }
    }
  }
})
