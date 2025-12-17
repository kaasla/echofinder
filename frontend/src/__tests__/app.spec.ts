import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import HomePage from '@/pages/HomePage.vue'

describe('HomePage', () => {
  it('renders welcome message', () => {
    const wrapper = mount(HomePage)
    expect(wrapper.text()).toContain('Welcome to EchoFinder')
  })
})

describe('Test Runner', () => {
  it('works correctly', () => {
    expect(true).toBe(true)
  })
})
