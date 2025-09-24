import { db } from '#config/database.js';
import { users } from '#models/user.model.js';
import { eq, desc } from 'drizzle-orm';
import logger from '#config/logger.js';

export const getAllUsers = async () => {
  try {
    const rows = await db
      .select({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      })
      .from(users)
      .orderBy(desc(users.createdAt))
      .limit(5);
    return rows;
  } catch (error) {
    logger.error('Error fetching users:', error);
    throw error;
  }
};

export const getUserById = async (id) => {
  try {
    const rows = await db
      .select({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      })
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    return rows[0] || null;
  } catch (error) {
    logger.error('Error fetching user by ID:', error);
    throw error;
  }
};

export const createUser = async (user) => {
  try {
    const [inserted] = await db
      .insert(users)
      .values(user)
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      });
    return inserted;
  } catch (error) {
    logger.error('Error creating user:', error);
    throw error;
  }
};

export const updateUser = async (id, updates) => {
  try {
    const existing = await db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    if (existing.length === 0) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    const [updated] = await db
      .update(users)
      .set(updates)
      .where(eq(users.id, id))
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      });
    return updated;
  } catch (error) {
    logger.error('Error updating user:', error);
    throw error;
  }
};

export const deleteUser = async (id) => {
  try {
    const existing = await db
      .select({ id: users.id })
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    if (existing.length === 0) {
      const err = new Error('User not found');
      err.status = 404;
      throw err;
    }

    const [deleted] = await db
      .delete(users)
      .where(eq(users.id, id))
      .returning({
        id: users.id,
        name: users.name,
        email: users.email,
        role: users.role,
        createdAt: users.createdAt,
        updatedAt: users.updatedAt,
      });
    return deleted;
  } catch (error) {
    logger.error('Error deleting user:', error);
    throw error;
  }
};