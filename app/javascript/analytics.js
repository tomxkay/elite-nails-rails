// First-party client-side analytics (see docs/analytics-plan.md).
//
// Sends allow-listed KPI events to POST /events, which records them via Ahoy.
// - Honors Do Not Track / Global Privacy Control (sends nothing).
// - Uses fetch({ keepalive: true }) so events survive the page navigating away
//   (e.g. tapping a tel: or external booking link) while still sending CSRF.
// - A single delegated click listener auto-tracks link clicks by inspecting
//   href, so CTAs don't each need instrumenting.

export function trackEvent(name, properties = {}) {
  if (doNotTrack()) return

  const token = document.querySelector('meta[name="csrf-token"]')?.content
  try {
    fetch("/events", {
      method: "POST",
      keepalive: true,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": token || ""
      },
      body: JSON.stringify({ name, properties })
    }).catch(() => {}) // analytics is best-effort; never surface failures
  } catch (_) {
    // ignore — tracking must never throw into the caller
  }
}

function doNotTrack() {
  return (
    navigator.doNotTrack === "1" ||
    window.doNotTrack === "1" ||
    navigator.globalPrivacyControl === true
  )
}

function bookingUrl() {
  return document.querySelector('meta[name="booking-url"]')?.content || ""
}

// Classify a clicked link into a funnel event.
function trackLinkClick(event) {
  const link = event.target.closest("a[href]")
  if (!link) return

  const href = link.getAttribute("href")
  if (!href) return

  if (href.startsWith("tel:")) {
    trackEvent("phone_click", { href })
    return
  }

  const booking = bookingUrl()
  if (booking && href === booking && /^https?:/i.test(href)) {
    // Booking is routed to the hosted Square page (native /book unavailable).
    trackEvent("square_fallback_clicked", { href })
    return
  }

  if (href === "/book" || href.startsWith("/book?") || href.startsWith("/book#")) {
    trackEvent("book_cta_clicked", {})
  }
}

// Attach once on the document — survives Turbo navigations (document persists).
document.addEventListener("click", trackLinkClick)
