# Elite Nails — Project Goals & Roadmap

> Living document. Captures the *why* and *what* of this project so feature work
> stays aligned with the goal. Technical/architecture reference lives in
> [`AGENTS.md`](AGENTS.md).

_Last updated: 2026-07-18_

## The Client

- **Elite Nails** — a **family-owned and operated** nail salon in Cramerton, NC
  (202 Market St F · (704) 824-9032 · est. 2003).
- The owners are **not tech-savvy**. A website is a resource they have **not yet
  tapped** to drive business.
- This is their first real digital presence. They rely today on walk-ins, phone,
  and word of mouth.

## The Goal

> **Give Elite Nails a warm, authentic digital home that turns visitors into
> booked appointments.** A fast, mobile-first landing site that captures the
> personality of a family-run salon, showcases the real people and their work,
> and makes booking effortless for both new and returning clients.

**This site succeeds when it:**
1. Establishes a credible, professional digital presence they can point people to.
2. Converts visitors into customers across **all channels, balanced** — online
   bookings, phone calls, *and* walk-ins. No single funnel dominates; the site
   makes every path easy.
3. Feels **personal and human** — not templated or "AI-generated."
4. Serves **new clients** (discovery, trust, first booking) *and* **existing
   clients** (quick rebooking, hours, specials).

### Design North Star
Modern and sophisticated, but **warm, editorial, and hand-crafted**. The current
theme (Fraunces/Manrope typography, terracotta/sage/cream palette) is a good
foundation but currently reads as robotic/generic. We want it to feel like *this
specific family's salon*. Confirmed emphasis for de-robotizing the design:
1. **Real photography** — authentic photos of the team, salon, and their work,
   replacing placeholders/stock feel.
2. **Distinctive layout** — break out of default component patterns; unique
   section layouts, asymmetry, hand-crafted touches.
3. **Refined motion & polish** — intentional, subtle animation and
   micro-interactions rather than generic reveal-on-scroll everywhere.

(Personal, human copy is still core to the About/Team work below — it just wasn't
called out as a separate design lever.)

## Guiding Principles

- **Booking is the primary call to action** everywhere; degrade gracefully to
  phone.
- **Mobile-first** — most local-salon traffic is on phones.
- **Personal over polished-generic** — real names, real faces, real stories,
  real work.
- **Fast & accessible** — respects reduced-motion, loads quickly, readable.
- **Low-maintenance** — owners aren't technical; content updates should be simple
  and infrequent.

## What Exists Today (Baseline)

Single-page site with these sections: hero, about, story, services (6 cards),
pricing (3 categories), testimonials, team (3 techs), gallery (4 items), contact
(address/phone/hours + map placeholder), safety, and closing CTA. Booking routes
to a Square Appointments URL via `BOOKING_URL`. Content is hardcoded in view
partials. See `AGENTS.md` for detail.

**Known gaps / placeholders:**
- Team photos are placeholders (`placeholder_image` returns `nil`).
- Contact map is a styled placeholder, not an embedded map.
- Team bios and "About/Story" copy are generic — not yet personal.
- Testimonials/gallery content may be filler.

## Feature Backlog (prioritized)

Ideas to make the site enticing + helpful. **★ = confirmed priority.**

- ★ **Personal About / Meet the Team** — real photos, personal stories, each
  tech's specialty and personality. *(Top priority — explicitly requested.)*
- ★ **Promotions / seasonal specials** — a simple way to surface current offers.
- ★ **Local SEO & map** — meta tags, `LocalBusiness` structured data, real map
  embed, Google Business alignment so they rank and are easy to find.
- ★ **Reviews / social proof** — real Google reviews and ratings to build trust.
- **Booking setup** — online booking is **not set up yet** (see decision below).
  Establishing a real booking flow is a prerequisite for a strong booking CTA.
- **Real photo gallery** — actual nail work + salon interior; possibly an
  Instagram feed embed. *(Not selected as a top priority this round.)*
