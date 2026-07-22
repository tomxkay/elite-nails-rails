import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"

// Connects to data-controller="hero"
//
// Entrance philosophy: a gentle SETTLE, never a reveal-from-nothing. The text
// the visitor came to read — headline, subtitle, CTAs — is animated by position
// only (a few px rise), never faded from opacity 0, so it is fully legible on
// the very first painted frame. Only decorative/visual elements (the photo,
// accents) get an opacity fade, since those aren't content to read. The whole
// sequence lands in ~0.7s instead of the old ~2s, and reduced-motion skips it
// entirely (elements are already in their final, visible state in the DOM).
export default class extends Controller {
  static targets = ["branch", "image", "hand", "heading", "subtitle", "cta", "availability", "scroll"]

  connect() {
    this.prefersReducedMotion = window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches ?? false
    // Nothing in the DOM starts hidden, so honoring reduced motion is just:
    // do nothing. The content is already where it should be.
    if (this.prefersReducedMotion) return

    this.createEntranceTimeline()
  }

  disconnect() {
    this.timeline?.kill()
  }

  createEntranceTimeline() {
    this.timeline = gsap.timeline({ defaults: { ease: "power3.out" } })

    // Decorative accents may fade — they're background flourish, not content.
    if (this.hasBranchTarget) {
      this.timeline.from(this.branchTargets, {
        autoAlpha: 0, scale: 0.9, duration: 0.7, stagger: 0.05
      }, 0)
    }

    // Photo: a soft zoom-fade reads well and isn't text the visitor is parsing.
    if (this.hasImageTarget) {
      this.timeline.from(this.imageTarget, {
        autoAlpha: 0, scale: 1.04, duration: 0.6
      }, 0)
    }

    if (this.hasHandTarget) {
      this.timeline.from(this.handTarget, {
        autoAlpha: 0, y: 40, duration: 0.7
      }, 0.1)
    }

    // Text + CTAs: POSITION ONLY, no opacity — legible at the first frame. A
    // small rise with a light stagger gives it life without hiding anything.
    const rising = []
    if (this.hasHeadingTarget) rising.push(this.headingTarget)
    if (this.hasSubtitleTarget) rising.push(this.subtitleTarget)
    if (this.hasCtaTarget) rising.push(...this.ctaTargets)
    if (this.hasScrollTarget) rising.push(this.scrollTarget)

    if (rising.length) {
      this.timeline.from(rising, {
        y: 14, duration: 0.5, stagger: 0.06
      }, 0.05)
    }
  }
}
