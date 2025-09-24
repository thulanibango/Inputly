import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { LogOut, Settings, User, Crown } from 'lucide-react'
import { Button } from '../ui/button'
import { useAuth } from '../../contexts/AuthContext'
import { AddUserForm } from './AddUserForm'
import { UsersList } from './UsersList'

export function Dashboard() {
  const { user, logout, isAdmin } = useAuth()
  const [refreshTrigger, setRefreshTrigger] = useState(0)

  const handleLogout = async () => {
    await logout()
  }

  const handleUserAdded = () => {
    // Trigger users list refresh
    setRefreshTrigger(prev => prev + 1)
  }

  return (
    <div className="min-h-screen gradient-bg-dark">
      {/* Animated background elements */}
      <div className="absolute inset-0 overflow-hidden">
        <motion.div
          className="absolute -top-40 -right-40 w-80 h-80 bg-blue-500/5 rounded-full blur-3xl"
          animate={{
            x: [0, 50, 0],
            y: [0, -50, 0],
          }}
          transition={{
            duration: 25,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
        <motion.div
          className="absolute -bottom-40 -left-40 w-80 h-80 bg-purple-500/5 rounded-full blur-3xl"
          animate={{
            x: [0, -50, 0],
            y: [0, 50, 0],
          }}
          transition={{
            duration: 20,
            repeat: Infinity,
            ease: "easeInOut"
          }}
        />
      </div>

      <div className="relative z-10">
        {/* Header */}
        <motion.header
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="bg-black/20 backdrop-blur-sm border-b border-white/10"
        >
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between h-16">
              <div className="flex items-center gap-3">
                <motion.h1 
                  className="text-2xl font-bold text-white"
                  animate={{ 
                    textShadow: [
                      "0 0 10px rgba(255,255,255,0.3)",
                      "0 0 20px rgba(255,255,255,0.5)",
                      "0 0 10px rgba(255,255,255,0.3)"
                    ]
                  }}
                  transition={{ 
                    duration: 4,
                    repeat: Infinity,
                    ease: "easeInOut"
                  }}
                >
                  Inputly
                </motion.h1>
                <span className="text-white/40">|</span>
                <span className="text-white/70">Dashboard</span>
              </div>

              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-white/10 backdrop-blur-sm border border-white/20">
                  {isAdmin ? (
                    <Crown className="w-4 h-4 text-yellow-400" />
                  ) : (
                    <User className="w-4 h-4 text-blue-400" />
                  )}
                  <span className="text-white/90 text-sm font-medium">
                    {user?.name}
                  </span>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${
                    isAdmin 
                      ? 'bg-yellow-500/20 text-yellow-400' 
                      : 'bg-blue-500/20 text-blue-400'
                  }`}>
                    {user?.role}
                  </span>
                </div>

                <Button
                  variant="ghost"
                  size="icon"
                  className="text-white/60 hover:text-white hover:bg-white/10"
                  onClick={() => alert('Settings to be implemented')}
                >
                  <Settings className="w-4 h-4" />
                </Button>

                <Button
                  variant="glass"
                  onClick={handleLogout}
                  className="text-white"
                >
                  <LogOut className="w-4 h-4 mr-2" />
                  Logout
                </Button>
              </div>
            </div>
          </div>
        </motion.header>

        {/* Main Content */}
        <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="space-y-8">
            {/* Welcome Section */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="text-center"
            >
              <h2 className="text-3xl font-bold text-white mb-2">
                Welcome back, {user?.name?.split(' ')[0]}!
              </h2>
              <p className="text-white/70 text-lg">
                {isAdmin 
                  ? 'Manage users and system settings from your admin dashboard.' 
                  : 'View and manage your account information.'
                }
              </p>
            </motion.div>

            {/* Content Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* Add User Form - Only visible to admins */}
              {isAdmin && (
                <motion.div
                  initial={{ opacity: 0, x: -20 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.5, delay: 0.2 }}
                  className="lg:col-span-1"
                >
                  <AddUserForm onUserAdded={handleUserAdded} />
                </motion.div>
              )}

              {/* Users List */}
              <motion.div
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ duration: 0.5, delay: 0.3 }}
                className={isAdmin ? "lg:col-span-2" : "lg:col-span-3"}
              >
                <UsersList refreshTrigger={refreshTrigger} />
              </motion.div>
            </div>

            {/* Stats Cards - Future enhancement */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5, delay: 0.4 }}
              className="grid grid-cols-1 md:grid-cols-3 gap-6"
            >
              {/* Placeholder for future stats */}
            </motion.div>
          </div>
        </main>
      </div>
    </div>
  )
}