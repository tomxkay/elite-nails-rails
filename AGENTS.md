# AGENTS.md — Elite Nails

Dev reference for AI agents and contributors working on this codebase.

## What This Is

**Elite Nails** is a single-page marketing website for a family-owned nail salon
in **Cramerton, NC** (202 Market St F, Cramerton, NC 28032 · (704) 824-9032 ·
est. 2003). It is a brochure/landing site — there is **no user auth, no database
models, and no forms**. Its single job is to present the salon and drive
appointment bookings to an external **Square Appointments** URL (with a `tel:`
phone fallback).

It is a **Rails 8 server-rendered app** with a rich, animation-heavy frontend
built on Hotwire (Turbo + Stimulus), GSAP, and Tailwind CSS v4.

## Tech Stack

| Layer      | Choice |
|------------|--------|
| Framework  | Rails 8.0.2 (Ruby 3.2.1) |
| Web server | Puma + Thruster |
| Database   | **PostgreSQL** (all environments). Production uses the multi-DB Solid layout (primary + `_cache`/`_queue`/`_cable`). Content is migrating from code → DB (Milestone 2). |
| Assets     | Propshaft |
| JS bundler | esbuild (`jsbundling-rails`), ESM output to `app/assets/builds/` |
| CSS        | Tailwind CSS v4 CLI (`cssbundling-rails`) |
| Front-end  | Hotwire (`turbo-rails`, `stimulus-rails`) + GSAP 3 (ScrollTrigger, ScrollToPlugin) |
| Icons      | `heroicons` gem (+ custom inline SVGs) |
| Deploy     | **Fly.io** (app `elite-nails-rails`, region `iad`); PostgreSQL (Fly Postgres). Tigris (S3) reserved for Active Storage. |
| Lint       | RuboCop (rails-omakase), Brakeman |
| Test       | Minitest + Capybara + Selenium |
| Node       | 20.8.1 |

## Run & Build

```bash
bundle install && yarn install     # first-time setup
bin/dev                            # Foreman: Rails + esbuild --watch + tailwind --watch
bin/rails server                   # single process (no asset watchers)

yarn build                         # bundle JS -> app/assets/builds
yarn build:css                     # build minified Tailwind CSS

bin/rails test                     # unit/controller tests
bin/rails test:system              # Capybara/Selenium browser tests (needs Chrome)
bundle exec rubocop                # Ruby lint
bin/brakeman                       # security scan
```

`Procfile.dev` runs three processes: `web` (Rails), `js` (esbuild watch),
`css` (tailwind watch). Note `RUBY_DEBUG_OPEN=true` is set on the web process.

## Configuration & Environment

- **`BOOKING_URL`** — the Square Appointments booking link. Read via
  `ApplicationHelper#booking_link`, which falls back to `tel:+17048249032`
  when unset. Set in `.env` (loaded by `dotenv-rails` in dev/test).
- **`GOOGLE_REVIEWS_URL`** — the salon's Google Business reviews/place link. Read
  via `ApplicationHelper#google_reviews_link`, which falls back to a Google Maps
  search for the salon when unset. Used by the Reviews section CTAs.
- **`MCP_AUTH_TOKEN`** — static bearer token for the MCP server (see MCP
  section). One of the two accepted credentials (the other is a Doorkeeper OAuth
  token); MCP auth is always enforced, so with this unset only OAuth tokens work.
  Set in `.env` for dev; **required in production** via `fly secrets`.
- Secrets via Rails credentials (`config/credentials.yml.enc` + `master.key`).
- All salon details (address, phone, hours) are **hardcoded in the views**, not
  in config — see "Editing Content" below.

## Routing & Server Code

The app is essentially static from the server's perspective:

- `config/routes.rb`: `root "pages#home"` + `/up` health check. That's it.
- `PagesController#home` — **empty action**, just renders the view.
- **All page content is DB-backed** (Milestone 2 / A2 complete): `Promotion`,
  `Service`, `PricingItem`, `TeamMember`, `Review`, `SiteSetting` (singleton NAP/
  geo/price/aggregate rating), `BusinessHour`. Each model keeps an in-code
  `DEFAULTS` backup + a `for_display`/`current` method that falls back to it if the
  table is empty/unavailable — so the site always renders and can re-seed from
  code. Photos are still asset files (Active Storage deferred). No jobs/mailers yet.

**Key helper — `app/helpers/application_helper.rb`:**
- `icon(name, variant:, classes:, **opts)` — unified icon helper. Delegates to
  the `heroicons` gem, except custom inline SVGs for `quote`, `instagram`, `branch`.
