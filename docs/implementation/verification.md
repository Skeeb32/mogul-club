# Initial foundation verification — 2026-10-24

Later Desktop integration and successful native builds/tests are recorded in [ios-verification.md](ios-verification.md); that report supersedes the missing-Xcode status below.

## Scope and ordered execution

Read the supplied JSON blueprint and pasted master request; inspected the repository, which contained only `.git` and no commits or application files. The originally mentioned Desktop specification was zero bytes; the Downloads JSON and pasted request supplied the requirements. Neither contained an `initial_execution` key. Followed the pasted request's “HOW TO START” order: inspection → product assumptions → architecture/security/compliance/runbook/release/roadmap files → foundational configuration → first API-backed synthetic discovery slice.

Product direction: fractional interests in individual residential properties, U.S. investors, eventual full-platform scope. Legal ownership form, offering permissions, custody, providers and operating entity remain unresolved. No real financial action was enabled.

## Final check results

| Command | Exit | Actual result |
|---|---|---|
| `pnpm install --frozen-lockfile` | 0 | All four workspace projects installed; lockfile up to date |
| `pnpm build` | 0 | Contracts and NestJS compiled; Next.js optimized production build completed |
| `pnpm lint` | 0 | ESLint passed |
| `pnpm typecheck` | 0 | Contracts, API and admin passed strict TypeScript checking |
| `pnpm test` | 0 | 4 Node test cases passed, 0 failed, 0 skipped |
| `pnpm test:integration` | 0 | 1 real MongoDB integration scenario passed, 0 failed, 0 skipped |
| `pnpm contracts` | 0 | OpenAPI generated from the configured NestJS application |
| `pnpm test:browser` | 0 | Chromium end-to-end flow and accessibility checks passed |
| `pnpm audit --prod --audit-level high` | 0 | No known vulnerabilities found in production dependency audit |
| `plutil -lint` on Xcode project and both Info plists | 0 | Property-list syntax valid; does not establish Swift compilation |
| `xcodebuild -project apps/ios/MogulClub.xcodeproj -scheme MogulClub -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build` | 1 | Blocked: full Xcode unavailable; active CommandLineTools path is not usable for this build |
| `docker compose config --quiet` | 127 | Blocked: Docker command not installed |

XCTest/XCUITest sources exist but were **not executed**. No GitHub Actions run, full Compose startup/container build, successful three-database readiness, deployment, TestFlight upload or App Store submission occurred.

## Behavior actually exercised

- Configuration rejects missing/invalid environment values, malformed connection URLs and production demo mode.
- Unmarked controllers reject anonymous, malformed, fabricated, and unverified bearer credentials. With a configured Firebase Admin verifier, a verified, non-revoked Firebase ID token is attached to the request as its principal. No investor-data routes exist yet.
- HTTP query validation rejects unknown/nested fields, excessive page sizes and out-of-range pages.
- Property routes restrict discovery to synthetic demo records; demo-disabled access and unknown IDs return 404.
- Database failures return sanitized 503 responses.
- Real MongoDB 8.0.15: seeding twice creates only two records; literal metacharacter search cannot turn into a wildcard; detail and filtering work; database restart retains records; invalid records fail schema validation.
- Financial mutation endpoint is absent; POST subscriptions returned 404.
- Process liveness returns 200; dependency readiness returns 503 with MongoDB up and deliberately unavailable PostgreSQL/Redis down.
- Browser: MongoDB → NestJS → server-rendered Next.js table; search, empty results, clear-search recovery, API outage and retry-link rendering.
- Browser: no page overflow at 320/768/1024/1440 widths; zero axe WCAG 2 A/AA and 2.1 AA violations at those light-mode widths and in the dark-mode scan; no browser runtime errors. Automated accessibility checks do not replace manual assistive-technology testing.
- Desktop/light and mobile/dark screenshots inspected visually; saved in ignored `.test-results/`.

## Failures found and resolved

1. Initial direct API compilation lacked built workspace contracts. Root scripts now build contracts before dependent checks.
2. MongoDB startup initially timed out, then exposed an illegal-instruction crash from an x86 binary under Rosetta. Integration/browser runners now detect Apple Silicon and select the native MongoDB binary. The real database integration scenario subsequently passed.
3. Audit found a high-severity transitive `multer` advisory. Pinned patched `multer` 2.5.0 via workspace override, installed it and confirmed the resolved runtime dependency. Final production audit passed.
4. Browser setup initially lacked downloaded Chromium. Installed Playwright's native browser; an installed Chrome attempt under Rosetta stalled and was terminated. Native Playwright Chromium was used for the passing run.
5. Corrected the browser harness to create an explicit browser context for axe scanning.
6. Axe found a keyboard-inaccessible horizontally scrollable table at 320px. Added a labeled, focusable region and visible focus style; rebuilt and reran the browser flow successfully.

