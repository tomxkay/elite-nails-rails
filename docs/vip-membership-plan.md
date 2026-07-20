# VIP Membership Signup Plan

Status: Exploration documented

_Created: 2026-07-20._

## Goal

Explore a lightweight VIP signup feature that gives visitors a clear reason to
share contact information while supporting Elite Nails' main business goal:
more repeat appointments.

The feature should feel like a salon loyalty perk, not a heavy account system.
It should avoid operational complexity, protect service margins, and keep the
owner's workflow manageable.

## Recommended Product Shape

Create an **Elite VIP Club** signup that works as a marketing list, not as
user authentication.

Recommended offer:

> Join Elite VIP and get $10 toward your first appointment, plus birthday
> treats and first access to specials.

Core benefits:

- $10 welcome credit toward a first booked service of $45 or more.
- Birthday-month treat, such as $10 off or a free accent nail/nail art add-on.
- Early access to seasonal specials.
- Last-minute opening alerts for cancellations or popular weekend slots.

The best first implementation is a simple email signup. SMS can be added later
only if the salon is ready for the consent, opt-out, and provider setup that
text marketing requires.

## Why This Benefit Mix

The signup incentive needs to be attractive without training customers to wait
for steep discounts.

A fixed $10 credit is easier to control than percentage-based discounts because
nail services are labor-heavy. A minimum service amount protects margin and
keeps the offer tied to real appointment revenue.

Birthday perks and early-special access add ongoing value without needing a
complex points ledger. Last-minute opening alerts are especially useful because
they can fill otherwise-lost appointment slots without reducing prices.

## Benefits To Avoid Initially

Avoid these for the first version:

- Large blanket discounts, such as 20-30% off.
- Points or cashback balances.
- Tiered memberships.
- Paid memberships.
- Guaranteed priority booking.
- Benefits that require staff to manually track complicated rules.

These could work later, but they add more operational burden than the current
site needs.

## Suggested Site Placement

Good placements:

- Promotions section, near seasonal offers.
- Footer signup area.
- Booking confirmation state, if native booking remains enabled.
- Optional small CTA in the mobile sticky booking area only after the primary
  booking CTA is preserved.

Avoid a pop-up as the first version. The site should keep appointment booking
as the primary action.

## Implementation Options

### Option 1: Square-Managed VIP List

Use Square Customer Directory or Square Marketing as the owner-facing system
and keep the website's role limited to signup capture or a handoff link.

Why this fits:

- Elite Nails already uses Square for appointments.
- The owner can manage customer lists and campaigns in Square.
- The Rails app avoids becoming a custom marketing platform.

Tradeoffs:

- Square Marketing plan requirements and API/import support need confirmation.
- Site customization may be limited by Square's available signup flows.

This is the recommended first path if Square can support the desired workflow.

### Option 2: Custom Email-Only Signup

Build a small Rails feature for collecting VIP email subscribers and exporting
or syncing them to an email provider.

Likely scope:

- `VipSubscriber` or `MarketingSubscriber` model.
- Email, status, source, consent copy, and timestamps.
- Signup endpoint and unsubscribe endpoint.
- Inline form partial.
- Basic duplicate handling.
- Ahoy event tracking for signup attempts and completions.
- Provider integration or CSV export.

This is a reasonable fallback if Square is not suitable.

### Option 3: Custom Email + SMS Signup

Add SMS marketing after email is proven useful.

Additional scope:

- Phone normalization.
- Separate SMS consent from email consent.
- Stored consent language.
- STOP/QUIT/END/CANCEL/UNSUBSCRIBE handling.
- SMS provider setup and compliance review.

This should be deferred unless the salon expects to send timely alerts often
enough to justify the extra work.

## First Slice

Recommended MVP:

1. Add an inline VIP signup module to the promotions section.
2. Offer a $10 welcome credit on first booked service of $45 or more.
3. Capture explicit email consent.
4. Send or show a clear confirmation.
5. Track signup conversion with the existing analytics path.
6. Keep booking CTAs routed through `booking_link`.

Acceptance criteria:

- Visitor understands the VIP benefit in one sentence.
- Visitor can sign up without creating an account.
- Duplicate signups are handled gracefully.
- Consent language is stored or handled by the chosen provider.
- The feature does not block booking if signup fails.

## Open Questions

- Should the welcome credit be fulfilled through Square coupons, manual staff
  awareness, or an email code?
- Should VIP signup collect email only at launch?
- Does Square Marketing support the owner's desired workflow without a custom
  subscriber database?
- What minimum service amount best protects margin: $45, $50, or another value?
- Should birthday perks require date of birth at signup, or should that wait
  until a later version?
