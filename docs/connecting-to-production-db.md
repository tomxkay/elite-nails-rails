# Connecting to the Production Database

The production database is a **Fly Postgres flex cluster** (`elite-nails-db`,
region `iad`). It has **no public internet endpoint** — you reach it through a
`fly proxy` tunnel over Fly's private WireGuard network, then point a local
client (TablePlus, `psql`, etc.) at `localhost`.

> ⚠️ **This is live production data** backing https://elite-nails-rails.fly.dev.
> Edits take effect immediately with no undo. Prefer read-only work. Content
> changes should go through the **MCP tools**, which record an `AuditLog` entry;
> direct SQL writes bypass that audit trail.

## Prerequisites

- `flyctl` installed and authenticated (`fly auth whoami`).
- Access to the `elite-nails-rails` / `elite-nails-db` Fly apps.

## Step 1 — Open the tunnel

The tunnel **is** the connection. It must stay running the whole time you're
using the database; closing it (or Ctrl-C) drops the connection immediately.

```bash
fly proxy 15432:5432 -a elite-nails-db
```

This forwards **`localhost:15432` → the cluster's `5432`**. Port `15432` is used
(instead of `5432`) so it won't collide with any Postgres running locally — a
local Postgres on `5432` is the usual cause of a confusing
`role "elite_nails_rails" does not exist` error (you'd be hitting your own
machine's database, not Fly).

To avoid tying up a terminal, background it:

```bash
fly proxy 15432:5432 -a elite-nails-db &
# stop later with:  kill %1   (or: pkill -f "fly proxy")
```

## Step 2 — Get the credentials

Username / password / database name live in the app's `DATABASE_URL` secret.
**Do not commit these anywhere.** Fetch them on demand:

```bash
fly ssh console -a elite-nails-rails -C "printenv DATABASE_URL"
```

Output format:

```
postgres://<user>:<password>@<host>:5432/<dbname>?sslmode=disable
```

Take the `<user>`, `<password>`, and `<dbname>`. Ignore the host — that's Fly's
internal `.flycast` address; you connect to `localhost` instead.

> The Rails app auto-suspends when idle. This command briefly wakes it, then it
> re-suspends. Harmless.

## Step 3 — Connect the client

### TablePlus

New connection → **PostgreSQL**:

| Field     | Value                          |
|-----------|--------------------------------|
| Host      | `127.0.0.1`                    |
| Port      | `15432`  ← the tunnel port     |
| User      | `<user>` from `DATABASE_URL`   |
| Password  | `<password>` from `DATABASE_URL` |
| Database  | `<dbname>` from `DATABASE_URL` |
| SSL mode  | `disable`                      |

`sslmode=disable` matches the `DATABASE_URL` — the flex cluster isn't presenting
a cert on that internal port. The tunnel itself is WireGuard-encrypted; the
`localhost` hop is plaintext to your own machine.

### psql

```bash
psql "postgres://<user>:<password>@127.0.0.1:15432/<dbname>?sslmode=disable"
```

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `role "elite_nails_rails" does not exist` | Client is hitting a **local** Postgres — you're on port `5432` and/or the tunnel isn't running. Use port `15432` and confirm `fly proxy` is up. |
| `connection refused` on `15432` | The `fly proxy` tunnel isn't running. Start it (Step 1). |
| Connection drops randomly | The `fly proxy` process was closed. It must stay running for the life of the session. |
| `fly ssh console` hangs | The app was fully suspended; give it a few seconds to wake, or retry. |

## Notes

- There is intentionally no public database endpoint — the tunnel is the only
  path in, which keeps the DB off the public internet.
- TablePlus "Over SSH" does **not** apply here: Fly uses WireGuard, not SSH, so
  `fly proxy` is the correct mechanism.
