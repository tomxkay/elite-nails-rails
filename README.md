# Elite Nails

Marketing website for **Elite Nails**, a family-owned nail salon in Cramerton, NC
(est. 2003). A single-page, server-rendered Rails 8 site that gives the salon a
digital presence and drives clients to book appointments.

> For a deeper architecture and feature map, see [`AGENTS.md`](AGENTS.md).
> Project goals and roadmap live in [`PROJECT.md`](PROJECT.md).

## Requirements

- **Ruby** 3.2.1 (see `.ruby-version`)
- **Node** 20.8.1 (see `.node-version`)
- **Yarn** (for JS/CSS dependencies)
- SQLite 3 (bundled on most systems)
- Chrome + WebDriver (only for system tests)

## Getting Started

```bash
# 1. Install dependencies
bundle install
yarn install

# 2. Configure environment
cp .env.example .env   # if present; otherwise create .env
# Set BOOKING_URL to the Square Appointments link.
# If unset, booking buttons fall back to tel:+17048249032

# 3. Set up the database (Solid Cache/Queue/Cable use SQLite)
bin/rails db:prepare

# 4. Run the app (Rails + esbuild + Tailwind watchers on port 3000)
bin/dev
```

Then visit http://localhost:3000.

`bin/dev` runs three processes via Foreman (`Procfile.dev`): the Rails server,
the esbuild JS watcher, and the Tailwind CSS watcher. Use `bin/rails server`
alone if you don't need the asset watchers.

## Configuration

| Variable             | Purpose                                                 |
|----------------------|---------------------------------------------------------|
| `BOOKING_URL`        | Square Appointments booking link used by all "Book" CTAs. Falls back to `tel:+17048249032` when unset. |
| `GOOGLE_REVIEWS_URL` | Google Business reviews/place link used by the Reviews section CTAs. Falls back to a Google Maps search when unset. |

`BOOKING_URL` is read in `.env` (via `dotenv-rails`) in development/test.
Secrets otherwise live in Rails credentials (`config/credentials.yml.enc` +
`master.key`).

## Building Assets

```bash
yarn build        # bundle JS -> app/assets/builds (esbuild, ESM)
yarn build:css    # build minified Tailwind CSS -> app/assets/builds
```

The dev server watches automatically; run these manually before precompiling for
production. Files in `app/assets/builds/` are **generated** — do not hand-edit.

## Testing & Quality

```bash
bin/rails test          # unit + controller tests (Minitest)
bin/rails test:system   # browser/system tests (Capybara + Selenium, needs Chrome)
bundle exec rubocop     # Ruby lint (rails-omakase)
bin/brakeman            # security scan
```

## Deployment

Deployed to [Fly.io](https://fly.io) (app `elite-nails-rails`, region `iad`).
Production runs SQLite on a persistent volume at `/data`, with
[Litestream](https://litestream.io) replicating it to Tigris object storage for
durability. Configuration lives in `fly.toml`.

```bash
fly deploy        # build + deploy
fly logs          # tail logs
fly ssh console   # shell into a running machine
```

Set production secrets (not committed) with Fly:

```bash
fly secrets set BOOKING_URL=… GOOGLE_REVIEWS_URL=…
```

> The repo also contains the default Kamal scaffold (`config/deploy.yml`,
> `.kamal/`) from `bin/rails new`, but it is **unused** — Fly.io is the
> deployment path.

## Project Structure

Single-page site rendered from `app/views/pages/home.html.erb`, composed of
section partials in `app/views/pages/home/` and reusable components in
`app/views/shared/`. Frontend animation uses Stimulus controllers
(`app/javascript/controllers/`) built on GSAP. See [`AGENTS.md`](AGENTS.md) for
the full breakdown.
