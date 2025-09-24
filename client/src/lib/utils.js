import { clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs) {
  return twMerge(clsx(inputs))
}

// API utilities
const API_BASE_URL = 'http://localhost:3000'

export const api = {
  async request(endpoint, options = {}) {
    const url = `${API_BASE_URL}${endpoint}`
    
    const config = {
      credentials: 'include',
      headers: {
        'Content-Type': 'application/json',
        ...options.headers,
      },
      ...options,
    }

    if (config.body && typeof config.body === 'object') {
      config.body = JSON.stringify(config.body)
    }

    const response = await fetch(url, config)
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}))
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
    }
    
    return response.json()
  },

  // Auth endpoints
  async login(email, password) {
    return this.request('/api/auth/login', {
      method: 'POST',
      body: { email, password },
    })
  },

  async register(name, email, password, role = 'user') {
    return this.request('/api/auth/register', {
      method: 'POST',
      body: { name, email, password, role },
    })
  },

  async logout() {
    return this.request('/api/auth/logout', {
      method: 'POST',
    })
  },

  // User endpoints
  async getUsers() {
    return this.request('/api/users')
  },

  async createUser(userData) {
    return this.request('/api/users', {
      method: 'POST',
      body: userData,
    })
  },

  async updateUser(id, userData) {
    return this.request(`/api/users/${id}`, {
      method: 'PUT',
      body: userData,
    })
  },

  async deleteUser(id) {
    return this.request(`/api/users/${id}`, {
      method: 'DELETE',
    })
  },
}

// Password generator
export function generatePassword(length = 12) {
  const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
  let password = ""
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length))
  }
  return password
}