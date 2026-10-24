# ADR 001: Native client and split operational / financial storage

Status: accepted for development; ledger schema deferred.

SwiftUI is the iPhone client; NestJS owns business rules; Next.js is the operations surface. pnpm coordinates TypeScript tooling. MongoDB stores flexible property and operational metadata. PostgreSQL is selected for future transactional journal entries because balanced postings, unique external references and atomic ledger updates benefit from relational constraints. This adds operational cost (backups, migrations, monitoring for two databases). No financial schema or ownership semantics will be finalized until the business model is approved. Redis is provisioned but not a financial source of truth.

Dependency versions are pinned in manifests and pnpm-lock.yaml. Upgrade in a branch, regenerate contracts, run checks/integration tests and review advisories before merging. XcodeGen specification is version controlled; generated Xcode projects are not hand edited.
