import { describe, it, expect } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";

// These tests exercise routing, validation and error-shaping WITHOUT touching
// the database, so they run in CI with no Postgres/SQLite setup. (Full
// integration tests against a throwaway test DB are a natural next step.)
const app = createApp();

describe("Forkwise API", () => {
  it("reports health", async () => {
    const res = await request(app).get("/api/v1/health");
    expect(res.status).toBe(200);
    expect(res.body.status).toBe("ok");
  });

    it("returns a 404 with a consistent error shape for unknown routes", async () => {
        const res = await request(app).get("/api/v1/does-not-exist");
        expect(res.status).toBe(404);
        expect(res.body.error.code).toBe("NOT_FOUND");
    });

    it("rejects signup with an invalid body (400 + validation details)", async () => {
        const res = await request(app)
            .post("/api/v1/auth/signup")
            .send({ email: "not-an-email", password: "short" });
        expect(res.status).toBe(400);
        expect(res.body.error.code).toBe("VALIDATION_ERROR");
    });

    it("requires a bearer token on protected routes", async () => {
        const res = await request(app).get("/api/v1/profile");
        expect(res.status).toBe(401);
        expect(res.body.error.code).toBe("UNAUTHORIZED");
    });
});
