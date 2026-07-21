import { Controller } from "@hotwired/stimulus"

// Reveals the persistent mobile action bar once the visitor is past the hero,
// and hides it wherever the page already offers the same two actions (the team
// section and the closing CTA banner) so it never doubles up.
//
// Reading layout (offsetTop/offsetHeight) inside a scroll handler forces a
// synchronous reflow on every event — most expensive on exactly the low-end
// phones this bar targets. So the geometry is measured once and cached, scroll
// work is coalesced into one frame via rAF, and re-measuring is driven by a
// ResizeObserver rather than by scrolling. The observer matters: lazy-loaded
// images below the fold shift these offsets after connect(), and without it the
// cached thresholds would be silently wrong for the rest of the visit.
export default class extends Controller {
  connect() {
    this.onScroll = this.onScroll.bind(this)
    this.remeasure = this.remeasure.bind(this)
    this.frame = null

    this.measure()
    window.addEventListener("scroll", this.onScroll, { passive: true })
    window.addEventListener("resize", this.remeasure)

    // Catches reflow from lazy images, font swaps, and the disclosure panels.
    if (window.ResizeObserver) {
      this.observer = new ResizeObserver(this.remeasure)
      this.observer.observe(document.body)
    }

    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.onScroll)
    window.removeEventListener("resize", this.remeasure)
    this.observer?.disconnect()
    if (this.frame) cancelAnimationFrame(this.frame)
  }

  // The only place that touches layout. Everything update() needs is cached here.
  measure() {
    const hero = document.getElementById("home")
    const team = document.getElementById("team")
    const finalCta = document.getElementById("final-cta")
    const viewport = window.innerHeight

    this.isMobile = window.matchMedia("(max-width: 1023px)").matches
    this.revealAt = hero ? hero.offsetTop + hero.offsetHeight - 80 : viewport
    this.teamEnter = team ? team.offsetTop - viewport + 160 : null
    this.teamExit = team ? team.offsetTop + team.offsetHeight - 80 : null
    this.finalCtaEnter = finalCta ? finalCta.offsetTop - viewport + 160 : null
  }

  onScroll() {
    if (this.frame) return
    this.frame = requestAnimationFrame(() => {
      this.frame = null
      this.update()
    })
  }

  remeasure() {
    this.measure()
    this.update()
  }

  update() {
    const y = window.scrollY
    const beforeFinalCta = this.finalCtaEnter === null || y < this.finalCtaEnter
    const awayFromTeam =
      this.teamEnter === null || y < this.teamEnter || y > this.teamExit
    const visible =
      this.isMobile && y >= this.revealAt && beforeFinalCta && awayFromTeam

    this.element.classList.toggle("opacity-0", !visible)
    this.element.classList.toggle("opacity-100", visible)
    this.element.classList.toggle("translate-y-4", !visible)
    this.element.classList.toggle("translate-y-0", visible)
    this.element.classList.toggle("pointer-events-none", !visible)
    this.element.classList.toggle("pointer-events-auto", visible)
  }
}
