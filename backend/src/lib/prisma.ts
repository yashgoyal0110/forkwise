import { PrismaClient } from "@prisma/client";

/**
 * A single shared PrismaClient. In dev we stash it on `globalThis` so hot-reload
 * (tsx watch) doesn't open a new connection pool on every file change.
 */
const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") {
  globalForPrisma.prisma = prisma;
}
