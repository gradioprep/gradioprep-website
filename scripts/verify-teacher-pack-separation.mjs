import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const assetDirectory = "dist/assets";
const assets = readdirSync(assetDirectory)
  .filter((name) => name.endsWith(".js"))
  .map((name) => join(assetDirectory, name));

if (assets.length === 0) {
  throw new Error("No built JavaScript assets found; client bundle check cannot run.");
}

const teacherOnlyMarkers = [
  "Correct. It combines the blurred comparison with the surrounding description of dense fog",
  "draft-lesson-how-writers-shape-meaning-v3",
  "qualityBands",
];

for (const asset of assets) {
  const content = readFileSync(asset, "utf8");
  for (const marker of teacherOnlyMarkers) {
    if (content.includes(marker)) {
      throw new Error(`Teacher-only content marker found in public client asset: ${marker}`);
    }
  }
}

console.log(`Teacher-pack separation verified across ${assets.length} browser JavaScript asset(s).`);
