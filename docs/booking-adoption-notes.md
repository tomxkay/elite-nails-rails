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
   only **Michael** is bookable online, and only **9 of 25** menu items are
   `bookable: true` (see `docs/service-menu-reconciliation.md`). Two filters
   apply: short/add-on work is excluded so the calendar stays predictable, and
   the list is narrowed again to what Michael actually performs — **Manicures**
   and **Acrylic, Dip & Extensions**. Pedicures and polish-only services came
   off the bookable list on 2026-07-21 for exactly this reason.

   ⚠️ Remember that `bookable` only drives the site's links. **Square owns the
   /book service list**, so narrowing this flag without re-importing the catalog
   leaves the wizard selling services nobody can work.
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
  their `TeamMember` record — **and** the availability code change flagged below
  (see "Before a SECOND technician becomes bookable").
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

## Manual acceptance ("request to book") — option + required code change

**What it is.** Square Appointments can be set (Dashboard → Appointments →
Settings → Booking) to one of:

- **Automatically accept** — current setup. A customer's booking is instantly
  live; `CreateBooking` returns status `ACCEPTED`.
- **Request to book / manually accept** — the booking is created `PENDING` and a
  staff member must **Accept or Decline** it before it's real.

**Why it's worth considering.** It's a direct answer to the owner's core worry —
*"I can't watch an incoming schedule and work at the same time."* With manual
acceptance, **nothing hits the calendar without a human OK**: each online booking
becomes a request he approves when he has a moment. That's an easier sell than
auto-booking for someone nervous about losing control. Trade-off: more friction
(the guest isn't instantly confirmed), and **someone must actually act on pending
requests** or they go stale — which leans on the *Notification workflow* item
above.

**⚠️ Plan caveat.** Unconfirmed whether "request to book" is available on the
**free** Appointments plan or needs a paid tier. The salon is on free. Check the
dashboard toggle is actually selectable before planning around it.

**⚠️ Required code change before enabling.** The confirmation screen currently
**ignores the booking status** and hardcodes **"Appointment confirmed"**
(`app/views/bookings/show.html.erb`, `confirmationHeading`;
`app/javascript/controllers/booking_controller.js` never reads
`data.booking.status`). If Square is switched to request-to-book *without* a code
change, a guest submits a request and the site still tells them **"Appointment
confirmed"** — a real misrepresentation, since it's only `PENDING` and can be
declined.

The fix (~20 min): branch the confirmation on `booking.status` (already returned
by `BookingsController#create`):
- `PENDING`  → "Appointment requested — we'll confirm shortly" + a line that
  they'll hear back, and don't imply it's locked in.
- `ACCEPTED` → "Appointment confirmed" (current copy).

Reflecting the real status is arguably worth doing **even on auto-accept** —
hardcoding "confirmed" is only correct by accident of the current Square setting.

## ⚠️ Before a SECOND technician becomes bookable — required code change

The quick-availability dialog (`/book/availability/next`, `BookingsController#
next_availability`) reports **per-technician** "next opening" correctly **only
while exactly one technician is bookable**. Adding a second bookable tech
*without* the fix below will make the dialog misreport availability. `next_slot`
per tech will be wrong; only the "Anyone available" aggregate stays correct.

**Why it breaks.** Today the controller runs one broad Square availability query
per service, then splits the returned slots by their `team_member_id`. Square,
however, tags each open slot to **one** technician ("first available"), and the
query returns a row per bookable staff member regardless of the service. So with
two+ bookable techs:

- **Different services** (Thai does Gel, Michael doesn't): the tech who doesn't
  perform the selected service still gets a row reading *"No opening in the next
  14 days"* — implying they offer it but are booked out, when they don't offer
  it at all. (`quick_availability_controller.js#resultRow` renders every
  technician the endpoint returns.)
- **Shared service** (both do Gel Manicure): a noon slot both could work is
  tagged by Square to just one of them. The other's earliest *own-tagged* slot
  looks later (e.g. 1pm) than their true availability (noon). Pruning can't fix
  this — both techs legitimately belong. This is the same slot-tagging quirk
  that caused the 2026-07-21 "phantom 10am" bug, but between two real techs.

**The fix.** Query Square **once per bookable technician** with
`team_member_id_filter: { any: [tech_id] }` (SquareApi.availability already
accepts a single `team_member_id`; extend or loop it), instead of one broad
query split after the fact. Then:
- each tech's `next_slot` is their *true* earliest for that service;
- a tech not assigned to the service returns zero slots → **omit the row** rather
  than show a false "no opening";
- `anyone_next_slot` = the min across the per-tech results (one consistent
  source), so it stays correct too.

Cost is N Square calls per lookup (one per bookable tech), which is fine at this
volume and already cached (30s/5min in the controller). Estimated ~30 min + the
existing `bookings_controller_test.rb` availability tests extended for two techs.

**Until then:** with one bookable tech (Michael), the current logic is correct —
his tagged slots are the only ones, so there's nothing to mis-split. This note
exists so the change lands *with* the second tech, not after a user reports bad
times.

## Related

- `docs/service-menu-reconciliation.md` — which services are bookable and why
- `CLAUDE.md` → "Booking (Square — Phase D2)" — the technical implementation
