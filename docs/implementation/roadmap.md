# Ordered implementation plan

1. Inspect repository and record assumptions / architecture (initial repository contained only .git).
2. Engineering foundation: pnpm workspace, native iOS project specification, API, admin, database Compose, CI and configuration validation.
3. First slice: synthetic property persistence → documented API → SwiftUI Discover and detail; public read-only demo operations view.
4. Native onboarding, secure identity/session integration, portfolio, private documents, notifications and account deletion with approved retention.
5. Server-authorized staff operations, audit trail, offering approvals and investor verification.
6. Approved financial model, transactional ledger, sandbox providers, idempotency, reconciliation and failure tests.
7. Security/accessibility/performance assessment, backup recovery, legal/provider approvals, TestFlight and production release review.

Acceptance: foundation requires builds, tests and reproducible README. First slice requires data served from the API, visible demo labels, loading/error/empty states and simulator verification. Record actual commands and blockers in verification.md. Later milestones cannot be marked complete based on the foundation.