- **Services deep-dive** — richer descriptions, durations, "what to expect."
- **Gift cards** — if the salon offers them.
- **Loyalty / returning-client hooks** — reasons for existing clients to return.

## Key Constraint: Booking Is Not Set Up Yet

There is **no live online booking**. All "Book" CTAs currently fall back to the
phone number via `booking_link`. Until a provider is chosen, the site emphasizes
**call / walk-in** paths (fits the "all channels balanced" metric in the interim)
and treats booking as a placeholder to drive the design.

**Recommendation: use a hosted service, do NOT build our own.** Building booking
(staff calendars, availability, deposits/PCI payments, reminders, no-show &
reschedule logic) is high-scope, money-critical, and high-maintenance — a poor
fit for non-technical owners and an ongoing liability for us.

- **Leading choice: Square Appointments** — free tier, SMS reminders,
  "Reserve with Google" (reinforces the local-SEO priority), and the codebase
  already assumes it (`BOOKING_URL`). Best if the salon already uses Square POS.
- **Alternatives:** Fresha or Booksy — beauty-specific platforms whose
  marketplaces can drive *new-client discovery*; consider if discovery outweighs
  simplicity. Fresha is free to the business (fee on new-client bookings).
- **Deciding factor:** what POS / payment system do they use today? Nail salons
  commonly already run Square — if so, Square Appointments is the natural pick.

## Roadmap (phased — draft)

- **Phase 1 — Foundation & Real Content:** Gather + place real photos and
  personal copy; personalize About & Team; wire up map + `LocalBusiness` SEO;
  confirm hours/prices/services; decide + set up the booking flow (or keep phone
  fallback). *Make what exists true, personal, and findable.*
- **Phase 2 — Conversion & Trust:** Real Google reviews, promotions/specials
  module, richer services, balanced booking/call/walk-in CTAs.
- **Phase 3 — Design Elevation:** Distinctive layouts and refined motion to shed
  the "AI-generated" feel; gallery/Instagram, gift cards, loyalty, analytics.

_(Phases refined as details below are confirmed.)_

## Open Questions

To be answered with the client. Grouped by theme; update inline as we learn more.

### The people & story (for a personal About/Team)
- Who are the owners/family? Names, relationship, who founded it and why?
- The real story of the salon — how it started in 2003, what makes it special,
  the family's connection to Cramerton?
- Each technician: real name, years of experience, specialties, personality,
  a favorite service, a fun fact? (Current names: Michael K, Nhan Ka, Lien Ka —
  are these correct/complete?)
- Do we have (or can we get) real, high-quality photos of the team and salon?

### Business details
- What POS / payment system do they use today (Square, Clover, other)? — this
  decides the booking provider (see Booking constraint section).
- Do they want online booking set up (recommended: Square Appointments), or
  phone-only for now?
- Are the current prices and services accurate and complete?
- Are the hours correct (Mon–Fri 10–7, Sat 9–6, Sun closed)?
- Do they offer gift cards? Loyalty/rewards? Group/party bookings?
- Any current promotions or seasonal specials to feature?
- Social media accounts (Instagram, Facebook, Google Business)?
- **Google Business profile / reviews URL** (for `GOOGLE_REVIEWS_URL`) + their
  real average rating and review count (Reviews section currently uses
  placeholder `4.9` / `120+` and placeholder review text).
- **Exact salon geo coordinates** (lat/lng) for the LocalBusiness structured
  data — currently approximate (35.2387, -81.0737).

### Deployment — RESOLVED: Fly.io
- **Fly.io is the deployment path** (app `elite-nails-rails`, region `iad`;
  SQLite on a persistent volume + Litestream → Tigris). Documented in `AGENTS.md`
  and `README.md`. The default **Kamal scaffold** (`config/deploy.yml`, `.kamal/`,
  `bin/kamal`, `kamal` gem) has been **removed** (2026-07-18 cleanup). `thruster`
  is retained (referenced by the Dockerfile CMD).

