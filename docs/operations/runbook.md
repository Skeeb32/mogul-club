# Development operations

Follow the root README for setup. GET /api/v1/health probes MongoDB, PostgreSQL and Redis; returns 200 only if all respond, otherwise 503. GET /api/v1/live is process liveness only. Do not confuse liveness with readiness.

If startup fails, check configuration names and service health; never paste connection strings into issue logs. If data access fails, retain the error state and retry after service recovery. Reseeding upserts only synthetic fixture IDs; it does not clear collections.

Compose volumes preserve development data between restarts. `docker compose down` retains them. Destructive volume removal is not part of normal setup. Backup/restore and incident exercises are not yet implemented or verified. Before production: establish encrypted backups, restore drills, monitoring, alert ownership, incident response, staged migrations and rollback. No production deployment has occurred.
