import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Users, Edit, Trash2, Shield, User, Crown, Loader2 } from 'lucide-react'
import { Card, CardHeader, CardTitle, CardContent } from '../ui/card'
import { Button } from '../ui/button'
import { Table, TableHeader, TableBody, TableHead, TableRow, TableCell } from '../ui/table'
import { useAuth } from '../../contexts/AuthContext'
import { api } from '../../lib/utils'

export function UsersList({ refreshTrigger }) {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [deleteLoading, setDeleteLoading] = useState(null)
  
  const { user: currentUser, isAdmin } = useAuth()

  useEffect(() => {
    loadUsers()
  }, [refreshTrigger])

  const loadUsers = async () => {
    try {
      const response = await api.getUsers()
      setUsers(response.data.users)
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  const handleDeleteUser = async (userId, userName) => {
    if (!window.confirm(`Are you sure you want to delete user "${userName}"?`)) {
      return
    }

    setDeleteLoading(userId)
    try {
      await api.deleteUser(userId)
      setUsers(prev => prev.filter(user => user.id !== userId))
    } catch (err) {
      setError(err.message)
    } finally {
      setDeleteLoading(null)
    }
  }

  const getRoleIcon = (role) => {
    switch (role) {
      case 'admin':
        return <Crown className="w-4 h-4 text-yellow-400" />
      case 'user':
        return <User className="w-4 h-4 text-blue-400" />
      default:
        return <Shield className="w-4 h-4 text-gray-400" />
    }
  }

  const getRoleBadge = (role) => {
    const baseClasses = "inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-medium"
    switch (role) {
      case 'admin':
        return `${baseClasses} bg-yellow-500/20 text-yellow-400 border border-yellow-500/30`
      case 'user':
        return `${baseClasses} bg-blue-500/20 text-blue-400 border border-blue-500/30`
      default:
        return `${baseClasses} bg-gray-500/20 text-gray-400 border border-gray-500/30`
    }
  }

  if (loading) {
    return (
      <Card className="w-full">
        <CardContent className="flex items-center justify-center py-8">
          <Loader2 className="w-6 h-6 animate-spin text-black/60" />
          <span className="ml-2 text-black/60">Loading users...</span>
        </CardContent>
      </Card>
    )
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.5, delay: 0.2 }}
      className="w-full"
    >
      <Card className="w-full">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="w-5 h-5" />
            Recently Added Users ({users.length})
          </CardTitle>
        </CardHeader>
        <CardContent>
          {error && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="text-red-400 text-sm bg-red-500/10 border border-red-500/20 rounded-lg p-3 mb-4"
            >
              {error}
            </motion.div>
          )}

          {users.length === 0 ? (
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center py-8 text-black/60"
            >
              <Users className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>No users found</p>
            </motion.div>
          ) : (
            <div className="rounded-lg overflow-hidden glass-card">
              <Table>
                <TableHeader>
                  <TableRow className="border-black/10">
                    <TableHead>Name</TableHead>
                    <TableHead>Email</TableHead>
                    <TableHead>Role</TableHead>
                    <TableHead>Joined</TableHead>
                    {isAdmin && <TableHead className="text-right">Actions</TableHead>}
                  </TableRow>
                </TableHeader>
                <TableBody>
                  <AnimatePresence>
                    {users.map((user, index) => (
                      <motion.tr
                        key={user.id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        exit={{ opacity: 0, x: 20 }}
                        transition={{ duration: 0.3, delay: index * 0.1 }}
                        className="border-black/10 hover:bg-black/5"
                      >
                        <TableCell className="font-medium">
                          <div className="flex items-center gap-2">
                            <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 flex items-center justify-center text-black text-sm font-medium">
                              {user.name.charAt(0).toUpperCase()}
                            </div>
                            {user.name}
                          </div>
                        </TableCell>
                        <TableCell>{user.email}</TableCell>
                        <TableCell>
                          <span className={getRoleBadge(user.role)}>
                            {getRoleIcon(user.role)}
                            {user.role.charAt(0).toUpperCase() + user.role.slice(1)}
                          </span>
                        </TableCell>
                        <TableCell className="text-black/60">
                          {new Date(user.createdAt).toLocaleDateString()}
                        </TableCell>
                        {isAdmin && (
                          <TableCell className="text-right">
                            <div className="flex items-center justify-end gap-2">
                              <Button
                                variant="ghost"
                                size="icon"
                                className="h-8 w-8 text-black/60 hover:text-black hover:bg-black/10"
                                onClick={() => {
                                  // TODO: Implement edit functionality
                                  alert('Edit functionality to be implemented')
                                }}
                              >
                                <Edit className="w-4 h-4" />
                              </Button>
                              {user.id !== currentUser?.id && (
                                <Button
                                  variant="ghost"
                                  size="icon"
                                  className="h-8 w-8 text-black/60 hover:text-red-400 hover:bg-red-500/10"
                                  onClick={() => handleDeleteUser(user.id, user.name)}
                                  disabled={deleteLoading === user.id}
                                >
                                  {deleteLoading === user.id ? (
                                    <Loader2 className="w-4 h-4 animate-spin" />
                                  ) : (
                                    <Trash2 className="w-4 h-4" />
                                  )}
                                </Button>
                              )}
                            </div>
                          </TableCell>
                        )}
                      </motion.tr>
                    ))}
                  </AnimatePresence>
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>
    </motion.div>
  )
}