### Goals & priorities
- What does "driving customers" mean to them — more online bookings, more calls,
  more walk-ins, or all three?
- Who is the target client (demographics, new vs. returning emphasis)?
- Any competitors/salons whose sites they admire (or dislike)?

## Progress Log

- **2026-07-18 — Editorial polish: Pricing, Contact, Safety.** Added the shared
  ambient grid backdrop (`hero-grid-lines`) to all three so every content section
  reads as one system. Pricing category headers now use the serif + numbered
  (01/02/03) treatment matching Team/Services, with a divider. Contact and Safety
  wrapped with the backdrop; content kept intact (map, hours, pricing-highlight
  wiring all preserved). Verified via screenshots.
- **2026-07-18 — Cleanup pass.** Removed the unused Kamal deploy scaffold
  (`config/deploy.yml`, `.kamal/`, `bin/kamal`, `kamal` gem, `.dockerignore`
  entries; Dockerfile comment updated) now that Fly.io is the confirmed host —
  `thruster` retained (Dockerfile CMD uses it). Removed the now-unused
  `service-image-hover` Stimulus controller (+ registration) and its dead CSS
  (`service-card-image/-glow/-stack`, `shadow-warm-2xl`) left over from the
  Services redesign. Rebuilt JS + CSS; verified the site still boots (200) with
  no stale references.
- **2026-07-18 — Phase 1: Services section editorial pass.**
  Replaced the emoji-forward card grid with **image-forward** editorial cards
  (real service photos front-and-center — the photography lever): numbered labels
  (01–06), serif title overlaid on a warm gradient scrim, "Most Loved" badge on
  the featured card, refined image-zoom + lift hover, description + "View Pricing"
  link. Added the ambient grid backdrop for consistency and preserved the
  "View Pricing → flash matching pricing category" wiring. Dropped the unused
  `emoji` field; the old `service-image-hover` controller/CSS are now unused (left
  registered, harmless — candidate for cleanup). Files:
  `app/views/shared/_service_card.html.erb`, `app/views/pages/home/_services.html.erb`.
  Verified via headless-browser screenshot.
- **2026-07-18 — Phase 2: Promotions / Specials section added.**
  New `#specials` section (rendered after pricing, before reviews) surfacing
  current offers in a distinctive **coupon/ticket** style (kept visually separate
  from the terracotta closing CTA banner): a full-width featured "New Guests —
  15% off first visit" offer with a badge and dashed divider, plus three
  coupon cards (Refer a Friend, Birthday Treat, Tues–Thurs Gel Special) with
  peach deal stubs. Data-driven from inline arrays for easy editing. Files:
  `app/views/pages/home/_promotions.html.erb`, `app/views/pages/home.html.erb`.
  Verified via headless-browser screenshot. **All offers are placeholders** —
  confirm real specials with the salon (see open questions).
- **2026-07-18 — Phase 1: Local SEO + real map embed.**
  Added `NailSalon` LocalBusiness structured data (JSON-LD: name, address, geo,
  phone, hours, price range, founding date) and social/local meta (Open Graph,
  Twitter card, canonical, geo tags) via new `shared/_structured_data` and
  `shared/_meta_tags` partials wired into the layout head. Replaced the contact
  "Map Placeholder" with a live, **keyless Google Maps embed**. Centralized the
  salon's NAP/hours/geo in an `ApplicationHelper#salon` hash (single source of
  truth) plus a `salon_map_embed_url` helper. Files:
  `app/helpers/application_helper.rb`, `app/views/shared/_meta_tags.html.erb`,
  `app/views/shared/_structured_data.html.erb`,
  `app/views/layouts/application.html.erb`,
  `app/views/pages/home/_contact.html.erb`. Verified head output + map render.
  **Note:** salon geo coordinates (35.2387, -81.0737) are approximate — verify
  exact lat/lng before launch.
