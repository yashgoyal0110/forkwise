import type { RequestHandler } from "express";
import type { ZodSchema } from "zod";

/**
 * Validates and coerces `req.body` against a Zod schema before the handler runs.
 * On success the parsed (typed, defaulted) data replaces `req.body`; on failure
 * the ZodError is forwarded to the error middleware, which returns a 400 with
 * field-level details.
 */
export const validateBody =
  (schema: ZodSchema): RequestHandler =>
  (req, _res, next) => {
    const result = schema.safeParse(req.body);
    if (!result.success) return next(result.error);
    req.body = result.data;
    next();
  };