- `booking_link` — centralized booking URL (see Configuration above). **Always
  use this helper for booking CTAs**, never hardcode the URL.
- `google_reviews_link` — centralized Google reviews URL (env `GOOGLE_REVIEWS_URL`,
  falls back to a Maps search). Used by the Reviews section CTAs.
- `salon` — returns the **`SiteSetting` singleton** (NAP, geo, price range,
  founding year, reviews aggregate), falling back to `SiteSetting::DEFAULTS`.
  Access via methods (`salon.phone_display`), not hash keys. Hours live in
  `BusinessHour` (`grouped_for_display` for the contact list,
  `opening_hours_specification` for JSON-LD). Prefer these over hardcoding.
- `salon_map_embed_url` — keyless Google Maps embed URL for the salon address
  (used by the contact section map iframe).
- `placeholder_image(...)` — currently returns `nil` by design (shows CSS
  placeholder backgrounds instead of real images); kept for future use. Team
  photos currently use it, so they render as placeholders.

**SEO / structured data:** the layout head renders `shared/_meta_tags`
(Open Graph, Twitter card, canonical, geo meta) and `shared/_structured_data`
(`NailSalon` LocalBusiness JSON-LD built from the `salon` helper). Update salon
facts in the `salon` helper, not in these partials.

## View Architecture

The whole site is one page composed from partials. Render order lives in
`app/views/pages/home.html.erb`:

```
navigation → hero → about → story → [services + pricing] → promotions
→ testimonials → team → gallery → contact → safety → cta_banner
→ mobile_sticky_cta → footer
```

**Home sections** (`app/views/pages/home/_*.html.erb`), each with an anchor `id`
used by the nav:

| Partial          | id             | Content |
|------------------|----------------|---------|
| `_hero`          | `#home`        | Headline, dual CTAs, stat cards, hero imagery, "est. 2003" |
| `_about`         | `#about`       | "Welcome to Elite Nails" intro |
| `_story`         | `#story`       | Family-owned since 2003, serving Cramerton/Belmont/Gaston County |
| `_services`      | `#services`    | 6 service cards (defined inline as a Ruby array) |
| `_pricing`       | `#pricing`     | 3 categories (Hands / Feet / Add-Ons) with prices, inline array |
| `_promotions`    | `#specials`    | Featured offer + coupon-style specials, inline arrays (placeholders) |
| `_testimonials`  | `#testimonials`| Client "Kind Words" |
| `_team`          | `#team`        | 3 technicians (Michael K, Nhan Ka, Lien Ka), inline array |
| `_gallery`       | `#gallery`     | 4 gallery items |
| `_contact`       | `#contact`     | Address, phone, hours, Google Maps link (map is a placeholder) |
| `_safety`        | (none)         | Sanitation / cleanliness messaging |
| `_cta_banner`    | (none)         | Closing booking CTA |

**Shared partials** (`app/views/shared/_*.html.erb`): reusable UI components —
`_navigation`, `_mobile_menu`, `_mobile_sticky_cta`, `_footer`, `_logo`,
`_section_header` (eyebrow/title/subtitle), `_cta_button`, `_service_card`,
`_team_member`, `_testimonial_card`, `_stat_card`, `_gallery_item`.

