# Mogul Club system design

## Initial slice
Native SwiftUI iOS → versioned NestJS REST API → MongoDB for synthetic property records. Next.js provides a read-only public demo operations view, not privileged administration. PostgreSQL is reserved for the future ledger; Redis is available for future jobs. API health checks probe all three services. No payment SDK, funding route, ownership issuance, or real investor records exist.

## Trust boundaries
Clients are untrusted. Only the API has database credentials. Public routes return synthetic, published properties only when DEMO_MODE is enabled outside production. All other API routes are denied by default. No admin mutations or sessions are claimed as implemented. Production refuses demo configuration and exposes no property records in this slice.

## Data contract
Property identifiers are stable slugs. Records carry synthetic=true, source, updatedAt, currency, and integer minor-unit amounts. Pagination is bounded. OpenAPI is emitted from the same application used at runtime. iOS decodes the documented response and displays explicit loading, empty, retry, detail, and unavailable states.

## Deployment boundary
Local Compose is the only deployment target implemented. Staging, production, identity, object storage, queues and financial workflows are future work requiring separate review. No secrets or user data are embedded in mobile or web clients.
