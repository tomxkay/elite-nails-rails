# CMS + AI/MCP Roadmap (Milestone 2)

Vision doc for turning Elite Nails from a **content-in-code brochure site** into a
**DB-backed platform the owners control through an AI agent** (Claude) over MCP.

_Created: 2026-07-18. Status: PLANNING (no code written yet)._
Parent planning doc: [`../PROJECT.md`](../PROJECT.md).

## The Vision

Today all content lives in Ruby view partials and the `salon` helper (see
`AGENTS.md` — there is no business data in the DB). Non-technical owners can't
change anything without a developer. We want to:

1. **Move all content into the database** behind editable models.
2. **Expose that data through an MCP server** so an AI agent (Claude) can read and
   write it safely.
3. Let owners **control the salon by talking to Claude** — "add a Valentine's
   promo," "raise gel manicure to $40," "we're closing early Friday," "feature
   Sarah's 5-star review." (Via **text chat** with Claude; native voice→MCP isn't
   production-ready yet — see Research Findings.)

The DB migration (Phase A) is the **prerequisite** for everything else: once
content is CRUD-able models, the MCP server (Phase B) is mostly thin, well-guarded
tools over those models, and the site keeps rendering from the same data.

```
Owner (voice/chat)  ──▶  Claude (MCP client)  ──▶  Elite Nails MCP server (Rails)
                                                          │  CRUD + guardrails + audit
                                                          ▼
                                                   Postgres/SQLite models  ◀── Admin UI (fallback)
                                                          │
                                                          ▼
                                                   Public site renders live
```

## Why this serves the project goal

- **Owner autonomy** — update promos, prices, hours, reviews without a developer.
- **Speed** — a spoken sentence becomes a live site change in seconds.
- **Keeps the goal** (drive customers): faster, more current content = more
  relevant promos, accurate hours, fresh social proof.
- **Differentiator** — very few local salons have an AI-operated site.

---

## Phase A — Content to the Database (CMS foundation)

Introduce models, migrate the inline arrays into them, refactor views to read from
the DB, and give owners a fallback admin UI.

### Proposed data model
| Model | Fields (draft) | Replaces |
|-------|----------------|----------|
| `SiteSetting` (single row) | name, phone, street, city, region, postal_code, country, latitude, longitude, price_range, established, booking_url, google_reviews_url, aggregate_rating, review_count | `ApplicationHelper#salon`, env URLs |
| `BusinessHour` | day_of_week (0–6), opens, closes, closed:bool | `_contact` hours, JSON-LD hours |
| `Service` | title, description, image (Active Storage), pricing_category, featured:bool, position, active:bool | `_services` array |
| `PricingCategory` + `PricingItem` | category: name, position · item: name, price:string, position | `_pricing` array |
| `TeamMember` | name, role, bio, quote, specialties (JSON/assoc), photo (Active Storage), position, active | `_team` array |
| `Review` | author_name, rating, quote, source, reviewed_at, featured:bool, approved:bool, position | `_testimonials` array |
| `Promotion` | title, deal, description, fine_print, badge, featured:bool, active:bool, starts_on, ends_on, position | `_promotions` arrays |
| `AuditLog` | actor, action, model, changes (JSON), source (mcp/admin), created_at | (new — see guardrails) |

Notes / decisions to make:
- **Price as string** (`"+$5"`, `"$40+"`) to preserve formatting, or cents + display rule.
- **Services vs PricingItems overlap** — keep separate (marketing cards vs detailed menu) or unify into one catalog. Draft: keep separate, link `Service.pricing_category`.
- **Images** — use **Active Storage** for team/service/gallery photos (uploadable). Needs `active_storage:install`. On Fly, store blobs in **Tigris (S3)** — already provisioned for Litestream, nice synergy. SQLite DBs stay covered by Litestream.
- **`active`/`position`** on everything so owners can reorder/hide without deleting.

### Work items
1. Add models + migrations; create the primary `db/schema.rb` (currently none).
2. `rails active_storage:install`; configure Tigris as the production storage service.
3. Seed the DB from today's inline content (`db/seeds.rb`) so nothing is lost.
4. Refactor each home partial to render from models (keep `salon` helper reading `SiteSetting`).
5. **Admin UI** for the owner (fallback to MCP): evaluate **Avo** (polished, non-tech friendly) vs Administrate vs ActiveAdmin vs custom. Needs auth (Rails 8 auth generator or Devise).
6. Tests for models + the refactored views.

---

## Phase B — MCP Server (AI control plane)

