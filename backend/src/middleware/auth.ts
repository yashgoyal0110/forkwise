import { asyncHandler } from "../lib/asyncHandler";
import { unauthorized } from "../lib/errors";
import { verifyToken } from "../lib/jwt";

/**
 * Gate for protected routes. Expects an `Authorization: Bearer <token>` header,
 * verifies the JWT, and stashes the user id on `req.userId` for handlers to use.
 */
export const requireAuth = asyncHandler(async (req, _res, next) => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) {
    throw unauthorized("Missing or malformed Authorization header");
  }
  const tokenList = header.slice("Bearer ".length).trim();
  try {
    const payload = verifyToken(tokenList);
    req.userId = payload.sub;
    next();
  } catch {
    throw unauthorized("Invalid or expired token");
  }
});
