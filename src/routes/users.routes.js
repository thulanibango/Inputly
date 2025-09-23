import express from "express";
import { fetchAllUsers, fetchUserById, createUser, updateUser, deleteUser } from "#controllers/user.controller.js";
import { requireAuth } from "#middleware/auth.middleware.js";

const router = express.Router();

router.get("/", fetchAllUsers);
router.get("/:id", fetchUserById);
router.post("/", requireAuth, createUser);
router.put("/:id", requireAuth, updateUser);
router.delete("/:id", requireAuth, deleteUser);

export default router;
