import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "secret change in production";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1d";

export const jwttoken = {
    sign: (payload) => {
        try {
            return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
        } catch (error) {
            logger.eror(error);
            throw error;
        }
    },
    verify: (token) => {
        try {
            return jwt.verify(token, JWT_SECRET);
        } catch (error) {
            logger.error(error);
            throw error;
        }
    }
}