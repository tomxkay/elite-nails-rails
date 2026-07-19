# Quick Availability Feature Plan

Status: Implemented; automated browser coverage remains

## Goal

Replace the hero's filler "Next availability" card with an actionable way to
check upcoming Square appointment openings by nail technician.

The experience should help a visitor find a realistic next appointment without
slowing down the initial page load or exposing Square credentials.

## Product Decision

Use an accessible modal on desktop and a bottom-sheet-style dialog on mobile.
A tooltip is not appropriate because the interaction needs service selection,
network loading, multiple results, and booking actions.

Square availability depends on the selected service and date range. The UI must
ask for both rather than presenting a misleading generic availability claim.

## User Flow

1. Visitor clicks the hero card labeled "Check availability".
2. The dialog loads available Square services and bookable technicians.
3. Visitor chooses a service and a date range, defaulting to the next 14 days.
4. The site requests open slots and groups the earliest result for each tech.
5. Each technician row shows the next opening and a "Book this time" action.
6. The visitor can view more times, choose anyone available, or close the dialog.
7. A selected result opens `/book` with the service, technician, and date
   preselected. The booking flow still rechecks the slot before submitting.

## Progress

- [x] Decide on modal/bottom-sheet interaction instead of a tooltip.
- [x] Confirm service and date are required for accurate Square availability.
- [x] Add a lazy endpoint for Square services and bookable technicians.
- [x] Add a next-availability endpoint that groups slots by technician.
- [x] Replace the hero filler card with the dialog trigger.
- [x] Build dialog loading, results, empty, error, and fallback states.
- [x] Pass selected service, technician, and date into `/book`.
- [x] Add caching, validation, and rate-limit handling.
- [x] Add controller and Square availability tests.
- [x] Verify desktop, iPhone, and Square failure behavior manually.
- [ ] Add automated browser/system coverage for the dialog interaction.

## Backend Design

Reuse the existing Square proxy in `app/services/square_api.rb` and keep all
Square requests server-side.

Proposed endpoints:

- `GET /book/availability/options` returns the available services and
  bookable technicians needed by the dialog.
- `GET /book/availability/next` accepts a service variation, version, start
  date, and bounded day range, then returns the earliest slot grouped by tech.

The next-availability request should use Square's existing availability search
without a technician filter, then group returned segments by
`team_member_id`. This avoids making one Square request per technician.

Validate service identifiers and dates server-side. Clamp the requested window
to a safe maximum, such as 14 days. Use the salon's configured timezone when
forming dates and displaying times.

## Dialog States

- Initial: service selector and date range controls.
- Loading: visible progress state while Square responds.
- Results: one row per technician with earliest opening and booking action.
- Partial results: technicians with no openings are labeled clearly.
- Empty: no openings in the selected window, with "View more" and phone paths.
- Error: Square unavailable or request failed, with retry and booking fallback.
- Unconfigured: use the existing `/book`, external Square, or phone fallback.

The dialog must support a close button, Escape, backdrop click, focus return,
`role="dialog"`, `aria-modal="true"`, and body scroll locking. On mobile it
should behave like a bottom sheet without creating a nested scrolling problem.

## Booking Integration

Extend the existing booking flow in `app/controllers/bookings_controller.rb`
and `app/javascript/controllers/booking_controller.js` to accept preselection
parameters. Preselect the service, technician, and date, then load fresh slots.

Do not trust the previously displayed slot. Square remains the source of truth,
and an unavailable slot must return the existing clear retry/call message.

## Performance and Reliability

- Do not call Square during the homepage render.
- Fetch options only when the dialog opens.
- Cache identical availability searches for approximately 30-60 seconds.
- Retain the existing per-IP availability throttling.
- Never expose access tokens or raw Square credentials to the browser.
- Distinguish no availability from an API failure.
- Preserve a usable booking and phone fallback when Square is unavailable.

## Test Plan

Add coverage for:

- Square slot grouping by technician.
- Invalid service, version, date, and day-range parameters.
- Empty availability and technicians without openings.
- Square errors and unavailable credentials.
- Cache behavior and rate limiting.
- Dialog loading, result, empty, error, and fallback states.
- Booking preselection followed by a fresh availability request.
- Responsive behavior at desktop and iPhone widths.

## Acceptance Criteria

- The hero card is an obvious button and does not trigger an API request on page
  load.
- A visitor can select a service and see the next opening for each bookable
  technician.
- Selecting a result opens the existing booking flow with useful preselection.
- Stale or unavailable times are handled without false booking confirmation.
- The interaction is keyboard accessible and usable on iPhone.
- Square failures leave the visitor with a clear booking or phone fallback.
