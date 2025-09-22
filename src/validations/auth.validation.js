import z from "zod";

export const registerSchema = z.object({
    name: z.string().min(3, "Name must be at least 3 characters long").max(30, "Name must be at most 30 characters long"),
    email: z.string().email("Invalid email address"),
    password: z.string().min(6, "Password must be at least 8 characters long").max(30, "Password must be at most 30 characters long"),
    role: z.enum(["user", "admin"]),
});

export const loginSchema = z.object({
    email: z.string().email("Invalid email address"),
    password: z.string().min(6, "Password must be at least 8 characters long").max(30, "Password must be at most 30 characters long"),
});