**Editing content:** **all content is DB-backed** — edit the DB records (or the
model's `DEFAULTS` constant + `bin/rails db:seed`). Models: `Promotion`, `Service`,
`PricingItem`, `TeamMember`, `Review`, `SiteSetting` (address/phone/geo/aggregate
rating), `BusinessHour` (hours). Each has an in-code `DEFAULTS` backup so the site
still renders if the DB is empty. Photos remain asset files for now.

## Frontend / Animation System

Animations are the core of the frontend. GSAP is initialized once in
`app/javascript/gsap_init.js`:
- Registers `ScrollTrigger` + `ScrollToPlugin`, sets global defaults.
- **Respects `prefers-reduced-motion`** (near-freezes the global timeline).
- Refreshes/kills ScrollTriggers on `turbo:load` / `turbo:before-cache` so
  animations survive Turbo navigation and caching.

**Stimulus controllers** (`app/javascript/controllers/`, registered in
`index.js`):

| Controller             | Purpose |
|------------------------|---------|
| `hero`                 | Hero entrance timeline (parallax intentionally disabled) |
| `scroll_reveal`        | Fade/slide element in on scroll (`animation`, `delay`, `duration`, `start`, `once` values) |
| `stagger`              | Staggered reveal of child elements (`amount`, `from`, `start`) |
| `parallax`             | Scroll parallax; **desktop only** (skips `<768px`) |
| `smooth_scroll`        | Animated anchor scrolling with 80px header offset |
| `navbar`               | Shrinks navbar / hides logo label after scrolling past 4px |
| `card_hover`           | Card hover micro-interactions |
| `service_image_hover`  | Service card image hover effect |
| `pricing_highlight`    | Flash-glow a pricing category (has public `highlight()` callable by other controllers; wired to `data-pricing-highlight-category-value`) |
| `hello`                | Default Stimulus scaffold (unused) |

When adding a controller, register it in `controllers/index.js` (or run
`bin/rails stimulus:manifest:update`).

## Styling / Design System

Tailwind CSS v4 with a custom theme in
`app/assets/stylesheets/application.tailwind.css` (`@theme` block):
- **Fonts:** `--font-serif` Fraunces, `--font-sans` Manrope, `--font-script`
  Cormorant Garamond.
- **Palettes:** custom `sage`, `peach`, `terracotta`, `cream`, `warm-gray`,
  `gold` (each 50–900). Warm, editorial spa aesthetic.
- Custom utility classes below the theme (warm gradients, glass effects, hero
  orbs/grid, shadow-warm-*).
- `app/assets/builds/` is **generated** — never hand-edit `application.css` /
  `application.js`.

Images live in `app/assets/images/` (hero, service photos, logo, decorative
hands/flowers).

## PWA

Dynamic PWA files exist at `app/views/pwa/` (`manifest.json.erb`,
`service-worker.js`) but the routes are **commented out** in `config/routes.rb` —
the PWA is not currently wired up.

## MCP Server (AI content control — Milestone 2, Phase B)

An MCP server lets an AI agent (Claude) read and edit the salon's DB-backed
content. This is the intended control surface (MCP-only, no admin UI).

- **Endpoint:** `POST /mcp` — **Streamable HTTP** JSON-RPC served by
  `McpController` (`initialize`, `ping`, `tools/list`, `tools/call`;
  notifications → 202; GET/DELETE → 405). fast-mcp's Rack/SSE transport is
  **not mounted** (claude.ai requires Streamable HTTP); the **`fast-mcp`** gem
  provides only the tool layer (`ActionTool::Base` + dry-schema). See
  `config/initializers/mcp.rb`.
- **Auth:** dual-auth via the `McpDualAuth` Rack middleware
  (`lib/middleware/mcp_dual_auth.rb`, runs before the router; answers CORS
  preflights). Accepts EITHER the static `MCP_AUTH_TOKEN` bearer token (Claude
  Code) OR a Doorkeeper OAuth access token (claude.ai). Unauthenticated
  requests get `401` + `WWW-Authenticate: Bearer
  resource_metadata="…/.well-known/oauth-protected-resource"` to trigger OAuth
  discovery (Doorkeeper + `/owner/login` + DCR at `/oauth/register`).
- **Tools** live in `app/tools/` (subclass `ApplicationTool`, registered in
  `McpController::TOOL_CLASS_NAMES`). **All content models are covered** (24
  content tools): per model a `List*`/`Get*` read plus guarded `Create*`/`Update*`
  and a visibility toggle (`Set*ActiveTool`; reviews use `SetReviewApprovedTool`,
  hours use `SetBusinessHoursTool` upserting one weekday per call, site
  settings are a `Get`/`Update` singleton pair). Plus a read-only
  **`GetAnalyticsSummaryTool`** exposing website KPIs (`Analytics::Summary`, see
  `docs/analytics-plan.md`). Shared serializers live on `ApplicationTool`.
- **Guardrails:** dry-schema validates all tool input; every write is recorded in
  **`AuditLog`** (`source: "mcp"`, before/after `details`); **no hard-delete** tool
  (hide via `SetPromotionActiveTool`). Add new tools following this pattern and
  register them in `TOOL_CLASS_NAMES`.

## Booking (Square — Phase D2)

Native on-site booking at **`/book`** (wizard: service → tech → slot → details),
backed by the **Square Bookings API**. Verified end-to-end on Square's **free**
plan (2026-07-19).

- **`SquareApi`** (`app/services/square_api.rb`) — dependency-free Net::HTTP
  client: catalog services, bookable staff, availability search, customer
  upsert, `CreateBooking` (idempotency keys). `BookingsController` proxies it
  as JSON for the `booking` Stimulus controller.
- **Auth model (the critical part):** Square gates Bookings API *writes* by
  token scope, not by API access. A **buyer-scoped OAuth token** (scopes
  `APPOINTMENTS_WRITE`/`READ`, `APPOINTMENTS_ALL_READ`,
  `APPOINTMENTS_BUSINESS_SETTINGS_READ`, `CUSTOMERS_*`, `ITEMS_READ` — never
  `APPOINTMENTS_ALL_WRITE`) can create customer self-bookings **on the free
  plan**. An all-scope personal access token is classified seller-level and
  403s without Appointments Plus ($49/mo) — Plus is only needed for future
  staff-side booking tools.
- **Token lifecycle:** mint once via `GET /square/authorize` →
  `SquareOauthController` (needs `SQUARE_APP_ID`/`SQUARE_APP_SECRET` + the
  redirect URL registered in the Square developer console). The callback
  persists tokens to **`SquareCredential`** (one encrypted row per
  environment; AR encryption keys live in Rails credentials). `SquareApi`
  prefers the stored credential and **lazily refreshes** it ~3 days before its
  ~30-day expiry on the next request (chosen over a cron job because Fly
  machines auto-stop). `ENV["SQUARE_ACCESS_TOKEN"]` is a fallback when no row
  exists.
- **Env:** `SQUARE_ENVIRONMENT` (`sandbox` unless `production`),
  `SQUARE_LOCATION_ID`, `SQUARE_APP_ID`, `SQUARE_APP_SECRET`, optional
  `SQUARE_ACCESS_TOKEN` fallback. Dev `.env` holds the sandbox set.
- **CTAs:** `booking_link` prefers `/book` when `SquareApi.configured?`, else
  `BOOKING_URL` (hosted Square page), else `tel:`. ✅ Square secrets **are** set
  in production — native `/book` is live and serving CTAs there (verified
  2026-07-20).
- **Deep links:** `/book?service_name=<marketing name>` fuzzy-matches home-page
  Service/PricingItem names to a Square catalog service and preselects step 1
  (exact → substring → shared-word match; unmatched names just leave the wizard
  unselected). Home service cards ("Book This") and pricing rows link this way.
  `/book` also shows a "Soonest opening" banner (via `availability/next`) when
  no service is preselected, and a "next opening" jump button when the chosen
  day has no slots.
- **Square gotchas:** service variations must have `team_member_ids` assigned
  or availability errors; staff working hours drive slots; sandbox can't
  simulate paid plans; sandbox sends no real notification emails/SMS.

## Deployment

**Deploys to Fly.io** (this is the chosen host). Config in `fly.toml`:
- App `elite-nails-rails`, primary region `iad`, internal port `8080`, HTTPS forced.
- **PostgreSQL** via Fly Postgres; `DATABASE_URL` is a Fly secret (`fly postgres
  attach`). Multi-DB Solid layout uses separate `_cache`/`_queue`/`_cable`
  databases (see the deploy-steps + CREATEDB gotcha in `docs/cms-ai-roadmap.md`).
- App process: `./bin/thrust ./bin/rails server`; migrations run on boot via
  `bin/docker-entrypoint` (`rails db:prepare`). Machines auto-stop/start.
- **Tigris** (Fly S3-compatible storage) reserved for Active Storage (A2);
  `aws-sdk-s3` retained for it. Litestream/SQLite removed.

```bash
fly deploy        # deploy
fly logs          # tail logs
fly ssh console   # shell into a machine
```

Set production secrets with `fly secrets set …` (`RAILS_MASTER_KEY`, `BOOKING_URL`,
`GOOGLE_REVIEWS_URL`, `MCP_AUTH_TOKEN`, `MCP_OWNER_PASSWORD`, Tigris `AWS_*`).
The Dockerfile is managed by `dockerfile-rails` (`config/dockerfile.yml`).
`thruster` (Rails 8 HTTP/asset accelerator) is retained; the default Kamal
scaffold was removed. ⚠️ Thruster listens on **`HTTP_PORT`** (set to 8080 in
`fly.toml [env]`, matching `internal_port`) — its default :80 can't bind as the
container's non-root user.

> ✅ **Deployed and verified (2026-07-18):** live at
> https://elite-nails-rails.fly.dev with Fly Postgres (`elite-nails-db`,
> attached; app role has CREATEDB so boot-time `db:prepare` creates the Solid
> `_cache`/`_queue`/`_cable` databases). Site, OAuth flow, and all 24 MCP tools
> verified in production.

