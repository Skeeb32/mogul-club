# Mogul Club

The active working copy is `/Users/skeebkhan/Desktop/Mogul Club`. Open the root `Mogul Club.xcodeproj` and select the **Mogul Club** scheme / an iPhone simulator. The original Desktop starter files are preserved on disk but excluded from compilation. Native implementation lives under `apps/ios/MogulClub`; the root project retains your original bundle ID and signing team. The Documents copy is retained as an earlier snapshot.

To run synthetic discovery without Docker, use Node 22.23.4, run `pnpm install --frozen-lockfile`, then `pnpm dev:demo` from this folder. This starts a real local MongoDB process with persistent development data under ignored `.local-demo/`, seeds the fictional properties, and serves the API at `http://localhost:3001`. Stop with Control-C. PostgreSQL and Redis are intentionally not started by this lightweight command; readiness returns degraded, while the property slice works.

Native iOS real estate platform in development. The initial slice is a **read-only, clearly labeled synthetic demonstration**, backed by a real NestJS API and MongoDB. No real investments, payments, signatures, investor accounts, ownership issuance or tax documents are available.

## What exists

- SwiftUI welcome, Discover/search, API-backed property detail, portfolio/document empty states and account information; Xcode project and XCTest/XCUITest sources.
- NestJS `/api/v1` public demo property API, strict query validation, pagination, Swagger, Firebase token verification for protected routes, default-deny authorization, throttling and security headers.
- Next.js read-only demo operations page with search, empty/error recovery, responsive layout and light/dark themes. Privileged staff administration is not implemented.
- MongoDB fixtures, unique index and schema validation; persistent Compose volumes; PostgreSQL and Redis readiness probes.
- Pinned pnpm workspace, Docker images, CI workflow, architecture decisions, risk register and release blockers.

See [actual verification results](docs/implementation/verification.md). Native simulator compilation, five unit tests and two UI tests now pass; full Compose checks remain unverified. See [native results](docs/implementation/ios-verification.md). This is not production-ready or legally authorized.

## Prerequisites

- Node **22.23.4**, pnpm **10.33.0** (`.nvmrc` / `packageManager`).
- Docker Desktop or Docker Engine with Compose v2 for the complete local stack.
- Xcode with iOS 17+ SDK and an installed iPhone simulator for native builds. Command Line Tools alone are insufficient.
- Optional XcodeGen for regenerating `apps/ios/MogulClub.xcodeproj` from `apps/ios/project.yml`.

## Reproduce the complete development stack

From the repository root:

```sh
cp .env.example .env
pnpm install --frozen-lockfile
pnpm build
docker compose up --build --wait mongodb postgres redis api admin
docker compose run --rm seed
curl --fail http://localhost:3001/api/v1/health
curl --fail http://localhost:3001/api/v1/properties
```

Open `http://localhost:3000` for demo operations and `http://localhost:3001/api/docs` for Swagger. Compose uses internal service names; `.env` supplies loopback URLs for host-run commands. Credentials shown in the development template and Compose file are development-only defaults. Never reuse them in deployed infrastructure. Database and application ports bind only to loopback.

The seed command upserts two fictional records, creates a unique `id` index and validates synthetic-only fields and integer minor-unit amounts. It does not delete existing records. Volumes persist across `docker compose down` / `up`; no ledger schema is initialized because financial workflows are deferred.

Stop the stack with `docker compose down`; development data is retained. Backups and recovery are not verified yet.

## Run TypeScript applications on the host

```sh
docker compose up --wait mongodb postgres redis
pnpm build
pnpm seed
pnpm dev:api
```

In a second terminal:

```sh
pnpm dev:admin
```

The API watches compiled output; rerun `pnpm --filter @mogul/api build` after source edits. Next.js watches source changes automatically. Next reads `API_BASE_URL` from its process environment (defaults to `http://127.0.0.1:3001`); it never sends database URLs to the browser.

## Build and run iOS

