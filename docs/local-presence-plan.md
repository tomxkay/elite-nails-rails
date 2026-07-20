# Local Presence Plan — Domain & Social Media

Status: Decided; site wiring pending (blocked on owner creating the accounts
and taking over the Google Business Profile)

Findings and decisions from the 2026-07-20 review. Goal: get prospects into the
salon. Context: site analytics (30 days to 2026-07-20) showed ~24 visits, 22 of
them direct — discovery, not on-site UX, is the bottleneck.

## Domain

**Decision: `elitenailscramerton.com` is the primary and only promoted domain.**

- It is the strongest choice for local SEO: business name + city matches what
  people search and what the Google Business Profile will show. All promotion
  (GBP, socials, print) points here. Verify it is attached to the Fly app and
  is the canonical URL Google indexes — not `elite-nails-rails.fly.dev`.
- **Declined: `elitenails.salon` (~$55 offer).** Not a one-time buy — `.salon`
  renews at ~$46–60/yr indefinitely, keyword TLDs carry no Google ranking
  benefit, and no prospect types `.salon`.
- **Optional: `elitenailsnc.com` (~$11/yr, available as of 2026-07-20).** Worth
  registering only as a short, sayable 301 redirect for print/spoken use
  (business cards, window decal, phone). Set up via Namecheap's Redirect
  Domain feature pointing at `https://elitenailscramerton.com` — no DNS work
  on the Fly side.
- Availability snapshot (registry RDAP, 2026-07-20): `elitenails.com`, `.net`,
  and `elitenailsspa.com` are taken; `cramertonnails.com`, `elitenails.studio`
  / `.beauty` / `.spa` were available but not worth pursuing.

## Social media

**Decision: Instagram + Facebook only.** Two platforms done properly beat four
done badly; a profile that visibly stopped posting reads as "probably closed."

- **Instagram (primary).** Nails are a visual purchase — the grid is the menu.
  Claim `@elitenailscramerton` to match the domain. Booking link in bio,
  location Cramerton. Content: real sets, before/afters, seasonal colors from
  the salon phone — 2–3 honest posts/week beats occasional polished ones.
  The same photos should feed the site's gallery section (currently only 4
  items — the biggest on-site trust gap).
- **Facebook (secondary).** Local recommendation groups and the small-town NC
  demographic live there; a Page adds reviews, check-ins, and is required for
  any future local ads. Can largely re-share Instagram content. Also list the
  business on **Nextdoor** — local recommendation threads convert well.
- **Others:** register the TikTok handle defensively but leave it unused
  unless someone genuinely wants to film. Skip X/LinkedIn.

## Site wiring (TODO once accounts exist)

Linking the site and profiles both ways strengthens the Google **knowledge
panel**: `sameAs` entries in the JSON-LD tell Google the profiles and the
website are the same business entity, consolidating reviews/photos/signals
under one listing.

- [ ] Replace the dead "Follow us on Instagram" link in
      `app/views/pages/home/_gallery.html.erb` (currently `href="#"`).
- [ ] Add Instagram + Facebook icons/links to `app/views/shared/_footer.html.erb`
      (an `instagram` icon already exists in the `icon` helper).
- [ ] Add `sameAs: [instagram_url, facebook_url]` to the `NailSalon` JSON-LD in
      `app/views/shared/_structured_data.html.erb` — this is the piece with
      actual SEO value.
- [ ] Store the profile URLs the same way as other salon facts (`SiteSetting`
      singleton or env vars per the `GOOGLE_REVIEWS_URL` pattern) rather than
      hardcoding in views.
- [ ] After GBP ownership is transferred: point the GBP website field at
      `elitenailscramerton.com` and its booking button at `/book`.

Prerequisite for all of the above: the owner creates the accounts; the site
wiring itself is a small change once URLs exist.
