# Initial threat model

Assets: future identity records, private documents and authoritative financial records; currently synthetic properties only.

Boundaries: device/browser → API → private databases. Threats include object access bypass, query injection, forged financial requests, leaked credentials, demo data in production, dependency compromise and availability loss.

Initial controls: global deny-by-default route guard, explicit public endpoints, strict DTO validation, bounded pagination, no user-supplied database query objects, Helmet, request throttling, non-sensitive error messages, startup configuration validation, synthetic-only repository filters, no financial execution code. Health failures return 503 without connection strings. Demo is forbidden in production. Database ports bind to loopback locally.

Residual risks / incomplete controls: no production identity provider, MFA, audit pipeline, private storage, penetration test, backup restore verification or production infrastructure. Public demo operations page grants no staff privileges. Do not deploy as a live investment platform.
