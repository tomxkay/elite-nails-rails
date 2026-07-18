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
   Sarah's 5-star review" — including hands-free/voice while they work.

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

## Suggested build order
1. **A1 — first vertical slice:** one model end-to-end (recommend **Promotions**:
   highest value, self-contained, time-bound) → migration, seed, view refactor,
   minimal admin. Proves the pattern.
2. **A2 — migrate remaining models** (services, pricing, team, reviews, settings,
   hours) + Active Storage for photos.
3. **B — MCP server** over the models with guardrails + audit, starting read-only,
   then writes behind auth.
4. **C — advanced features** picked by owner priority.
