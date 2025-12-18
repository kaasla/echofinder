import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import HomePage from '@/pages/HomePage.vue'
import NotFoundPage from '@/pages/NotFoundPage.vue'
import AppLayout from '@/layouts/AppLayout.vue'

// Unit Tests
describe('HomePage', () => {
  it('renders welcome heading', () => {
    const wrapper = mount(HomePage)
    expect(wrapper.find('h1').text()).toBe('Welcome to EchoFinder')
  })

  it('renders description text', () => {
    const wrapper = mount(HomePage)
    expect(wrapper.text()).toContain('Discover live events')
  })
})

describe('NotFoundPage', () => {
  it('renders 404 heading', () => {
    const wrapper = mount(NotFoundPage, {
      global: {
        stubs: {
          'router-link': {
            template: '<a><slot /></a>'
          }
        }
      }
    })
    expect(wrapper.find('h1').text()).toBe('404')
  })

  it('renders page not found message', () => {
    const wrapper = mount(NotFoundPage, {
      global: {
        stubs: {
          'router-link': {
            template: '<a><slot /></a>'
          }
        }
      }
    })
    expect(wrapper.text()).toContain('Page not found')
  })

  it('has Go Home link', () => {
    const wrapper = mount(NotFoundPage, {
      global: {
        stubs: {
          'router-link': {
            template: '<a><slot /></a>'
          }
        }
      }
    })
    expect(wrapper.text()).toContain('Go Home')
  })
})

describe('AppLayout', () => {
  it('renders navigation with app name', () => {
    const wrapper = mount(AppLayout, {
      global: {
        stubs: {
          'router-link': {
            template: '<a><slot /></a>'
          },
          'router-view': {
            template: '<div data-testid="router-view"></div>'
          }
        }
      }
    })
    expect(wrapper.text()).toContain('EchoFinder')
  })

  it('contains router-view for page content', () => {
    const wrapper = mount(AppLayout, {
      global: {
        stubs: {
          'router-link': {
            template: '<a><slot /></a>'
          },
          'router-view': {
            template: '<div data-testid="router-view"></div>'
          }
        }
      }
    })
    expect(wrapper.find('[data-testid="router-view"]').exists()).toBe(true)
  })

  it('has nav and main elements', () => {
    const wrapper = mount(AppLayout, {
      global: {
        stubs: {
          'router-link': {
            template: '<a><slot /></a>'
          },
          'router-view': {
            template: '<div></div>'
          }
        }
      }
    })
    expect(wrapper.find('nav').exists()).toBe(true)
    expect(wrapper.find('main').exists()).toBe(true)
  })
})

// Integration Tests - Router/Layout Wiring
describe('Router Integration', () => {
  const createTestRouter = () => {
    return createRouter({
      history: createWebHistory(),
      routes: [
        { path: '/', name: 'home', component: HomePage },
        { path: '/:pathMatch(.*)*', name: 'not-found', component: NotFoundPage }
      ]
    })
  }

  it('renders HomePage at root route', async () => {
    const router = createTestRouter()
    router.push('/')
    await router.isReady()

    const wrapper = mount(AppLayout, {
      global: {
        plugins: [router]
      }
    })

    expect(wrapper.text()).toContain('Welcome to EchoFinder')
  })

  it('renders NotFoundPage for unknown routes', async () => {
    const router = createTestRouter()
    router.push('/unknown-page')
    await router.isReady()

    const wrapper = mount(AppLayout, {
      global: {
        plugins: [router]
      }
    })

    expect(wrapper.text()).toContain('404')
    expect(wrapper.text()).toContain('Page not found')
  })

  it('AppLayout wraps routed content with navigation', async () => {
    const router = createTestRouter()
    router.push('/')
    await router.isReady()

    const wrapper = mount(AppLayout, {
      global: {
        plugins: [router]
      }
    })

    // Navigation is present
    expect(wrapper.find('nav').exists()).toBe(true)
    expect(wrapper.find('nav').text()).toContain('EchoFinder')

    // Page content is rendered
    expect(wrapper.find('main').exists()).toBe(true)
    expect(wrapper.find('main').text()).toContain('Welcome to EchoFinder')
  })
})
