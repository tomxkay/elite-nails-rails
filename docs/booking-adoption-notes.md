# Online Booking — Adoption & Rollout Notes

**Status:** 🟡 Active — soft launch. Phone is the primary booking channel; online
booking is live but deliberately limited.

**Last updated:** 2026-07-21

## Why this doc exists

The site has a lot of engineering behind native Square booking (`/book`, the
wizard, `SquareApi`, `SquareCredential`, deep links, availability endpoints).
Anyone reading the code would reasonably assume online booking is *the* booking
method. **It is not.** This doc records the business context so future changes
don't over-commit the site to a channel the salon hasn't fully adopted.

## The situation (as of 2026-07-21)

Elite Nails is family-owned. The staff are long-tenured and prefer taking
appointments **by phone** — that's the established workflow and it works for
them.

- **The other technicians** are not on board with online booking. Change is
  hard, and phone-in is what they know.
- **The owner (Tom's dad)** is on the fence. He likes the technology in
  principle, but is concerned about the operational load: he doesn't believe he
  can monitor an incoming online schedule *and* stay focused on the client in
  his chair. That's a legitimate workflow concern, not a technophobia problem —
  treat it as such.
- **The case being made to him:** online booking isn't a replacement for the
  phone, it's an *additional* intake channel. Some people won't call — they'd
  rather book at 11pm from their couch than talk to a stranger. Those bookings
  are otherwise lost. And the salon keeps control: which services are bookable,
  which staff are bookable, and what days/times are exposed are all
  configurable.

## What this means for the product

Design decisions should follow from this, not fight it:

1. **The phone number is never secondary.** Any booking surface must show it as
   a first-class option. Don't build flows that make calling feel like the
   fallback for people who failed at the website.
2. **Online booking stays opt-in per service and per technician.** Currently
   only **Michael** is bookable online, and only 14 of 24 menu items are
   `bookable: true` (see `docs/service-menu-reconciliation.md`). Short/add-on
   work — polish changes, repairs, trims, waxing — is intentionally excluded so
   the online calendar stays low-volume and predictable.
3. **Exposure is the pressure valve.** If the owner feels overwhelmed, the fix
   is operational, not a code change: narrow the bookable hours, reduce bookable
   services, or add buffer time in Square. That knob is more useful to him than
   any UI we can build, and it's worth telling him it exists — it's the direct
   answer to "I can't watch a schedule and work at the same time."
4. **Set expectations on-site.** Visitors should understand that online booking
   covers select services and that calling is welcome and normal. See below.

## On-site messaging

We surface the limits rather than hiding them:

- **Pricing section** — a legend distinguishes online-bookable rows from
  walk-in/phone rows ("Bookable online — everything else is walk-in or by
  phone").
- **Service cards** — no per-card "Book This" CTA. Cards are *categories*, and
  two of them (Nail Care, Waxing) contain nothing bookable, so the CTA promised
  a path that didn't exist. Removed 2026-07-20.
- **`/book` page** — a note near the top of the wizard explains that online
  booking covers select services with select technicians, and that anything else
  is a phone call away.

**Deliberate wording choice:** the on-site copy does *not* say the salon is
"experimenting with" or "transitioning to" online booking, even though that's
accurate internally. Telling customers a booking system is an experiment invites
them to distrust it — the likely reaction is "I'd better call to make sure it
went through," which produces *more* phone load, not less, and makes the feature
look worse than it is. The copy instead states the limits as a normal policy
(select services, select staff, phone for everything else), which is equally
honest and doesn't undermine the bookings we do want.

## Open questions / future decisions

- **Do other technicians opt in?** Gated on the owner's comfort and on whether
  the first weeks produce real bookings without disruption. Adding a tech is
  Square-side (assign them to service variations) plus flipping `bookable` on
  their `TeamMember` record.
- **Should more services become bookable?** Same gate. Revisit once there's real
  booking volume to reason about.
- **Notification workflow** — the owner's concern is really about *awareness*,
  not booking. Worth confirming he gets Square's booking notifications on his
  phone in a form he'll actually notice, and that someone is designated to check
  them. This is likely the single highest-value thing for his comfort, and it's
  configuration, not code.
- **Kill switch** — if adoption fails, `booking_link` degrades cleanly:
  unset the Square credentials and every CTA falls back to `BOOKING_URL`, then
  to `tel:`. No code changes needed to retreat.

## Related

- `docs/service-menu-reconciliation.md` — which services are bookable and why
- `CLAUDE.md` → "Booking (Square — Phase D2)" — the technical implementation
