import logger from '#config/logger.js';
import { formatValidationErrors } from '#utils/format.js';
import { registerSchema } from '#validations/auth.validation.js';
import { createUser } from '#services/auth.service.js';
import { jwttoken } from '#utils/jwt.js';
import { cookies } from '#utils/cookies.js';

export const registerController = async (req, res, next) => {
    try {
        const validationResult = registerSchema.safeParse(req.body);
        if (!validationResult.success) {
            const error = new Error(formatValidationErrors(validationResult.error));
            error.status = 400;
            throw error;
        }
        const { name, email, role, password } = validationResult.data;
        const user = await createUser({ name, email, password, role });
        const token = jwttoken.sign({ id: user.id, email: user.email, role: user.role, name: user.name });
        cookies.set(res, "token", token);

        logger.info("Register controller", { name, email, role });
        res.status(201).json({
            message: "User registered successfully",
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                createdAt: user.createdAt
            }
        });

    } catch (error) {
        logger.error("Register controller error", error);
        if (error.message === "User already exists") {
            return res.status(409).json({ message: error.message });
        }
        next(error);
    }
};