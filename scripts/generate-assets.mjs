import { readFile, writeFile } from "node:fs/promises";
import sharp from "sharp";

const encoded = (await readFile("assets/logo.png.base64", "utf8")).trim();
const logo = sharp(Buffer.from(encoded, "base64"));
const background = "#080807";
const gold = "#E7C56B";

async function icon(path, size, logoSize, transparent = false) {
  const artwork = await logo.clone().resize(logoSize, logoSize, { fit: "inside" }).png().toBuffer();
  await sharp({
    create: { width: size, height: size, channels: 4, background: transparent ? { r: 0, g: 0, b: 0, alpha: 0 } : background },
  })
    .composite([{ input: artwork, gravity: "center" }])
    .png()
    .toFile(path);
}

await icon("assets/icon-only.png", 1024, 610);
await icon("assets/icon-foreground.png", 1024, 560, true);
await sharp({ create: { width: 1024, height: 1024, channels: 4, background: gold } })
  .png().toFile("assets/icon-background.png");

async function splash(path, dark) {
  const artwork = await logo.clone().resize(440, 440, { fit: "inside" }).png().toBuffer();
  const label = Buffer.from(`<svg width="1000" height="220"><text x="500" y="145" text-anchor="middle" font-family="Arial, sans-serif" font-size="112" font-weight="700" fill="${dark ? gold : background}">LYAMFI</text></svg>`);
  await sharp({ create: { width: 2732, height: 2732, channels: 4, background: dark ? background : gold } })
    .composite([
      { input: artwork, top: 1010, left: 1146 },
      { input: label, top: 1480, left: 866 },
    ])
    .png().toFile(path);
}
await splash("assets/splash.png", true);
await splash("assets/splash-dark.png", true);
console.log("Lyamfi icon and splash sources generated.");
