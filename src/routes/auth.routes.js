import express from "express";
import { registerController } from "#controllers/auth.controller.js";
const router = express.Router();


router.post('/register', registerController);

router.post("/login", (req, res) => {
    res.send("Login").status(200);
});

router.post("/logout", (req, res) => {
    res.send("Logout").status(200);
});

export default router;
