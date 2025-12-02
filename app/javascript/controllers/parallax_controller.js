import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

// Connects to data-controller="parallax"
export default class extends Controller {
  static values = {
    speed: { type: Number, default: 0.5 }, // 0 = no movement, 1 = normal scroll speed
    direction: { type: String, default: "down" }, // "up" or "down"
    start: { type: String, default: "top bottom" },
    end: { type: String, default: "bottom top" }
  }

  connect() {
    // Only enable parallax on desktop (performance consideration)
    if (window.innerWidth < 768) {
      return
    }

    this.createParallax()
  }

  disconnect() {
    if (this.scrollTrigger) {
      this.scrollTrigger.kill()
    }
  }

  createParallax() {
    const movement = this.directionValue === "up" ? -100 : 100
    const speed = this.speedValue

    this.scrollTrigger = ScrollTrigger.create({
      trigger: this.element,
      start: this.startValue,
      end: this.endValue,
      scrub: 1,
      onUpdate: (self) => {
        const progress = self.progress
        const yValue = movement * progress * speed

        gsap.to(this.element, {
          y: yValue,
          force3D: true,
          duration: 0.1,
          ease: "none"
        })
      }
    })
  }
}
