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