import bcrypt from "bcrypt";
import logger from "#config/logger.js";
import { eq } from "drizzle-orm";
import { db } from "#config/database.js";
import { users } from "#models/user.model.js";

export const hashPassword = async (password) => {
    try {
        return await bcrypt.hash(password, 10);

    } catch (error) {
        logger.error("Hash password error", error);
        throw error;

    }
}

export const createUser = async ({ name, email, password, role }) => {
    try {
        const existingUsers = await db
            .select()
            .from(users)
            .where(eq(users.email, email))
            .limit(1);
        if (existingUsers.length > 0) {
            throw new Error("User already exists");
        }
        const hashedPassword = await hashPassword(password);
        const inserted = await db
            .insert(users)
            .values({ name, email, password: hashedPassword, role })
            .returning({ id: users.id, name: users.name, email: users.email, role: users.role, createdAt: users.createdAt });
        const newUser = inserted[0];
        logger.info("User created successfully", { id: newUser.id, email: newUser.email, role: newUser.role });
        return newUser;
    } catch (error) {
        logger.error("Create user error", error);
        throw error;
    }
}

export const findUserByEmail = async (email) => {
    try {
        const results = await db
            .select({ id: users.id, name: users.name, email: users.email, role: users.role, password: users.password, createdAt: users.createdAt })
            .from(users)
            .where(eq(users.email, email))
            .limit(1);
        return results[0] || null;
    } catch (error) {
        logger.error("Find user by email error", error);
        throw error;
    }
}

export const authenticateUser = async ({ email, password }) => {
    try {
        const user = await findUserByEmail(email);
        if (!user) {
            const err = new Error("Invalid credentials");
            err.status = 401;
            throw err;
        }
        const match = await bcrypt.compare(password, user.password);
        if (!match) {
            const err = new Error("Invalid credentials");
            err.status = 401;
            throw err;
        }
        const { password: _pw, ...safeUser } = user;
        return safeUser;
    } catch (error) {
        logger.error("Authenticate user error", error);
        throw error;
    }
}