A Rails-mounted **MCP server** exposing the CMS as safe tools an agent can call.

### Draft tools
- **Read:** `get_site_settings`, `list_services`, `list_pricing`, `list_team`,
  `list_reviews`, `list_promotions`, `get_business_hours`.
- **Write:** `update_site_settings`, `upsert_service`, `set_service_active`,
  `update_pricing_item`, `upsert_team_member`, `add_review`, `feature_review`,
  `upsert_promotion`, `expire_promotion`, `set_business_hours`.

### Technical decisions to research (Phase B kickoff)
- **Ruby MCP implementation** — official MCP Ruby SDK vs community gems (e.g.
  `fast-mcp`) mounted as a Rails endpoint. _Verify current best option._
- **Transport** — remote MCP over HTTP (Streamable HTTP) so claude.ai / Claude
  Desktop / Claude Code can connect.
- **Auth** — remote MCP typically uses OAuth 2.1; for a single owner an API
  token may suffice initially. _Decide auth model; this gates production safety._

### Guardrails (non-negotiable — this writes to production)
- **Audit log** every write (actor, before/after, source).
- **No hard deletes** — use `active:false` / soft delete.
- **Validation** at the model layer (agent input is untrusted).
- **Human-in-the-loop** for risky changes (price drops, hours) — confirm/preview
  or a publish step; consider a draft→publish flag.
- **Scoped tokens + rate limits**; separate staging vs production credentials.

---

## Phase C — Advanced AI features (build on A + B)

These become possible once data is in the DB and reachable over MCP.

1. **Conversational content management** — "Add a Valentine's promo: 20% off gel
   sets through Feb 14" → creates a `Promotion` with `starts_on/ends_on`;
   auto-expire past promos.
2. **Voice control** — via Claude voice, update hours/promos/services hands-free
   during the workday.
3. **Review management** — sync/import Google reviews, feature the best, draft
   polite responses, flag negatives for the owner.
4. **AI-drafted copy** — generate service descriptions, seasonal promo copy, and
   social captions in the salon's warm voice; keep SEO meta/JSON-LD in sync.
5. **Booking notifications & summaries** — via Square API (once booking is set
   up): daily appointment digest, no-show alerts, "slow Tuesday → suggest a promo."
6. **Customer-facing site chatbot** — a Claude-powered assistant answering "do you
   do dip powder? how much? open Sunday?" from the same DB (Claude API, not MCP).
7. **Business insights** — "most-viewed but least-booked service?" → promo ideas
   (needs analytics).
8. **Instagram / gallery sync** — pull latest posts; AI curates which nail-art
   photos to feature in the Gallery.
9. **Multilingual content** — AI-generated Spanish / Vietnamese versions
   (relevant to the local clientele).
10. **Content safety / approval workflow** — AI proposes changes; owner approves
    via a simple publish toggle; full change history + one-click rollback.

## Risks & considerations
- **Security is the whole game** — MCP write access to production content is
  powerful; strong auth, audit, validation, and human approval for risky ops are
  mandatory before go-live.
- **Complexity jump** — from a static site to DB + auth + admin + MCP + background
  jobs (Solid Queue would finally be used, e.g. review sync). More surface, more
  tests, more that can break.
- **Booking features depend on a booking provider** (Square) being set up first.
- **Cost** — AI/token usage; keep an eye on it.
- **Durability** — Active Storage blobs → Tigris; SQLite → Litestream (already set).

## Open questions (for the owner / project)
- Do owners want a **traditional admin UI too**, or is **Claude/MCP the primary**
  (voice/chat) control surface with admin as fallback?
- **Which content matters most** to edit first (promotions? pricing? hours?) — sets
  the first vertical slice.
- Comfort level with **AI making live changes** vs a **review-before-publish** step?
- Is **Square** the booking system (unblocks booking notifications)?
- Any need for **multiple staff logins / roles**, or single-owner access?

## Decisions (2026-07-18)
- **Control surface: MCP only — no admin UI.** Claude (chat/voice) is the sole way
  owners edit content. ⚠️ Implication: no GUI fallback, so (a) guardrails + audit +
  rollback are critical, and (b) keep a break-glass path for emergencies (Rails
  console / re-seed) documented for the developer.
- **AI autonomy: live edits + audit log.** Changes apply immediately; every write
  is logged with before/after and is one-click reversible. No pre-publish approval
  step (accepted higher risk for a faster, more magical experience).
