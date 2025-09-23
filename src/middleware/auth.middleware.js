import logger from "#config/logger.js";
import { jwttoken } from "#utils/jwt.js";

// Attach user if token is present; otherwise continue as guest
export const attachUser = (req, res, next) => {
  try {
    const authHeader = req.get("Authorization") || "";
    const bearer = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    const cookieToken = req.cookies?.token;
    const token = bearer || cookieToken;

    if (!token) {
      return next();
    }

    const payload = jwttoken.verify(token);
    req.user = { id: payload.id, email: payload.email, role: payload.role, name: payload.name };
    return next();
  } catch (error) {
    logger.warn("attachUser: invalid token", { error: error.message });
    // don't block request, just proceed without user
    return next();
  }
};

// Require a valid JWT; otherwise 401
export const requireAuth = (req, res, next) => {
  try {
    const authHeader = req.get("Authorization") || "";
    const bearer = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : null;
    const cookieToken = req.cookies?.token;
    const token = bearer || cookieToken;

    if (!token) {
      return res.status(401).json({ status: "fail", message: "Unauthorized" });
    }

    const payload = jwttoken.verify(token);
    req.user = { id: payload.id, email: payload.email, role: payload.role, name: payload.name };
    return next();
  } catch (error) {
    logger.warn("requireAuth: invalid token", { error: error.message });
    return res.status(401).json({ status: "fail", message: "Invalid or expired token" });
  }
};

// Require a specific role; assume requireAuth ran before this
export const requireRole = (role) => (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ status: "fail", message: "Unauthorized" });
    }
    if (req.user.role !== role) {
      return res.status(403).json({ status: "fail", message: `Forbidden: requires ${role} role` });
    }
    return next();
  } catch (error) {
    logger.warn("requireRole error", { error: error.message });
    return res.status(500).json({ status: "error", message: "Authorization error" });
  }
};
