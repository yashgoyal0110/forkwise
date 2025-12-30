import { Router } from "express";
import authRoutes from "../modules/auth.routes";
import menuRoutes from "../modules/menu.routes";
import profileRoutes from "../modules/profile.routes";
import favoritesRoutes from "../modules/favorites.routes";
import intakeRoutes from "../modules/intake.routes";

const router = Router();

router.get("/health", (_req, res) => {
  res.json({ status: "ok", uptime: process.uptime() });
});

router.use("/auth", authRoutes);
router.use("/menu", menuRoutes);
router.use("/profile", profileRoutes);
router.use("/favorites", favoritesRoutes);
router.use("/intake", intakeRoutes);

export default router;
