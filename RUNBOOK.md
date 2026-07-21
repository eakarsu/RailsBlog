# RailsBlog operations runbook

## Release

Copy `.env.example` to a secret-managed environment file and replace every placeholder. Production requires PostgreSQL and a unique `SECRET_KEY_BASE`; startup fails if either is missing. Build the image, run `bundle exec rails db:migrate` as a one-off release command, and then start the web container. `bin/start` deliberately refuses to boot with pending migrations and never migrates or seeds automatically.

Provision the first administrator only through a controlled one-time `db:seed` invocation with `BOOTSTRAP_ADMIN_EMAIL`, `BOOTSTRAP_ADMIN_PASSWORD`, and optionally `BOOTSTRAP_ADMIN_NAME`. Remove those variables immediately afterward. Add authors, editors, and moderators through an audited Rails console until an administrative UI is approved.

## Health and rollback

`GET /health` checks database connectivity and returns 503 when unavailable. Monitor web error rate, response latency, pending comment volume, disk capacity for local Active Storage, and database saturation. For a bad application release, roll back to the previous immutable image. Roll back a database migration only when its migration is explicitly reversible and a current backup has been verified.

## Backup and restore

Run `BACKUP_DIRECTORY=/secure/path ./bin/backup`; it creates a PostgreSQL custom-format dump and a SHA-256 sidecar. Copy both to encrypted off-site storage under the retention policy. Verify with `sha256sum -c <dump>.sha256` and `pg_restore --list <dump>`.

Test restores regularly into an isolated empty database: verify the checksum, run `pg_restore --clean --if-exists --no-owner --dbname "$RESTORE_DATABASE_URL" <dump>`, boot the release against that database, check `/health`, and sample users, articles, revisions, comments, media metadata, and audit events. Never restore over production directly. Active Storage objects are separate from PostgreSQL and must be snapshotted with matching retention and restore points.

## Incident controls

Suspend compromised users, rotate `SECRET_KEY_BASE` to invalidate all sessions, rotate database credentials, and preserve publication/moderation events before remediation. Logs must not contain passwords, session cookies, email addresses, raw IP addresses, or import payloads. Import first in validation-only mode and review every reported error before committing drafts.
