import type { RequestHandler } from "express";

/**
 * Wraps an async route handler so a rejected promise is forwarded to Express's
 * error middleware instead of crashing the process. Lets handlers simply
 * `throw` and rely on the central error handler.
 */
export const asyncHandler =
  (fn: RequestHandler): RequestHandler =>
  (req, res, next) =>
    Promise.resolve(fn(req, res, next)).catch(next);
