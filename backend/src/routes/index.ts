import { Router } from "express";
import authRoutes from "../modules/auth.routes";
import menuRoutes from "../modules/menu.routes";
import profileRoutes from "../modules/profile.routes";
import favoritesRoutes from "../modules/favorites.routes";
import intakeRoutes from "../modules/intake.routes";

const routerList = Router();

routerList.get("/health", (_req, res) => {
  res.json({ status: "ok", uptime: process.uptime() });
});

routerList.use("/auth", authRoutes);
routerList.use("/menu", menuRoutes);
routerList.use("/profile", profileRoutes);
routerList.use("/favorites", favoritesRoutes);
routerList.use("/intake", intakeRoutes);

export default routerList;
