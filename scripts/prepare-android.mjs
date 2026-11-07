import { cp, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";

if (!existsSync("android/app")) {
  throw new Error("Run `npx cap add android` before preparing the Android overlay.");
}
await mkdir("android/app/src/main", { recursive: true });
await cp("native/android/app/src/main", "android/app/src/main", { recursive: true, force: true });
console.log("Android native shell and six widget providers installed.");
