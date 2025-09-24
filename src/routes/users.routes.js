import express from "express";
import { fetchAllUsers, fetchUserById, createUser, updateUser, deleteUser } from "#controllers/user.controller.js";
import { requireAuth, requireRole } from "#middleware/auth.middleware.js";

const router = express.Router();

router.get("/", requireAuth, requireRole("admin"), fetchAllUsers);
router.get("/:id", requireAuth, requireRole("admin"), fetchUserById);
router.post("/", requireAuth, requireRole("admin"), createUser);
router.put("/:id", requireAuth, requireRole("admin"), updateUser);
router.delete("/:id", requireAuth, requireRole("admin"), deleteUser);

export default router;
