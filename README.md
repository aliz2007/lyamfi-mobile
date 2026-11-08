# Lyamfi Mobile

The App Store / Google Play package for **Lyamfi**, built around the live product at
https://lyamfi.com.

## What this package contains

- Native **iPhone and Android** app shells (`com.lyamfi.app`).
- The complete Lyamfi website inside the app: accounts, portfolios, leagues,
  lessons, news, simulators and live prices.
- **Automatic product updates:** the app loads the live site, so a Lovable
  publication reaches app users without another App Store submission.
- **Six home-screen widget types on each platform:**
  1. MASI and MASI 20
  2. Top market movers
  3. Four-stock Lyamfi watchlist
  4. Casablanca market open/closed status
  5. Daily investing lesson
  6. Quick shortcuts to Bourse, Portefeuille, Académie and Actualités
- **iPhone lock-screen widgets** for market status (circular and rectangular).
- Native deep links (`lyamfi://…`), universal-link configuration, branded icon
  and splash assets, release metadata and privacy policy.
- Push-notification native scaffolding and the `market_alerts` Android channel.
- Ready-to-enable unsigned Android and iOS release builds through GitHub Actions.

Widgets intentionally read **public market data only**. They never copy login
sessions, portfolio balances or league information onto the home screen.

## Build the package without a terminal

1. On GitHub, copy `ci/mobile-build.yml` to `.github/workflows/mobile-build.yml` (the connected integration did not have permission to create workflow files).
2. Open **Actions → Mobile package → Run workflow**.
3. When the run finishes, download:
   - `lyamfi-android-unsigned` (release APK + AAB)
   - `lyamfi-ios-unsigned-archive` (Xcode archive)

These artifacts are **unsigned** by design. Apple and Google require the owner's
private signing identities; no certificate belongs in a public repository.

## What is required before store submission

1. Apple Developer ($99/year) and Google Play ($25 one-time) accounts.
2. Add the Apple development team and distribution certificate in Xcode, then
   upload the archive through **Distribute App → App Store Connect**.
3. Add the Android release keystore in a secure signing workflow, then upload
   the signed AAB to Play Console. Keep the keystore and passwords outside git.
4. To activate push delivery, create the APNs key and Firebase project, then add
   `GoogleService-Info.plist` / `google-services.json` as CI secrets. The native
   registration and channel code is already present; credentials are not.
5. Replace `TEAM_ID` and `REPLACE_WITH_RELEASE_SIGNING_SHA256` in
   `web-association/.well-known/`, publish those two files at the same path on
   `lyamfi.com`, and universal links will open directly in the app.
   Custom `lyamfi://` links and widget taps already work without this step.
6. Add store screenshots and a dedicated demo account for App Review. Listing
   copy and reviewer notes are ready in `store/metadata/`.

## Store review positioning

This is not a bare web wrapper. In addition to the complete product it provides
six native widget families, lock-screen complications, native notifications and
deep links. That native functionality is the answer to App Review guideline 4.2
(minimum functionality). Web content updates are automatic; only changes to the
native shell, icon, permissions or plugins require a new store binary.

## Developer commands

The owner never needs these; they are for local development and CI.

```bash
npm install
npm test
npx tsc --noEmit

# Android (requires Android SDK)
npm run build:android

# iOS project and unsigned archive (requires macOS, Xcode and CocoaPods)
gem install xcodeproj
npm run build:ios
xcodebuild -workspace ios/App/App.xcworkspace -scheme App \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath build/Lyamfi.xcarchive CODE_SIGNING_ALLOWED=NO archive
```

Generated `android/` and `ios/` trees are deliberately ignored. The source of
truth is `capacitor.config.ts` plus `native/` and `scripts/`, so updates to
Capacitor never leave hundreds of generated files in review.

## Data and security

- HTTPS only; no cleartext traffic or mixed content.
- Route allow-list for native deep links; arbitrary URLs cannot become app routes.
- No analytics SDK, ad SDK, cross-app tracking or in-app purchase.
- No signing keys, Supabase service-role key or account token in this repository.
- Widget quotes come from the same public TradingView scanner used by the site;
  the service can change independently and widgets show a graceful fallback.
