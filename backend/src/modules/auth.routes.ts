import { Router } from "express";
import { prisma } from "../lib/prisma";
import { asyncHandler } from "../lib/asyncHandler";
import { conflict, unauthorized, notFound } from "../lib/errors";
import { hashPassword, verifyPassword } from "../lib/password";
import { signToken } from "../lib/jwt";
import { serializeUser } from "../lib/serializers";
import { validateBody } from "../middleware/validate";
import { requireAuth } from "../middleware/auth";
import { authLimiter } from "../middleware/rateLimit";
import { signupSchema, loginSchema } from "../validators/schemas";

const router = Router();

/** POST /auth/signup - create an account (+ default profile) and return a token. */
router.post(
  "/signup",
  authLimiter,
  validateBody(signupSchema),
  asyncHandler(async (req, res) => {
    const { email, password, name } = req.body;

    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw conflict("An account with that email already exists");

    const user = await prisma.user.create({
      data: {
        email,
        name: name ?? null,
        passwordHash: await hashPassword(password),
        profile: { create: {} }, // sensible defaults from the schema
      },
      include: { profile: true },
    });

    res.status(201).json({ token: signToken(user.id), user: serializeUser(user, user.profile) });
  })
);

/** POST /auth/login - exchange credentials for a token. */
router.post(
  "/login",
  authLimiter,
  validateBody(loginSchema),
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    const user = await prisma.user.findUnique({ where: { email }, include: { profile: true } });
    // Same error whether the email is unknown or the password is wrong - don't
    // leak which accounts exist.
    if (!user || !(await verifyPassword(password, user.passwordHash))) {
      throw unauthorized("Invalid email or password");
    }

    res.json({ token: signToken(user.id), user: serializeUser(user, user.profile) });
  })
);

/** GET /auth/me - the current user and their profile. */
router.get(
  "/me",
  requireAuth,
  asyncHandler(async (req, res) => {
    const user = await prisma.user.findUnique({
      where: { id: req.userId! },
      include: { profile: true },
    });
    if (!user) throw notFound("User not found");
    res.json({ user: serializeUser(user, user.profile) });
  })
);

export default router;