- **First vertical slice: Promotions** — self-contained, high value, time-bound,
  and needs **no Active Storage** (promotions have no images), so images/Tigris are
  deferred to the later team/services/gallery migration.
- **Approach: research/spike the stack first**, then build.
- **Database engine: PostgreSQL.** Dev + test primary DB switched to Postgres
  (2026-07-18). **Production still runs SQLite + Litestream** until a tracked
  deploy task provisions managed Postgres on Fly (update `fly.toml` + the
  production block in `database.yml`, retire Litestream-for-DB; Tigris stays for
  future Active Storage). Low lock-in: data re-seeds from each model's in-code
  `DEFAULTS`.
- **In-code backup pattern:** every migrated model keeps a `DEFAULTS` constant (the
  canonical seed source) and a `for_display` that falls back to it when the table
  is empty/unavailable — the site always renders, and re-seeding never loses data.

## Production Postgres — deploy steps (MANUAL, needs your Fly account)

Repo is **prepared** for Postgres in production (2026-07-18): `database.yml`
production → Postgres multi-DB; `Dockerfile` uses `postgresql-client` + `libpq-dev`;
`fly.toml` drops the SQLite volume + litestream and runs `./bin/thrust ./bin/rails
server` (DB migrates on boot via `bin/docker-entrypoint`); litestream + sqlite3
gems removed. What I **can't** do (requires your Fly account):

1. **Provision Postgres:** `fly postgres create` (or Fly Managed Postgres).
2. **Attach:** `fly postgres attach <cluster> -a elite-nails-rails` — sets the
   `DATABASE_URL` secret automatically.
3. **⚠️ Multi-DB gotcha:** the Solid stack uses separate databases
   (`elite_nails_cache/_queue/_cable`). Fly's attached DB user often lacks
   `CREATEDB`, so boot-time `db:prepare` can't create them. Fix once, either:
   - grant it: `fly postgres connect` → `ALTER ROLE <role> CREATEDB;`, **or**
   - pre-create the three databases, **or**
   - (alternative) collapse Solid onto the primary DB — a small config change if
     we'd rather avoid the extra databases. _Decide at deploy time._
