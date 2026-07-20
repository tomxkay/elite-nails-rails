# Deal Alerts Subscription Plan

Status: Exploration documented

_Created: 2026-07-20._

## Goal

Explore what it would take to let visitors subscribe for alerts about deals,
seasonal offers, and salon specials.

The feature should support the site's marketing goal without turning the Rails
app into a full marketing platform too early. Because these alerts are
commercial messages, the design must treat consent, unsubscribe, and sender
responsibility as product requirements rather than afterthoughts.

## Recommended Product Shape

Add a small inline signup module instead of a pop-up. Good placements:

- Promotions section (`#specials`)
- Footer
- Booking confirmation state, if the native `/book` flow remains enabled

Suggested UI:

- Email field, required for email alerts.
- Phone field, optional and only shown or used for SMS alerts.
- Separate unchecked opt-in controls:
  - "Email me deals and seasonal offers."
  - "Text me deals and seasonal offers."
- Short consent copy naming Elite Nails, the message type, unsubscribe method,
  and the salon's physical address.
- Confirmation state after submit.
- Clear failure state with phone/booking fallback.

Do not pre-check consent boxes. Do not combine email and SMS consent into one
ambiguous checkbox.

## Best Implementation Options

### Option 1: Square Marketing Managed

Use Square Marketing / Square Customer Directory as the campaign system and keep
the website's role limited to routing visitors into that managed flow.

Why this fits:

- Elite Nails already uses Square for bookings.
- Square Marketing supports email and text campaigns, customer groups,
  scheduling, seasonal offers, coupons, and reporting.
- The owner can manage campaigns in Square Dashboard instead of needing a custom
  Rails admin UI.

Tradeoffs:

- Square Marketing is tied to Square Plus or Premium.
- Website customization depends on what Square exposes for signup, import, or
  customer collection.
- The app may only be able to link out or collect then export/import, depending
  on Square's available workflow.

Estimated development:

- 0.5-1.5 days for a link/handoff/signup CTA integration.
- 1-3 days if the site collects consent and exports/imports subscribers into
  Square-managed marketing.

This is the recommended first path if the owner wants a low-maintenance system.

### Option 2: Custom Email-Only Signup

Build a small Rails subscription feature and send campaigns through an email
provider.

Likely scope:

- `MarketingSubscriber` model.
- Consent/audit fields: email, status, source, IP/user agent, consent text,
  timestamps.
- `SubscriptionsController#create`.
- Unsubscribe endpoint.
- Inline form partial and Stimulus submit states.
- Provider integration, such as Mailchimp, ConvertKit, SendGrid marketing
  contacts, or a simple CSV export workflow.
- Tests for validation, consent capture, unsubscribe, and spam/rate limiting.

Estimated development:

- 2-4 days for email-only, depending on provider choice and polish.

This is a reasonable first custom build if Square Marketing is not desired.

### Option 3: Custom Email + SMS

Build the email feature and add SMS marketing through a messaging provider.

Additional scope:

- Phone normalization and validation.
- Separate SMS consent records.
- SMS provider account setup.
- US messaging registration / campaign setup if required by the provider.
- STOP/QUIT/END/CANCEL/UNSUBSCRIBE handling.
- One-time opt-out confirmation behavior.
- Stronger operational process around send frequency and message wording.

Estimated development:

- 5-10 days for a compliant, production-ready email + SMS implementation.

This should be deferred unless the salon expects to send timely offers often
enough to justify the additional compliance and provider setup.

### Option 4: Full Custom Marketing Module

Build subscriber management, campaign authoring, scheduling, templates,
analytics, and MCP/admin tooling inside the Rails app.

Estimated development:

- 1-3 weeks depending on campaign editing, previewing, scheduling, reporting,
  and owner workflow expectations.

This is not recommended as a first slice. It duplicates software that Square and
email/SMS providers already provide.

## Compliance Requirements

