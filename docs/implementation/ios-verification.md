# Desktop integration and native verification — 2026-10-24

Active working copy: `/Users/skeebkhan/Desktop/Mogul Club`.
Open the root `Mogul Club.xcodeproj`; scheme `Mogul Club`; iPhone 15 simulator with iOS 17.5.

## Integration

- Preserved the original Desktop bundle ID and development signing team.
- Preserved the original Hello World source and template test files on disk, excluded from target compilation.
- Imported the authored monorepo, API, admin, contracts, configuration and documentation without copying node_modules, build artifacts, secrets or the source repository's Git directory.
- Root Desktop project compiles shared native sources in `apps/ios/MogulClub` and tests in `apps/ios/MogulClubTests` / `MogulClubUITests`.
- Added shared Desktop scheme and updated CI to build/test that scheme. CI now starts the synthetic API before the native network test; GitHub Actions has not been executed here.
- Original Documents copy remains an earlier snapshot. Backups of the original Desktop project and starter source are under the Documents copy's ignored `.test-results/desktop-original/`.

## Actual results

Environment: Xcode 15.4 (15F31d), iOS 17.5, iPhone 15 simulator.

| Check | Result |
|---|---|
| Original native shell simulator build | Exit 0 |
| Integrated Desktop app simulator build | Exit 0 |
| Native unit tests | 5 passed, 0 failed |
| Final UI test run | Exit 0; 2 passed, 0 failed |
| API property list | HTTP 200; two seeded synthetic properties |
| App install / launch | `simctl` installed and launched `Mogul.Mogul-Club` |
| ESLint after adding demo startup script | Exit 0 |
| Xcode project plist validation | Exit 0 |

Unit tests cover demo response decoding, HTTP rejection, non-demo response rejection, empty view-model state and offline state. UI tests cover loading Magnolia House from the real local API, opening its detail screen and returning; plus welcome and Portfolio/Documents/Account tab navigation.

These results came from separate native test runs: five unit cases passed in `desktop-final-tests.log`, and both UI cases passed in the final `desktop-ui-passing.log`. The earlier combined run failed only the subsequently corrected account-heading assertion; it is retained as failure evidence. Result bundles and logs remain in ignored `.test-results/`.

## Commands

```sh
pnpm install --frozen-lockfile
pnpm --filter @mogul/contracts build
pnpm --filter @mogul/api build
node scripts/demo-api.mjs
xcodebuild -project 'Mogul Club.xcodeproj' -scheme 'Mogul Club' -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -derivedDataPath apps/ios/SimulatorBuild CODE_SIGNING_ALLOWED=NO build
xcodebuild -project 'Mogul Club.xcodeproj' -scheme 'Mogul Club' -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -derivedDataPath apps/ios/SimulatorBuild -only-testing:'Mogul ClubTests' CODE_SIGNING_ALLOWED=NO test
xcodebuild -project 'Mogul Club.xcodeproj' -scheme 'Mogul Club' -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.5' -derivedDataPath apps/ios/SimulatorBuild -only-testing:'Mogul ClubUITests' CODE_SIGNING_ALLOWED=NO test
```

The demo server was run with the installed Node 22.23.4 executable on PATH. The initial dependency install used this shell's Node 22.12 and emitted an engine warning; no install failure occurred. Use `nvm use` in this root to select `.nvmrc` before future runs.

## Failures resolved

- Explicit simulator architecture selection led Xcode 15.4 to choose the Mac for a test attempt (exit 70). A named iPhone 15/iOS 17.5 destination without an architecture constraint ran successfully.
- Welcome UI testing used a UserDefaults argument-domain override, preventing state changes after tapping Explore. Replaced it with Debug-only launch hooks that reset ordinary persisted state.
- Case-sensitive Section heading assertions did not match native accessibility capitalization. Corrected selectors and allowed the asynchronously loaded detail section time to appear.
- Isolated detail loading to the main actor to remove the concurrency warnings found during compilation.

## Runtime and remaining limits

The local demo API runs on port 3001 with a real MongoDB 8.0.15 process. Synthetic records persist in ignored `.local-demo/mongodb`. PostgreSQL/Redis are not started by this lightweight command; overall readiness remains degraded while the discovery endpoints work. Stop the demo with Control-C; restart from this folder using `pnpm dev:demo`.

The app is open in Simulator on Discover. No real funds, authentication, ownership, distributions or live offerings are enabled. Docker/container validation, device testing, manual accessibility assessment, production security/legal gates and App Store distribution remain incomplete. See the roadmap and original verification report for the wider platform scope; this native verification supersedes their earlier missing-Xcode blocker only.


## Logo integration — October 24, 2026

Updated the authoritative Desktop project with the three user-supplied logo originals in `Mogul Club/Assets.xcassets`. Added the reusable, appearance-aware `MogulLogo` in `Core/DesignSystem.swift`; welcome and Discover now display the horizontal logo, and Account displays the stacked logo with an explicit Demo guest label. Logo canvas blends with the native background. Sources, dimensions and limitations are documented in `brand-assets.md`. No API, signing, bundle identifier or Documents changes.

Actual verification on iPhone 15 / iOS 17.5:

- Standalone simulator build: exit 0, BUILD SUCCEEDED (`.test-results/logo-build.log`).
- Final build-and-test after the background blending adjustment: exit 0, TEST SUCCEEDED; 5 unit tests and 2 UI tests passed, zero failures (`.test-results/logo-verified.log`, `logo-verified.xcresult`).
- Earlier combined run: UI tests passed but unit-test startup was killed, potentially by concurrent manual simulator checks (`logo-tests.log`). An uninterrupted rerun passed all seven tests (`logo-tests-final.log`); the final visual adjustment was then verified again as above.
- Welcome visually checked in light and dark appearance; Discover checked with API-loaded properties. Screenshots: `logo-welcome.png`, `logo-welcome-dark.png`, `logo-discover.png` under `.test-results/`.

This completes the requested in-app logo integration. The broader redesign brief and launcher AppIcon are not implemented in this update. The supplied light logo has limited raster resolution; a vector source would improve sharpness.