4. **Secrets:** ensure `RAILS_MASTER_KEY` is set, plus `BOOKING_URL`,
   `GOOGLE_REVIEWS_URL`, and the **Tigris/S3** vars (`AWS_REGION`,
   `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `BUCKET_NAME`, `AWS_ENDPOINT_URL_S3`)
   — production currently boots the Tigris Active Storage service, which needs a
   region even before A2 uses it.
5. **Deploy & verify:** `fly deploy`; watch `fly logs` for a clean `db:prepare`
   and boot. ⚠️ **Unverified locally** — I can't run a real Fly Postgres deploy, so
   treat the first deploy as the verification step.

## What's next — launch checklist (2026-07-18)

Milestone 2 core is **live**: site + MCP + OAuth deployed and verified at
https://elite-nails-rails.fly.dev, and the owner's claude.ai connector is
attached to production. Remaining work, in priority order:

**Housekeeping**
- [x] Re-point claude.ai connector from ngrok to production (`/mcp` on fly.dev).
- [x] Stop the local ngrok tunnel + tunnel-test dev server.
- [ ] Re-apply dev-only content edits in prod via chat (e.g. gel manicure $40 —
      prod seeded fresh from `DEFAULTS`).
- [ ] `git push` — the whole milestone (~46 commits) is local-only.
- [ ] Optional: set `GOOGLE_REVIEWS_URL` prod secret (currently falls back to a
      Maps search link).

**Client-ready polish**
- [ ] **Custom domain** — `fly certs add <domain>` + DNS once the salon has one;
      fly.dev URL is fine for testing, not for a business card.
- [ ] **Owner handoff doc** — one page: how to add the connector, where the
      password lives, example phrases ("add a promo", "change Saturday hours",
      "hide that review"), what the approval prompts mean, who to call when
      stuck. With MCP-only control, this doc is the admin manual.

**Remaining engineering**
- [ ] **Active Storage + Tigris** (last deferred Phase A item) — make
      team/service/gallery photos owner-manageable; unlocks photo tools over MCP.
- [ ] **Phase C by owner priority** — first candidates: scheduled promo
      expiry/digest (first real Solid Queue use), Google review sync,
      AI-drafted seasonal copy. See Phase C list above.

**Ops notes**
- Machines auto-stop when idle → first request after a lull cold-starts (~2-4s).
  The Postgres machine stays up (~$2/mo).
- Credentials (MCP owner password/token, PG superuser, `RAILS_MASTER_KEY`) are
  in the developer's password manager + git-ignored `.env.production.secrets`.
  Fly secrets are write-only — rotate, never recover.
- Break-glass path (MCP down/misbehaving): `fly ssh console -a elite-nails-rails`
  → `bin/rails console`; content re-seeds from model `DEFAULTS` via
  `bin/rails db:seed`; every MCP write has an `AuditLog` before/after snapshot.

### Progress
- **Phase B — full tool coverage (2026-07-18).** MCP tools extended from the
  Promotions pilot to **every content model** — 24 tools registered in
  `McpController::TOOL_CLASS_NAMES`: Services, PricingItems (category-validated
  against `CATEGORY_ORDER`), TeamMembers (incl. `specialties` array),
  Reviews (rating 1–5 schema-validated; visibility via `approved`),
  SiteSetting (`Get`/`Update` singleton; feeds contact/SEO/JSON-LD),
  BusinessHours (`Get` incl. grouped display; `Set` upserts one weekday per
  call, `HH:MM` format-validated, `closed: true` clears times). Same guardrails
  as the pilot: dry-schema at the boundary, `AuditLog` before/after on every
  write, no hard-delete tools. Photos stay developer-managed (Active Storage
  still deferred). Suite 71 green. **Phase B is functionally complete** — next
  is production deploy (Fly Postgres + secrets) and Phase C features.
- **Phase B — Streamable HTTP transport (2026-07-18).** claude.ai completed OAuth
  but then reported "no MCP server found": its connector speaks **Streamable
  HTTP** (JSON-RPC `POST /mcp`), while fast-mcp 1.6 only serves the deprecated
  SSE transport (`/mcp/sse` + `/mcp/messages`) and 404s a bare `POST /mcp`.
  Following the working pattern in the Crown project, replaced the fast-mcp
  mount with **`McpController`** — a minimal Streamable HTTP endpoint
  (`initialize`, `ping`, `tools/list` with camelCase annotations, `tools/call`;
  notifications → 202; GET/DELETE → 405). fast-mcp remains only as the tool
  layer (`ActionTool::Base` + dry-schema validation, invoked via
  `call_with_schema_validation!`); tools are registered in
  `McpController::TOOL_CLASS_NAMES`. `McpDualAuth` still fronts `/mcp` and now
  answers CORS preflights itself. Claude Code must reconnect with
  `--transport http` and URL `<base>/mcp` (SSE endpoints are gone). Verified
  through ngrok: initialize/tools-list/tools-call all work with the static
  token; 401 challenge intact. Suite 58 green.
- **Phase B — OAuth (claude.ai) — IN PROGRESS (2026-07-18).** claude.ai's connector
  UI (confirmed via screenshot) offers only OAuth Client ID/Secret — no static-header
  option — so `static_headers` is unavailable to this account; **OAuth is required**
  for claude.ai. Building an OAuth 2.1 provider in the app (Doorkeeper). Slices:
  1. ✅ **Foundation** — Doorkeeper installed (public clients, PKCE S256 forced,
     authorization_code + refresh tokens, `skip_authorization`), single-owner login
     (`/owner/login`, `MCP_OWNER_PASSWORD` — no User table), migrations, routes.
  2. ✅ **Discovery** — `/.well-known/oauth-protected-resource` (RFC 9728) +
     `/.well-known/oauth-authorization-server` (RFC 8414) advertising S256.
  3. ✅ **Dynamic Client Registration** — custom `/oauth/register` (RFC 7591)
     creating public Doorkeeper clients; CSRF-exempt, CORS-open, 201 + client_id.
  4. ✅ **Dual-auth in front of `/mcp`** — `McpDualAuth` Rack middleware
     (`lib/middleware/mcp_dual_auth.rb`), inserted ahead of the fast-mcp transport
     in `config/initializers/fast_mcp.rb`; fast-mcp's own auth is disabled
     (`authenticate: false`). Accepts static `MCP_AUTH_TOKEN` (secure-compared,
     read per-request) OR an `accessible?` Doorkeeper token; otherwise `401` +
     `WWW-Authenticate: Bearer resource_metadata="<base>/.well-known/oauth-protected-resource"`
     with `Access-Control-Allow-Origin: *` + `Access-Control-Expose-Headers:
     WWW-Authenticate` so claude.ai's browser can read the challenge. CORS
     preflights pass through unauthenticated. 9 integration tests
     (`test/integration/mcp_dual_auth_test.rb`); suite 46 green. Verified live:
     401 challenge / static-token 200 / bad-token 401 on a booted dev server.
  5. ✅ **Verified against claude.ai over ngrok (2026-07-18).** The owner-facing
     flow works end-to-end in the real claude.ai UI: custom connector added with
     just the `<base>/mcp` URL (no client id — DCR handles registration), OAuth
     completes via `/owner/login`, and **all four Promotion tools work from a
     chat** (list/create/update/hide, with claude.ai's per-tool approval
     prompts). Required the Streamable HTTP transport switch + the two
     Doorkeeper fixes below. Earlier, the same flow was simulated with curl through
     ngrok and it passes end-to-end: DCR → PKCE authorize → owner login →
     `skip_authorization` redirect to `https://claude.ai/api/mcp/auth_callback`
     with code+state → token exchange (scope `claudeai` echoed, 7200s expiry,
     refresh token) → `/mcp` 200 with the OAuth token → refresh grant works.
     Watch items resolved: `WWW-Authenticate` is CORS-exposed; **no CSP header**
     is sent, so `form_action` can't block the redirect; scope parsing — the real
     claude.ai authorize request sends **no scope param**, which Doorkeeper
     rejects ("Missing required parameter: scope") unless `default_scopes` is
     set → configured `default_scopes :mcp` + `optional_scopes :claudeai`, DCR
     stores blank per-app scopes (so they can't shadow the server list), and
     both discovery docs advertise `scopes_supported`. Found+fixed live: Doorkeeper calls
     `.id` on the resource owner, so `resource_owner_authenticator` now returns
     `MCP_OWNER` (a `Data` object), not the integer 1 — locked in by
     `test/integration/oauth_authorization_flow_test.rb`. **Remaining:** add the
     connector in claude.ai's UI (Settings → Connectors → paste `<ngrok>/mcp`)
     and exercise the Promotion tools from a chat — couldn't be automated
     (Chrome extension not connected); needs a quick manual run.
- **Phase B — pilot DONE (2026-07-18).** MCP server live via **`fast-mcp` 1.6.0**,
  mounted at `/mcp` (SSE transport: `/mcp/sse` + `/mcp/messages`), bearer-token auth
  (enabled when `MCP_AUTH_TOKEN` is set). Added **`AuditLog`** (before/after
  snapshots, `source: "mcp"`) and four **Promotion** tools — `list_promotions`
  (read), `create_promotion`, `update_promotion`, `set_promotion_active` (guarded
  writes: validation via dry-schema, every write audited, no hard delete). Verified
  locally: tools create/update/hide + audit correctly; SSE endpoint emits its
  handshake. 8 tool/audit tests (full suite 35 green).
  **✅ Verified with a live Claude client (2026-07-18):** connected **Claude Code**
  to the server over ngrok (SSE transport + static bearer token via
  `--header "Authorization: Bearer <MCP_AUTH_TOKEN>"`) and successfully did CRUD on
  promotions through Claude. Gotchas found + fixed: fast-mcp's `localhost_only`
  (default true) blocks remote/tunnelled clients → set false; `allowed_origins`
  only wildcards via a **Regexp** (`[/.*/]`), not the string `"*"`. Auth via static
  header works; the interactive "authenticate" button uses OAuth (unsupported by
  fast-mcp) and must be avoided. Origin/IP protections are now env-gated
  (permissive in dev, host-restricted in production via `MCP_ALLOWED_ORIGINS`).
  **Still to do:** (a) verify the **claude.ai** custom connector specifically
  (OAuth-first UI — may need real OAuth on the server for a clean owner experience);
  (b) extend tools to the other models (services/pricing/team/reviews/settings/hours).
- **A2 — DONE (2026-07-18), except Active Storage.** All page content is now
  DB-backed: `Promotion`, `Service`, `PricingItem`, `TeamMember`, `Review`,
  `SiteSetting` (singleton NAP/geo/price/aggregate rating), `BusinessHour` (hours,
  with grouped display + schema.org `openingHoursSpecification`). The `salon`
  helper reads `SiteSetting`; contact + JSON-LD + meta tags + reviews aggregate all
  read from the DB (added a bonus JSON-LD `aggregateRating`). 26 model tests pass;
  each model keeps an in-code `DEFAULTS` fallback. **Deferred:** Active Storage
  (uploadable team/service/gallery photos → Tigris) — photos are still asset files.
  **Next: Phase B (MCP server).**
- **Prod deploy: DONE (2026-07-18)** — live at https://elite-nails-rails.fly.dev.
  Fly Postgres `elite-nails-db` (smallest, iad) created + attached; app role
  granted CREATEDB (Solid `_cache`/`_queue`/`_cable` created on boot); old
  SQLite-era machine + volume destroyed; secrets set (`RAILS_MASTER_KEY`, prod
  `MCP_AUTH_TOKEN`/`MCP_OWNER_PASSWORD` — generated fresh, distinct from dev).
  One deploy fix needed: Thruster binds `HTTP_PORT` (default :80 fails as
  non-root) → `HTTP_PORT=8080` in `fly.toml [env]`. Verified in production:
  site renders seeded content, `/up` 200, discovery docs, 401 challenge, 24
  tools via static token, and the full OAuth flow (DCR→PKCE→login→token→
  tools/call). Note: prod DB seeded fresh from `DEFAULTS` — content edits made
  in dev (e.g. the $40 gel manicure) are not carried over.
- **Prod Postgres: PREPARED (2026-07-18), then deployed same day** — see the
  deploy-steps section above.
- **A1 — Promotions slice: DONE (2026-07-18).** `Promotion` model + migration +
  primary `db/schema.rb`, idempotent seeds from `Promotion::DEFAULTS`, `_promotions`
  view rendering from the DB with in-code fallback, 5 passing model tests. Verified
  on Postgres end-to-end (DB-backed render + fallback). AuditLog deferred to Phase B
  (no writes yet in A1).

## Research Findings (2026-07-18)

Resolves the Phase B "to research" items. Sources at bottom.

**Rails MCP implementation → `fast-mcp`** (v1.6.0, Sept 2025; Ruby 3.2+, we're on
3.2.1). Mounts via `FastMcp.mount_in_rails`; tools subclass `ApplicationTool` with
**dry-schema-validated arguments** (validates untrusted agent input at the
boundary — exactly what our guardrails need) and a `call` method.

**Transport → Streamable HTTP.** Current/recommended per MCP spec; **SSE is
deprecated** (2025). Our endpoint must be **public HTTPS** — Fly.io provides this.
⚠️ **Verify during the spike** that fast-mcp's HTTP transport is compatible with
claude.ai's current remote-connector expectations (older write-ups referenced SSE +
an `mcp-proxy` bridge for Claude Desktop; the modern claude.ai custom-connector path
takes a remote HTTPS URL directly).

**Auth → static Bearer token via request header.** Simplest secure option for a
single owner, and it matches fast-mcp's built-in token auth (`authenticate: true` +
`auth_token`). OAuth 2.x is supported/recommended only if we later need multi-user.
Token stored in Rails credentials / Fly secrets.

