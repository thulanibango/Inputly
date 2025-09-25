import logger from '#config/logger.js';
import {
  getAllUsers as getAllUsersService,
  getUserById as getUserByIdService,
  createUser as createUserService,
  updateUser as updateUserService,
  deleteUser as deleteUserService,
} from '#services/users.service.js';
import { userIdSchema, updateUserSchema } from '#validations/users.validation.js';
export const fetchAllUsers = async (req, res, next) => {
  try {
    const users = await getAllUsersService();
    res.status(200).json({
      status: 'success',
      message: 'Users fetched successfully',
      data: users
    });
  } catch (error) {
    logger.error('Error fetching users:', error);
    next(error);
  }
};
export const fetchUserById = async (req, res, next) => {
  try {
    const { id } = userIdSchema.parse(req.params);
    const user = await getUserByIdService(id);
    if (!user) {
      return res.status(404).json({ status: 'fail', message: 'User not found' });
    }
    res.status(200).json({
      status: 'success',
      message: 'User fetched successfully',
      data: user
    });
  } catch (error) {
    logger.error('Error fetching user by ID:', error);
    next(error);
  }
};
export const createUser = async (req, res, next) => {
  try {
    const user = await createUserService(req.body);
    res.status(201).json({
      status: 'success',
      message: 'User created successfully',
      data: user
    });
  } catch (error) {
    logger.error('Error creating user:', error);
    next(error);
  }
};
export const updateUser = async (req, res, next) => {
  try {
    const { id } = userIdSchema.parse(req.params);
    const updates = updateUserSchema.parse(req.body);

    const requester = req.user;
    if (!requester) {
      return res.status(401).json({ status: 'fail', message: 'Unauthorized' });
    }

    const isSelf = Number(requester.id) === Number(id);
    const isAdmin = requester.role === 'admin';

    if (!isSelf && !isAdmin) {
      return res.status(403).json({ status: 'fail', message: 'Forbidden: cannot update other users' });
    }

    if (!isAdmin && Object.prototype.hasOwnProperty.call(updates, 'role')) {
      return res.status(403).json({ status: 'fail', message: 'Forbidden: only admin can change role' });
    }

    const user = await updateUserService(id, updates);
    res.status(200).json({
      status: 'success',
      message: 'User updated successfully',
      data: user
    });
  } catch (error) {
    logger.error('Error updating user:', error);
    next(error);
  }
};
export const deleteUser = async (req, res, next) => {
  try {
    const { id } = userIdSchema.parse(req.params);

    const requester = req.user;
    if (!requester) {
      return res.status(401).json({ status: 'fail', message: 'Unauthorized' });
    }

    const isSelf = Number(requester.id) === Number(id);
    const isAdmin = requester.role === 'admin';

    if (!isSelf && !isAdmin) {
      return res.status(403).json({ status: 'fail', message: 'Forbidden: cannot delete other users' });
    }

    const user = await deleteUserService(id);
    res.status(200).json({
      status: 'success',
      message: 'User deleted successfully',
      data: user
    });
  } catch (error) {
    logger.error('Error deleting user:', error);
    next(error);
  }
};
