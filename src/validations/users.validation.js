import z from 'zod';

// Validate route param id
export const userIdSchema = z.object({
  id: z
    .string()
    .regex(/^\d+$/, 'id must be a positive integer string')
    .transform((v) => Number(v))
    .refine((n) => Number.isInteger(n) && n > 0, 'id must be a positive integer'),
});

// Fields allowed to be updated by users; 'role' is conditionally permitted (admin only)
export const updateUserSchema = z
  .object({
    name: z.string().min(3).max(255).optional(),
    email: z.string().email().optional(),
    password: z.string().min(6).max(255).optional(),
    role: z.enum(['user', 'admin']).optional(),
  })
  .refine(
    (data) => Object.keys(data).length > 0,
    {
      message: 'At least one field must be provided to update',
      path: ['_'],
    }
  );