Dependency install scripts for Scarf telemetry and MongoDB's optional postinstall were intentionally not allowed; integration testing downloads MongoDB at runtime and passed without those scripts.

## Acceptance status and blockers

**Foundation: partially verified, not accepted as complete.** API/admin builds, tests, database integration and reproducible setup files exist. Native compilation/simulator tests and complete Compose operation remain blocked by missing local tools. CI is configured to exercise these checks on suitable runners, but has not run.

**First discovery slice: API/admin verified; iOS source implemented but unverified.** No simulator, physical-device, VoiceOver or native network journey result is claimed.

**Remaining platform criteria: incomplete.** Secure identity/session flows, investor records, staff RBAC/resource permissions, audit events, property mutations, offering approvals, private document access, account deletion/retention, ledger calculations, idempotency, subscriptions, distributions, reconciliation, background jobs, backup/restore, monitoring, deployment automation and production release are not implemented. No financial correctness or production security sign-off is claimed.

**Release gates: blocked.** Legal entity, actual ownership and offering pathway, authorization, custody/payment and identity providers, approved financial/tax rules, policies/support URLs, security assessment, signing, device testing and TestFlight require completion. Real financial capabilities remain unavailable.

Next concrete step: install/select full Xcode and Docker, execute the documented native and Compose checks, resolve failures, then proceed to sandbox identity/session integration and account lifecycle before privileged administration or financial workflows.

## Files delivered

- `.dockerignore`
- `.env.example`
- `.github/workflows/ci.yml`
- `.gitignore`
- `.nvmrc`
- `README.md`
- `apps/admin/app/error.tsx`
- `apps/admin/app/globals.css`
- `apps/admin/app/layout.tsx`
- `apps/admin/app/loading.tsx`
- `apps/admin/app/page.tsx`
- `apps/admin/next-env.d.ts`
- `apps/admin/next.config.ts`
- `apps/admin/package.json`
- `apps/admin/tsconfig.json`
- `apps/api/package.json`
- `apps/api/src/app.module.ts`
- `apps/api/src/config.ts`
- `apps/api/src/database.ts`
- `apps/api/src/export-openapi.ts`
- `apps/api/src/fixtures.ts`
- `apps/api/src/main.ts`
- `apps/api/src/properties.ts`
- `apps/api/src/security.ts`
- `apps/api/src/seed.ts`
- `apps/api/src/setup.ts`
- `apps/api/test/foundation.test.ts`
- `apps/api/test/properties.integration.ts`
- `apps/api/tsconfig.json`
- `apps/ios/Config/Debug-Info.plist`
- `apps/ios/Config/Release-Info.plist`
- `apps/ios/MogulClub.xcodeproj/project.pbxproj`
- `apps/ios/MogulClub.xcodeproj/xcshareddata/xcschemes/MogulClub.xcscheme`
- `apps/ios/MogulClub/App/MogulClubApp.swift`
- `apps/ios/MogulClub/Core/APIClient.swift`
- `apps/ios/MogulClub/Core/DesignSystem.swift`
- `apps/ios/MogulClub/Core/Property.swift`
- `apps/ios/MogulClub/Features/Discover/DiscoverModel.swift`
- `apps/ios/MogulClub/Features/Discover/DiscoverView.swift`
- `apps/ios/MogulClub/Features/Discover/PropertyDetailView.swift`
- `apps/ios/MogulClubTests/APIClientTests.swift`
- `apps/ios/MogulClubUITests/NavigationTests.swift`
- `apps/ios/project.yml`
- `docker-compose.yml`
- `docs/app-store/release-checklist.md`
- `docs/architecture/adr/001-stack-and-ledger.md`
- `docs/architecture/system-design.md`
- `docs/compliance/regulatory-decisions.md`
- `docs/implementation/roadmap.md`
- `docs/implementation/verification.md`
- `docs/operations/runbook.md`
- `docs/security/threat-model.md`
- `eslint.config.mjs`
- `infrastructure/docker/Dockerfile`
- `package.json`
- `packages/api-contracts/openapi.json`
- `packages/api-contracts/package.json`
- `packages/api-contracts/src/index.ts`
- `packages/api-contracts/tsconfig.json`
- `pnpm-lock.yaml`
- `pnpm-workspace.yaml`
- `scripts/browser-smoke.mjs`
