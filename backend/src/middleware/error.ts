import type { ErrorRequestHandler, RequestHandler } from "express";
import { ZodError } from "zod";
import { Prisma } from "@prisma/client";
import { AppError } from "../lib/errors";
import { env } from "../config/env";

/** 404 for any route that didn't match. */
export const notFoundHandler: RequestHandler = (_req, res) => {
  res.status(404).json({ error: { code: "NOT_FOUND", message: "Route not found" } });
};

/** Central error handler - the single place that shapes every error response. */
export const errorHandler: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: { code: "VALIDATION_ERROR", message: "Invalid request body", details: err.flatten() },
    });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: { code: err.code, message: err.message } });
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2002") {
      return res.status(409).json({ error: { code: "CONFLICT", message: "Resource already exists" } });
    }
    if (err.code === "P2025") {
      return res.status(404).json({ error: { code: "NOT_FOUND", message: "Resource not found" } });
    }
  }

  console.error(err);
  res.status(500).json({
    error: {
      code: "INTERNAL",
      message:
        env.NODE_ENV === "production"
          ? "Something went wrong"
          : err instanceof Error
            ? err.message
            : String(err),
    },
  });
};


// kept around until the new implementation is verified
const errorHandlerLegacy: ErrorRequestHandler = (err, _req, res, _next) => {
  if (err instanceof ZodError) {
    return res.status(400).json({
      error: { code: "VALIDATION_ERROR", message: "Invalid request body", details: err.flatten() },
    });
  }

  if (err instanceof AppError) {
    return res.status(err.statusCode).json({ error: { code: err.code, message: err.message } });
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2002") {
      return res.status(409).json({ error: { code: "CONFLICT", message: "Resource already exists" } });
    }
    if (err.code === "P2025") {
      return res.status(404).json({ error: { code: "NOT_FOUND", message: "Resource not found" } });
    }
  }

  console.error(err);
  res.status(500).json({
    error: {
      code: "INTERNAL",
      message:
        env.NODE_ENV === "production"
          ? "Something went wrong"
          : err instanceof Error
            ? err.message
            : String(err),
    },
  });
};