This is not legal advice; confirm final copy and process with counsel if SMS is
used.

### Email

Commercial email must comply with CAN-SPAM. Practical requirements:

- Accurate sender and routing information.
- Non-deceptive subject lines.
- Clear identification that the message is promotional when applicable.
- Valid physical postal address.
- Clear unsubscribe path.
- Opt-outs honored within 10 business days.
- Ability to process opt-outs for at least 30 days after a campaign is sent.

### SMS

SMS marketing has stricter expectations than email.

Practical requirements:

- Prior express written consent before marketing texts.
- Consent language that clearly says the visitor is agreeing to receive texts
  from Elite Nails about deals and seasonal offers.
- Consent cannot be required to book or buy services.
- Store the exact consent language shown at opt-in time.
- Support reasonable revocation methods, including standard reply keywords such
  as STOP, QUIT, END, CANCEL, UNSUBSCRIBE, and OPT OUT.
- Stop future marketing texts after opt-out, with at most a confirmation text.

## Data Model For A Custom Build

Minimum email-only table:

```ruby
create_table :marketing_subscribers do |t|
  t.string :email, null: false
  t.string :phone
  t.string :status, null: false, default: "subscribed"
  t.boolean :email_opt_in, null: false, default: false
  t.boolean :sms_opt_in, null: false, default: false
  t.datetime :email_opted_in_at
  t.datetime :sms_opted_in_at
  t.datetime :unsubscribed_at
  t.string :source
  t.string :ip_address
  t.string :user_agent
  t.text :consent_text
  t.timestamps
end
```

For SMS or stricter auditability, use a separate `marketing_consents` table so
each opt-in, opt-out, and source copy version is preserved historically.

## Rails Integration Points

Current app facts that shape the implementation:

- The public site is one Rails-rendered page composed from partials.
- Promotions are already DB-backed through `Promotion`.
- Booking CTAs route through `booking_link`, and native booking lives at
  `/book`.
- First-party analytics already exists via Ahoy and `/events`.
- There is no general admin UI; MCP tools are the current content control
  surface.

Implementation touchpoints for a custom first slice:

- Add a signup partial under `app/views/shared/` or `app/views/pages/home/`.
- Render it in `_promotions.html.erb` and `_footer.html.erb`.
- Add `SubscriptionsController`.
- Add routes for subscribe and unsubscribe.
- Add a Stimulus controller only if progressive submit states are needed.
- Track signup attempts and successes through the existing analytics event
  path.
- Add MCP tools later only if the owner needs Claude to list/export subscribers
  or trigger campaign prep.

## Suggested First Slice

Start with one of these:

1. Square-managed deal alerts if the owner is willing to use Square Plus/Premium.
2. Custom email-only signup if Square Marketing is not desired.

Acceptance criteria for the first slice:

- Visitor can subscribe from the promotions section.
- Consent is explicit and stored.
- Duplicate signups are handled gracefully.
- Subscriber can unsubscribe from a single-click link.
- Owner has a defined way to use the list: Square, provider dashboard, or CSV.
- No SMS is sent unless SMS-specific consent and opt-out handling exist.

## Open Questions

- Does the owner already have Square Plus or Premium?
- Should the first version be email-only?
- Which system should own campaigns: Square, a newsletter provider, or Rails?
- How often will offers be sent?
- Is the goal seasonal campaigns only, or also birthday/reactivation offers?
- Should signup be offered after a completed booking?

## Sources

- [Square Marketing](https://squareup.com/us/en/marketing)
- [Square Email Marketing](https://squareup.com/us/en/software/marketing/email)
- [FTC CAN-SPAM compliance guide](https://www.ftc.gov/business-guidance/resources/can-spam-act-compliance-guide-business)
- [FCC consent revocation rule summary in the Federal Register](https://www.federalregister.gov/documents/2024/03/05/2024-04587/strengthening-the-ability-of-consumers-to-stop-robocalls)
