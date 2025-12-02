import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"

// Connects to data-controller="card-hover"
export default class extends Controller {
  static targets = ["icon", "content"]
  static values = {
    scale: { type: Number, default: 1.02 },
    duration: { type: Number, default: 0.3 },
    lift: { type: Boolean, default: true }
  }

  connect() {
    // Set initial state
    this.isHovering = false
  }

  mouseEnter(event) {
    if (this.isHovering) return
    this.isHovering = true

    const animations = {}

    // Card scale and lift
    if (this.liftValue) {
      animations.scale = this.scaleValue
      animations.y = -4
    }

    // Animate the card
    gsap.to(this.element, {
      ...animations,
      duration: this.durationValue,
      ease: "power2.out"
    })

    // Animate icon if present
    if (this.hasIconTarget) {
      this.iconTargets.forEach(icon => {
        gsap.to(icon, {
          scale: 1.1,
          rotation: 5,
          duration: this.durationValue,
          ease: "back.out(1.7)"
        })
      })
    }

    // Animate content if present
    if (this.hasContentTarget) {
      this.contentTargets.forEach(content => {
        gsap.to(content, {
          y: -2,
          duration: this.durationValue,
          ease: "power2.out"
        })
      })
    }
  }

  mouseLeave(event) {
    this.isHovering = false

    // Reset card
    gsap.to(this.element, {
      scale: 1,
      y: 0,
      duration: this.durationValue,
      ease: "power2.out"
    })

    // Reset icon
    if (this.hasIconTarget) {
      this.iconTargets.forEach(icon => {
        gsap.to(icon, {
          scale: 1,
          rotation: 0,
          duration: this.durationValue,
          ease: "power2.out"
        })
      })
    }

    // Reset content
    if (this.hasContentTarget) {
      this.contentTargets.forEach(content => {
        gsap.to(content, {
          y: 0,
          duration: this.durationValue,
          ease: "power2.out"
        })
      })
    }
  }
}