- **2026-07-18 — Phase 1: Reviews section rebuilt (Google-reviews-ready).**
  Reworked the "Kind Words" section (`#testimonials`, the nav "Reviews" target)
  into a trust-focused reviews block in the editorial language: an **aggregate
  rating panel** (big serif score, gold stars, review count, "Read Reviews on
  Google" + "Leave a Review" CTAs) above an **organic masonry** of review cards
  (avatar initial, name, relative date, stars, quote, "Posted on Google" tag).
  Added a configurable `google_reviews_link` helper (env `GOOGLE_REVIEWS_URL`,
  falls back to a Maps search). Files: `app/views/pages/home/_testimonials.html.erb`,
  `app/views/shared/_testimonial_card.html.erb`,
  `app/helpers/application_helper.rb`. Verified via headless-browser screenshot.
  **Placeholder data:** the `4.9` rating, `120+` count, and all review text/names
  are placeholders pending real Google reviews.
- **2026-07-18 — Phase 1: About & Story sections given the editorial treatment.**
  Reworked both to share the Team section's design language so the page reads as
  one system: ambient backdrops (grid lines + soft orbs), oversized serif/script
  watermarks, script-font pull-quotes, and generous ~85vh rhythm. **About** now
  leads with a large serif headline (italic terracotta accent) and an editorial
  2×2 stats panel (big serif numerals) with a faint "2003" watermark. **Story**
  presents the salon photo in the **same arched, blended frame as the team
  portraits** (terracotta ambient blob + `portrait-ground` shadow), with an "est."
  watermark, a script pull-quote, the family narrative, a "Since 2003" caption
  badge, and a script signature line. Removed the old aggressive negative-margin
  overlap for a cleaner scroll-rich flow. Files:
  `app/views/pages/home/_about.html.erb`, `app/views/pages/home/_story.html.erb`.
  Verified via headless-browser screenshots.
- **2026-07-18 — Phase 1: Team section redesigned (design-against-placeholders).**
  Replaced the 3-card grid with an editorial, **alternating (zig-zag) full-height
  layout** — each member ~80vh, two columns (portrait / content) that swap sides
  per member for a long, scroll-rich page. Portraits are designed as
  **background-removed cutouts on a soft ambient color blob** (terracotta/sage,
  alternating) with an oversized initial watermark and a grounding shadow —
  deliberately *not* framed rectangles. Added personal touches: index numeral,
  a `quote` line in each tech's voice, specialty chips, and a per-person
  "Book with [name]" CTA (routes through `booking_link`). Placeholder standing in
  for edited cutout photos shows a "Photo coming soon" arched shape.
  Files: `app/views/pages/home/_team.html.erb`,
  `app/views/shared/_team_member.html.erb`, CSS utilities in
  `application.tailwind.css` (`portrait-backdrop-*`, `portrait-ground`).
  Verified rendering via headless-browser screenshots.

## Decisions Log

_(Record confirmed decisions here as we make them, with date.)_

- 2026-07-18 — Project goal drafted (above); site remains a single-page,
  conversion-focused landing site.
- 2026-07-18 — **Success = all channels balanced** (online bookings + calls +
  walk-ins), not a single funnel.
- 2026-07-18 — **Online booking is NOT set up yet.** Booking CTAs use the phone
  fallback until a provider (likely Square) is set up. Booking setup is a Phase 1
  decision.
- 2026-07-18 — **Confirmed priority features:** personalized About/Team (top),
  promotions & specials, local SEO & map, reviews & social proof.
- 2026-07-18 — **Design de-robotizing levers:** real photography, distinctive
  layout, refined motion & polish.
- 2026-07-18 — **Deployment = Fly.io** (app `elite-nails-rails`, region `iad`,
  SQLite + Litestream → Tigris). Unused Kamal scaffold removed in cleanup.
