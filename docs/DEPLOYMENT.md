# Deployment Guide — VPS (178.212.35.171)

Ubuntu 24.04. Node 22, Docker, PM2.

## Server layout

| Path | Purpose |
|------|---------|
| `/root/matrimonial` | App repo (cloned from GitHub, branch `main`) |
| `/root/matrimonial-deploy` | Docker Compose for Postgres/Redis + initdb scripts |
| `/root/.pm2` | PM2 process data |

## Running services

| Service | Type | Port | Restart |
|---------|------|------|---------|
| matrimonial-api | PM2 (NestJS) | 3001 | pm2 restart matrimonial-api |
| matrimonial-web | PM2 (Next.js) | 3100 | pm2 restart matrimonial-web |
| matrimonial_postgres | Docker | 5432 | docker restart |
| matrimonial_redis | Docker | 6379 | docker restart |
| adminer | Docker | 8081 | docker restart |

## Deploy new code (after `git push origin main`)

```bash
cd /root/matrimonial && git pull origin main

# API
cd apps/api && npm install && npm run build && pm2 restart matrimonial-api

# Web
cd apps/web && npm install && npm run build && pm2 restart matrimonial-web
```

## Database

Postgres runs from `/root/matrimonial-deploy/docker-compose.yml`:

```yaml
postgres:
  image: postgres:16-alpine
  restart: unless-stopped
  environment:
    POSTGRES_USER: postgres
    POSTGRES_PASSWORD: postgres
    POSTGRES_DB: matrimonial_admin
  volumes:
    - postgres_data:/var/lib/postgresql/data
    - ./initdb:/docker-entrypoint-initdb.d
```

`initdb/*.sql` runs ONLY on a fresh volume (first boot). It creates schema + seed + admin password.

### Rebuild DB from scratch (data loss!)

```bash
cd /root/matrimonial-deploy && docker-compose down -v && docker-compose up -d
```
All three initdb scripts re-run. **Warning: wipes all data.**

### Manual SQL access

```bash
docker exec -it matrimonial_postgres psql -U postgres -d matrimonial_admin
```

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| "database matrimonial_admin does not exist" | Recreate DB (see above) or `CREATE DATABASE matrimonial_admin;` then re-run 001 schema + seed |
| "Invalid credentials" at login | Password hash broken by shell `$` mangling — apply SQL via file (`psql -f file.sql`), never inline with `$` |
| Port already in use | Check `ss -tlnp`; web is on 3100 because 3000/8080/8090 were taken |
| API crash-looping | `pm2 logs matrimonial-api` — usually DB connection |
| Adminer "invalid server" | Use `matrimonial_postgres` (Docker network name), NOT `localhost` |

## PM2 persistence

Already configured:
```bash
pm2 save                    # saved process list
pm2 startup systemd         # boot script (enabled)
```
