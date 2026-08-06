# Database Backup & Restore

The superadmin panel has a full database backup system. It dumps **schema + data** for the
admin database and every tenant database via `pg_dump`, stores them on the server, and lets
you download or delete them from the UI.

## Features

| Feature | Details |
|---|---|
| Scope | `matrimonial_admin` + every tenant DB listed in `Tenants.DatabaseName` |
| Format | Plain SQL (`pg_dump -U postgres --no-owner --no-privileges`) — restores with `psql` |
| Storage | Server filesystem: `/root/matrimonial/apps/api/backups/` |
| Retention | Newest **10** backups kept, older ones auto-deleted |
| UI | Admin panel → sidebar → **Backups** |
| Auth | Requires superadmin JWT (all `/admin/*` routes are guarded) |

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/admin/backups` | Create a backup of admin + all tenant DBs → `{ backups: [filenames] }` |
| `GET` | `/admin/backups` | List backups → `{ backups: [{name, size, modified}] }` |
| `GET` | `/admin/backups/:file` | Download a backup file (Content-Disposition attachment) |
| `POST` | `/admin/backups/:file/delete` | Delete one backup → `{ deleted: true }` |

All endpoints require the JWT: `Authorization: Bearer <token>`.

## How It Works

1. `BackupsController.create()` runs `pg_dump` **inside the postgres container**
   (`docker exec matrimonial_postgres pg_dump ...`) for the admin DB, then for each tenant
   whose `DatabaseName` is set and whose database actually exists (unprovisioned seed
   tenants are skipped).
2. Each dump is written to `apps/api/backups/<db>_<timestamp>.sql`.
3. `list()` reads the directory and returns name/size/modified, newest first.
4. `prune()` deletes everything beyond the newest 10 files.

### Running from a dev machine (tests)

When the API runs off the VPS, `docker exec` isn't available locally. Set
`BACKUP_SSH_PREFIX` to wrap the docker command over SSH:

```bash
export BACKUP_SSH_PREFIX="sshpass -p 'PASSWORD' ssh -o StrictHostKeyChecking=no root@178.212.35.171"
```

On the server itself (PM2), no prefix is needed — `docker exec` is local.

## Restore

```bash
# restore admin DB (drop + recreate first if it exists)
docker exec -i matrimonial_postgres psql -U postgres -d matrimonial_admin < matrimonial_admin_2026-08-06T10-04-47-448Z.sql

# restore a tenant DB
docker exec -i matrimonial_postgres psql -U postgres -d provision-test_provisiontestmatrimony < provision-test_...sql
```

The dumps use `--no-owner --no-privileges`, so they restore cleanly as the `postgres` user.

## Tests

`apps/api/test/backups.e2e-spec.ts` — 6 tests: auth guard, empty list, create (skipped
without `BACKUP_SSH_PREFIX` on a dev machine), list after create, download content
(`CREATE TABLE` present), 404 for unknown file.

## Related: DB Watchdog

`/root/db_watchdog.sh` (cron, every 5 min) auto-recreates `matrimonial_admin` with schema +
seed + admin password if it is ever dropped — a safety net alongside these backups.
