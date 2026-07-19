# Analytics & KPI Plan — First-Party Metrics with Ahoy

Plan for adding **first-party visitor analytics** to Elite Nails so the salon can
answer real business questions ("is the website driving bookings, and where do
customers come from?") and accumulate raw behavioral data to mine for KPIs over
time.

_Created: 2026-07-19. Status: PLANNING (no code written yet)._
Parent planning doc: [`../PROJECT.md`](../PROJECT.md) · Related: [`cms-ai-roadmap.md`](cms-ai-roadmap.md).

## Goal

Turn the site from a black box into a **measurable funnel**. Two horizons:

1. **Now (the 80/20):** answer a handful of concrete questions the owner cares
   about — reach, traffic source, and where the booking funnel leaks.
2. **Later (the ceiling):** accumulate a raw, first-party event stream in our own
   Postgres so we can mine it for deeper "connections" and KPIs as traffic grows.

The guiding principle: **"log everything" as a _schema_ (flexible JSONB events),
not as _day-one instrumentation_.** Capture richly; instrument only the events
that map to a question someone will actually read. Adding noise (scroll depth,
heatmaps, every hover) is cost with no reader until a real question demands it.

## Decision

**Use the `ahoy_matey` gem — first-party, anonymized.**

| Choice | Decision | Why |
|--------|----------|-----|
| Approach | **Ahoy (first-party)** | Stores Visits + Events in **our** Postgres with a JSONB `properties` bag. Gives visit/session stitching, referrer + UTM attribution, device/browser parsing, and coarse geo-from-IP for free — the exact substrate for "connections over time." |
| vs. Bespoke `Event` model | Rejected | Would re-hand-roll exactly what Ahoy already does well (stitching, UTM/UA parsing, geo). Real hours for a worse result; the only upside (zero deps) isn't worth it. |
| vs. Third-party (GA4/Plausible/PostHog) | Rejected | Data lives off-site, aggregated/sampled, weak for arbitrary joins. Would also add a tracker to a currently **tracker-free** site (fast, clean, no consent banner). Owning the raw stream is the whole point. |
| Privacy posture | **Anonymized** | Mask IPs, keep coarse city/region + device class. Nearly free to choose, answers all target questions, and avoids PII liability (GDPR/CCPA consent obligations) for marginal analytical gain on a salon site. |

### Cost vs. usefulness (why this fits *now*)

- Low build cost: gem + 2 tables + migration + small JS + ~6 events.
- Low ongoing cost: Ahoy is mature; data is in Postgres we already run.
- Honest caveat: at this traffic volume (a single-location salon), statistical
  "connections" stay thin for a while. The near-term value is the **booking
  funnel + attribution**, not data mining. Logging now is what makes the deeper
  analysis possible later.

## Questions we can answer (the promises)

### Free from the `visits` table
- Visits / unique visitors, week-over-week; trend over time.
- New vs. returning visitors.
- **Device mix** (mobile vs. desktop vs. tablet) — validates the mobile-first UX.
- Browser / OS breakdown.
- **Coarse geography** — are visitors local (Cramerton/Belmont/Gaston County)?

### Acquisition — where customers come from
- **Traffic sources**: Google search, Instagram, direct, referral.
- **UTM campaigns** — measure a specific tagged Instagram/Google link's visits
  *and* bookings.
- Top landing pages (homepage vs. direct `/book` links).

### Behavior & engagement
- Which CTAs get clicked (phone vs. book-online vs. Square fallback).
- Time of day / day of week people browse (when to post, when to staff).

### The booking funnel — the money question (custom events)
See exactly where people drop between intent and confirmed booking:

```
book_cta_clicked   1000
  → book_page_opened   820   (never loaded the page)
    → service_selected  610   (bounced before picking a service)
      → slot_selected    430
        → booking_submitted 300
          → booking_completed 280  (failed at Square / gave up)
```

Because event `properties` is JSONB, this slices by *which service*, *which
technician*, *which day/time*, and *booked price* — minable later with no schema
change.

### Conversion & KPIs — joining visits ↔ events
- **Site conversion rate** = bookings ÷ visits. The headline "is this site worth
  it?" number.
- **Conversion by source** — do Instagram visitors book more than Google ones?
- **Conversion by device** — does mobile convert as well as desktop? (If not,
  that's a UX bug worth money.)
- **Bookings over time vs. visits over time** — did a marketing push move
  bookings, not just traffic?

## Explicit limits (what Ahoy will NOT tell us)

- **Nothing off-site.** When the native `/book` flow is off and a visitor clicks
  through to the **hosted Square page**, we only know they *clicked*, not that
  they booked. Native `/book` is fully tracked; the Square fallback is a blind
  spot.
- **No individual identity** (by design — we anonymize). Aggregate patterns, not
  "Jane visited 3 times."
- **No heatmaps / mouse movement / scroll depth** unless we add instrumentation
  later (deliberately deferred).
- **Thin statistics at low traffic.** Early per-source/per-device percentages are
  noisy; *trends* become trustworthy only as volume accumulates.

## Proposed first slice (scope)

Small, self-contained PR:

1. Add `ahoy_matey`; migrate `visits` + `events` tables.
2. Anonymized Ahoy config (mask IP, coarse geo, respect DNT).
3. Automatic page-view / visit tracking.
4. ~8 KPI events via one small helper:
   `book_cta_clicked`, `book_page_opened`, `service_selected`, `slot_selected`,
   `booking_submitted`, `booking_completed`, `phone_click`,
   `square_fallback_clicked`.
5. One or two query objects so owner-facing numbers (visits, conversion rate,
   funnel drop-off, top sources) are a method call, not raw SQL.

### Deferred (not in the first slice)
- Owner-facing dashboard / reporting UI (query in console or add Blazer later).
- Richer engagement instrumentation (scroll depth, section views, heatmaps).
- Off-site (hosted Square) conversion attribution.
- Exposing metrics through the MCP server.