Open the root `Mogul Club.xcodeproj`, select the `Mogul Club` scheme and an iPhone simulator, then Run. The Debug client calls `http://localhost:3001/api/v1/`, which reaches the Mac from the simulator. The API must already be running and seeded. Local networking permission is confined to Debug configuration. Release uses an intentionally unconfigured HTTPS host pending an approved deployment.

```sh
xcodebuild -project 'Mogul Club.xcodeproj' -scheme 'Mogul Club' -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
xcrun simctl list devices available
xcodebuild -project 'Mogul Club.xcodeproj' -scheme 'Mogul Club' -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO test
```

Replace the simulator name with one installed on your Mac. The Desktop project retains its existing development signing team and bundle ID. No distribution certificate or release authorization has been verified. Physical-device networking and signing require separate setup. The root Desktop project is authoritative. `apps/ios/project.yml` describes the earlier portable development project; regenerating that inner project does not update the root Desktop project.

## Checks

```sh
pnpm lint
pnpm typecheck
pnpm test
pnpm test:integration
pnpm build
pnpm contracts
pnpm exec playwright install chromium
pnpm test:browser
pnpm audit --prod --audit-level high
```

Integration tests launch a real temporary MongoDB 8.0.15 process, seed it, issue HTTP requests and restart the database to test persistence. They download an official MongoDB binary on first run, require network access and do not touch your development database. Apple Silicon is detected even under Rosetta. The integration readiness test deliberately uses unavailable PostgreSQL/Redis endpoints and expects HTTP 503.

Browser verification launches an isolated MongoDB/API/admin stack on ports 43101 and 43100, checks search, empty and outage states, scans accessibility at four widths, and cleans up processes. It requires a completed `pnpm build`. To use an installed Chrome instead of a downloaded Playwright browser:

```sh
CHROME_PATH='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' pnpm test:browser
```

Screenshots/logs are ignored under `.test-results/`. OpenAPI is generated to `packages/api-contracts/openapi.json`; CI rejects drift. CI jobs are configured but have not been run on GitHub in this environment.

## API surface and failure behavior

| Method | Path | Policy |
|---|---|---|
| GET | `/api/v1/live` | Public process liveness |
| GET | `/api/v1/health` | Public dependency readiness; 503 if any dependency is down |
| GET | `/api/v1/properties?q=&page=1&limit=20` | Public synthetic, published demo records only; non-production demo mode required |
| GET | `/api/v1/properties/:id` | Same policy; 404 for absent/invalid IDs |

Query parameters are whitelisted, search is literal and limited to 80 characters, page size is at most 50. Storage failures return a sanitized 503. Demo-disabled discovery returns 404. No privileged or financial routes exist. Private routes require a Firebase ID token for a verified account when `FIREBASE_PROJECT_ID` and server Application Default Credentials are configured; without provider configuration they remain denied. Public demo property routes expose only synthetic read-only records. See [Firebase setup](docs/auth/firebase-setup.md).

## Architecture and next work

Read [system design](docs/architecture/system-design.md), [ADR](docs/architecture/adr/001-stack-and-ledger.md), [threat model](docs/security/threat-model.md), [regulatory decisions](docs/compliance/regulatory-decisions.md), [operations](docs/operations/runbook.md), [release checklist](docs/app-store/release-checklist.md) and [ordered roadmap](docs/implementation/roadmap.md).

Next: satisfy Xcode/Compose foundation acceptance, then implement real sandbox identity/session handling and investor account workflows before privileged administration. Ledger, idempotency, subscriptions, distributions, reconciliation, private documents, account deletion, backup restore, monitoring, staging deployment and TestFlight remain incomplete. Legal entity, ownership form, offering authority, custody, providers, policies and support details remain release blockers.

Toolchain references: [NestJS prerequisites](https://docs.nestjs.com/first-steps), [Next.js installation](https://nextjs.org/docs/app/getting-started/installation), [Swift Package Manager](https://docs.swift.org/main/documentation/packagemanagerdocs/). Dependency updates must preserve lockfile reproducibility, regenerate OpenAPI and pass all applicable checks.
