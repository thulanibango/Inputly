import React, { createContext, useContext, useState, useEffect } from 'react'
import { api } from '../lib/utils'

const AuthContext = createContext()

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  // Check if user is logged in on app start
  useEffect(() => {
    checkAuth()
  }, [])

  const checkAuth = async () => {
    try {
      // Try to fetch user data using the existing cookie
      const response = await api.request('/api/users/me')
      console.log('CheckAuth response:', response) // Debug log
      setUser(response.user) // Changed from response.data.user to response.user
    } catch (error) {
      console.log('CheckAuth error:', error) // Debug log
      // User is not logged in
      setUser(null)
    } finally {
      setLoading(false)
    }
  }

  const login = async (email, password) => {
    try {
      const response = await api.login(email, password)
      console.log('Login response:', response) // Debug log
      setUser(response.user) // Changed from response.data.user to response.user
      return { success: true, user: response.user }
    } catch (error) {
      return { success: false, error: error.message }
    }
  }

  const register = async (name, email, password, role = 'user') => {
    try {
      const response = await api.register(name, email, password, role)
      console.log('Register response:', response) // Debug log
      setUser(response.user) // Changed from response.data.user to response.user
      return { success: true, user: response.user }
    } catch (error) {
      return { success: false, error: error.message }
    }
  }

  const logout = async () => {
    try {
      await api.logout()
      setUser(null)
      return { success: true }
    } catch (error) {
      // Even if logout fails, clear local state
      setUser(null)
      return { success: true }
    }
  }

  const value = {
    user,
    login,
    register,
    logout,
    loading,
    isAuthenticated: !!user,
    isAdmin: user?.role === 'admin'
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}