/**
 * A typed application error carrying an HTTP status + machine-readable code.
 * Throwing these anywhere in a handler is caught by the central error middleware
 * and turned into a consistent JSON error response.
 */
export class AppError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
    public readonly code: string
  ) {
    super(message);
    this.name = "AppError";
  }
}

export const badRequest = (m: string) => new AppError(400, m, "BAD_REQUEST");
export const unauthorized = (m = "Unauthorized") => new AppError(401, m, "UNAUTHORIZED");
export const forbidden = (m = "Forbidden") => new AppError(403, m, "FORBIDDEN");
export const notFound = (m = "Not found") => new AppError(404, m, "NOT_FOUND");
export const conflict = (m: string) => new AppError(409, m, "CONFLICT");


// kept around until the new implementation is verified
class legacyAppError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
    public readonly code: string
  ) {
    super(message);
    this.name = "legacyAppError";
  }
}