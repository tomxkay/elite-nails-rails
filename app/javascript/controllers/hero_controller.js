import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

// Connects to data-controller="hero"
export default class extends Controller {
  static targets = ["branch", "image", "hand", "heading", "subtitle", "cta", "scroll"]

  connect() {
    // Create entrance timeline
    this.createEntranceTimeline()

    // Create scroll-based parallax effects
    this.createParallaxEffects()
  }

  disconnect() {
    if (this.timeline) {
      this.timeline.kill()
    }
    if (this.parallaxTrigger) {
      this.parallaxTrigger.kill()
    }
  }

  createEntranceTimeline() {
    this.timeline = gsap.timeline({
      defaults: {
        ease: "power2.out"
      }
    })

    // Decorative branches (if present)
    if (this.hasBranchTarget) {
      this.branchTargets.forEach(branch => {
        this.timeline.from(branch, {
          opacity: 0,
          scale: 0.8,
          rotation: -10,
          duration: 1
        }, 0)
      })
    }

    // Hero image container (if present)
    if (this.hasImageTarget) {
      this.timeline.from(this.imageTarget, {
        opacity: 0,
        scale: 0.9,
        duration: 1.2
      }, 0.3)
    }

    // Floating hand accent
    if (this.hasHandTarget) {
      this.timeline.from(this.handTarget, {
        opacity: 0,
        y: 120,
        duration: 1.1
      }, ">")
    }

    // Main headline
    if (this.hasHeadingTarget) {
      this.timeline.from(this.headingTarget, {
        opacity: 0,
        y: -20,
        duration: 1
      }, 0.6)
    }

    // Subtitle
    if (this.hasSubtitleTarget) {
      this.timeline.from(this.subtitleTarget, {
        opacity: 0,
        y: 20,
        duration: 0.8
      }, 0.9)
    }

    // CTA buttons
    if (this.hasCtaTarget) {
      this.ctaTargets.forEach((cta, index) => {
        this.timeline.from(cta, {
          opacity: 0,
          y: 20,
          scale: 0.95,
          duration: 0.6
        }, 1.2 + (index * 0.1))
      })
    }

    // Scroll indicator
    if (this.hasScrollTarget) {
      this.timeline.from(this.scrollTarget, {
        opacity: 0,
        y: -10,
        duration: 0.8
      }, 1.5)

      // Add continuous pulse animation
      gsap.to(this.scrollTarget, {
        y: 5,
        duration: 1.5,
        repeat: -1,
        yoyo: true,
        ease: "sine.inOut"
      })
    }
  }

  createParallaxEffects() {
    // Only create parallax on desktop (not performance-intensive on mobile)
    if (window.innerWidth < 1024) return

    // Parallax for decorative branches
    if (this.hasBranchTarget) {
      this.branchTargets.forEach((branch, index) => {
        const direction = index % 2 === 0 ? -1 : 1
        ScrollTrigger.create({
          trigger: this.element,
          start: "top top",
          end: "bottom top",
          scrub: 1,
          onUpdate: (self) => {
            gsap.to(branch, {
              y: self.progress * 50 * direction,
              duration: 0.3
            })
          }
        })
      })
    }
  }
}