## Docs & Pending Follow-Ups

Plans and reference docs live in `docs/`. Each plan carries a `Status:` line
near the top — **keep it updated when work lands**, and when the user asks
"what's next?" (or finishes related work), check this index and suggest the
pending items:

| Doc | Status / pending follow-up |
|-----|---------------------------|
| `local-presence-plan.md` | Decided (IG + FB only). **Pending:** social links wiring — gallery link, footer icons, JSON-LD `sameAs` for the knowledge panel; blocked on owner creating accounts. Also: optional `elitenailsnc.com` redirect; GBP takeover → point website/booking fields at the domain and `/book`. |
| `quick-availability-plan.md` | Implemented. **Pending:** automated browser coverage. |
| `deal-alerts-plan.md` | Exploration only — suggest when marketing/email comes up; not yet approved to build. |
| `vip-membership-plan.md` | Exploration only — suggest when loyalty/retention comes up; not yet approved to build. |
| `analytics-plan.md` | Implemented (Ahoy + `GetAnalyticsSummaryTool`); reference for KPI definitions. |
| `cms-ai-roadmap.md` | Milestone 2 vision doc; largely delivered (DB content + MCP tools). |
| `connecting-to-production-db.md` | Reference — how to reach Fly Postgres via `fly proxy`. |

