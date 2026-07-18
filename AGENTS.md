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
| Database   | SQLite 3 (Solid Cache / Solid Queue / Solid Cable — all SQLite-backed) |
| Assets     | Propshaft |
| JS bundler | esbuild (`jsbundling-rails`), ESM output to `app/assets/builds/` |
| CSS        | Tailwind CSS v4 CLI (`cssbundling-rails`) |
| Front-end  | Hotwire (`turbo-rails`, `stimulus-rails`) + GSAP 3 (ScrollTrigger, ScrollToPlugin) |
| Icons      | `heroicons` gem (+ custom inline SVGs) |
| Deploy     | Kamal (Docker), service name `elite_nails` |
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
- Secrets via Rails credentials (`config/credentials.yml.enc` + `master.key`).
- All salon details (address, phone, hours) are **hardcoded in the views**, not
  in config — see "Editing Content" below.

## Routing & Server Code

The app is essentially static from the server's perspective:

- `config/routes.rb`: `root "pages#home"` + `/up` health check. That's it.
- `PagesController#home` — **empty action**, just renders the view.
- No models (`app/models` has only `ApplicationRecord`), no jobs, no mailers in use.

**Key helper — `app/helpers/application_helper.rb`:**
- `icon(name, variant:, classes:, **opts)` — unified icon helper. Delegates to
  the `heroicons` gem, except custom inline SVGs for `quote`, `instagram`, `branch`.
- `booking_link` — centralized booking URL (see Configuration above). **Always
  use this helper for booking CTAs**, never hardcode the URL.
- `google_reviews_link` — centralized Google reviews URL (env `GOOGLE_REVIEWS_URL`,
  falls back to a Maps search). Used by the Reviews section CTAs.
- `salon` — **single source of truth** for the salon's NAP (name/address/phone),
  hours, geo, price range, and founding year. Used by the SEO structured data;
  prefer it over re-hardcoding contact details in new views.
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
navigation → hero → about → story → [services + pricing] → testimonials
→ team → gallery → contact → safety → cta_banner → mobile_sticky_cta → footer
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

**Editing content:** Service list, prices, team members, and testimonials are
defined as **inline Ruby arrays inside their partials** (not a CMS/DB). Salon
address, phone `(704) 824-9032`, and hours (Mon–Fri 10–7, Sat 9–6, Sun closed)
are hardcoded in `_contact`. Update those files directly to change content.

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

- The action is empty and there's no DB-backed content — to change what the site
  says, edit the **view partials**, not a controller or model.
- Booking CTAs must route through `booking_link`; the site degrades to a phone
  link if `BOOKING_URL` is unset.
- The contact **map is a styled placeholder**, not an embedded map; team photos
  render as placeholders until `placeholder_image` returns real assets.
- Rebuild assets (`yarn build`, `yarn build:css`) after JS/CSS changes — the dev
  server watches, but production/precompile needs a fresh build.
