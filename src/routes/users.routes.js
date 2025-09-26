import express from 'express';
import { fetchAllUsers, fetchUserById, createUser, updateUser, deleteUser } from '#controllers/user.controller.js';
import { requireAuth, requireRole } from '#middleware/auth.middleware.js';

const router = express.Router();

// Current user profile endpoint - must come before /:id to avoid conflict
router.get('/me', requireAuth, (req, res) => {
  res.json({
    message: 'User profile retrieved successfully',
    user: {
      id: req.user.id,
      name: req.user.name,
      email: req.user.email,
      role: req.user.role,
      createdAt: req.user.createdAt
    }
  });
});

router.get('/', requireAuth, requireRole('admin'), fetchAllUsers);
router.get('/:id', requireAuth, requireRole('admin'), fetchUserById);
router.post('/', requireAuth, requireRole('admin'), createUser);
router.put('/:id', requireAuth, requireRole('admin'), updateUser);
router.delete('/:id', requireAuth, requireRole('admin'), deleteUser);

export default router;