### ⏸️ Pending owner confirmation — gel / dip / acrylic / nail-art menu (2026-07-20)

The owner needs to confirm which enhancement services the salon actually
offers. For now, **the default `<title>` and `<meta name="description">` are
optimized for search-result clicks**: exact brand, Cramerton, nail salon, book
online, and the configured services (`gel`, `dip`, `acrylics`, and `nail art`).
This is defined in `app/views/layouts/application.html.erb` and mirrored in
`app/views/shared/_meta_tags.html.erb`.

These services are named in many other places, and removing them was judged
riskier than leaving them:

- They are **live, bookable services in the owner's Square catalog** (verified
  in production 2026-07-20): `Gel Manicure`, `Gel Pedicure`, `Dip Powder`,
  `Acrylic Full Set`, `Acrylic Fill`, `Nail Art (per nail)`. Square only makes
  a service bookable once staff are assigned to it, so these were configured
  deliberately. Scrubbing the site while `/book` still sells them would hide
  real services.
- `Service` / `PricingItem` records (3 of 6 service cards, 6 priced items),
  `TeamMember` bios + specialties, an active `Tues–Thurs Gel Special`
  `Promotion`, and two `_faq.html.erb` entries all reference them.
- One `Review` quote mentions gel manicures — **never edit customer
  testimonials**; altering a real review is fabrication regardless of intent.

**If the owner confirms these are not offered**, the fix is to remove them at
the source (Square catalog) first, then hide the corresponding records via the
MCP `Set*ActiveTool` tools, then update the meta description. Do not edit
marketing copy alone. Note the content is DB-backed, so editing `DEFAULTS` in
code will not change production.

## Conventions

- **Ruby:** 2-space indent, snake_case methods, CamelCase classes; rails-omakase
  RuboCop config.
- **JS:** ES modules, Stimulus controllers named `*_controller.js`.
- **CSS:** Tailwind utilities; custom CSS only in `application.tailwind.css`.
- **Commits:** Conventional Commits (`feat:`, `fix:`, `chore:` …), imperative,
  lowercase, no trailing period, ≤72 chars. No body/co-author lines unless asked.
- **Tests:** `test/{models,controllers,system}`, files `*_test.rb`, fixtures in
  `test/fixtures`.
- Never commit `.key` files or secrets. `storage/` (Active Storage) stays out of
  commits.

## Gotchas

- Dev/test and **production** all run on **Postgres** (prod: Fly Postgres via
  `DATABASE_URL`). Seeds are idempotent and sourced from each model's in-code
  `DEFAULTS`; a fresh production DB seeds itself on first boot via `db:prepare`.
- The action is empty and most content is still in code — to change what the site
  says, edit the **view partials**, not a controller or model.
- Booking CTAs must route through `booking_link`; the site degrades to a phone
  link if `BOOKING_URL` is unset.
- Team photos render as placeholders until `placeholder_image` returns real
  assets. The contact map is now a live keyless Google Maps embed
  (`salon_map_embed_url`).
- Rebuild assets (`yarn build`, `yarn build:css`) after JS/CSS changes — the dev
  server watches, but production/precompile needs a fresh build.