**How the owner connects (non-technical friendly):**
- **claude.ai:** Settings → Connectors → "Add custom connector" → paste the Fly
  URL → Advanced/Request headers → `Authorization: Bearer <token>` → Add. (Request-
  header auth is currently **beta**.)
- **Claude Code:** `claude mcp add --transport http cms https://<app>.fly.dev/mcp --header "Authorization: Bearer <token>"`.

**Destructive/write tools:** MCP has no protocol-level "confirm" — claude.ai shows a
per-tool **approval prompt** (allow once / always). We reinforce with descriptive
tool names/descriptions + our own guardrails (audit log, soft delete, validation).

**Requirements/gotchas:** HTTPS required; public endpoint (Fly is fine); no dynamic
client registration (pre-register the URL); tool response ≲1MB; if we ever move to a
private network, Anthropic "MCP Tunnels" exist (not needed on public Fly).

**⚠️ Voice control — reality check.** Native **voice → MCP tool invocation is NOT
production-ready today.** Claude voice mode can't reliably invoke MCP tools directly.
The realistic experience is **text chat** (typing to Claude, or phone dictation →
text → Claude → MCP). Voice-first control should be treated as **aspirational**, not
a 2026 deliverable. This tempers the original "voice control" framing — the CMS-over-
chat value stands regardless.

## Suggested build order
1. **A1 — first vertical slice:** one model end-to-end (recommend **Promotions**:
   highest value, self-contained, time-bound) → migration, seed, view refactor,
   minimal admin. Proves the pattern.
2. **A2 — migrate remaining models** (services, pricing, team, reviews, settings,
   hours) + Active Storage for photos.
3. **B — MCP server** over the models with guardrails + audit, starting read-only,
   then writes behind auth.
4. **C — advanced features** picked by owner priority.
