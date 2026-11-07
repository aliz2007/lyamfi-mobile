import { cp, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { spawnSync } from "node:child_process";

if (!existsSync("ios/App/App.xcodeproj")) {
  throw new Error("Run `npx cap add ios` before preparing the iOS overlay.");
}
await cp("native/ios/App/App", "ios/App/App", { recursive: true, force: true });
await cp("native/ios/App/LyamfiWidgets", "ios/App/LyamfiWidgets", { recursive: true, force: true });

const plistPath = "ios/App/App/Info.plist";
let plist = await readFile(plistPath, "utf8");
if (!plist.includes("ITSAppUsesNonExemptEncryption")) {
  plist = plist.replace(/<dict>\s*/, `<dict>\n\t<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>\n\t<key>UIBackgroundModes</key>\n\t<array><string>remote-notification</string></array>\n`);
  await writeFile(plistPath, plist);
}
const result = spawnSync("ruby", ["scripts/add-ios-widgets.rb"], { stdio: "inherit" });
if (result.status !== 0) throw new Error("Could not add the LyamfiWidgets target to Xcode.");
