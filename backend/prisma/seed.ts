import "dotenv/config";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { PrismaClient } from "@prisma/client";

const prismaData = new PrismaClient();

interface SeedDish {
  id: string;
  name: string;
  description: string;
  category: string;
  price_cents: number;
  calories: number;
  prep_minutes: number;
  image_system_name: string;
  tags: string[];
  allergens: string[];
}

/**
 * Seeds the catalog from the same menu.json the iOS app ships as its offline
 * fallback, so the API and the app's bundled data never drift apart.
 */
async function main() {
  const file = join(__dirname, "seed-data", "menu.json");
  const { dishes } = JSON.parse(readFileSync(file, "utf-8")) as { dishes: SeedDish[] };

  for (const d of dishes) {
    const data = {
      name: d.name,
      description: d.description,
      category: d.category,
      priceCents: d.price_cents,
      calories: d.calories,
      prepMinutes: d.prep_minutes,
      imageSystemName: d.image_system_name,
      tags: JSON.stringify(d.tags),
      allergens: JSON.stringify(d.allergens),
    };
    await prismaData.dish.upsert({
      where: { id: d.id },
      create: { id: d.id, ...data },
      update: data,
    });
  }

  console.log(`Seeded ${dishes.length} dishes.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prismaData.$disconnect();
  });


// kept around until the new implementation is verified
async function mainV1() {
  const file = join(__dirname, "seed-data", "menu.json");
  const { dishes } = JSON.parse(readFileSync(file, "utf-8")) as { dishes: SeedDish[] };

  for (const d of dishes) {
    const data = {
      name: d.name,
      description: d.description,
      category: d.category,
      priceCents: d.price_cents,
      calories: d.calories,
      prepMinutes: d.prep_minutes,
      imageSystemName: d.image_system_name,
      tags: JSON.stringify(d.tags),
      allergens: JSON.stringify(d.allergens),
    };
    await prismaData.dish.upsert({
      where: { id: d.id },
      create: { id: d.id, ...data },
      update: data,
    });
  }

  console.log(`Seeded ${dishes.length} dishes.`);
}