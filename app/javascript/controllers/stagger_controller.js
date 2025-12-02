import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

// Connects to data-controller="stagger"
export default class extends Controller {
  static values = {
    amount: { type: Number, default: 0.15 },
    from: { type: String, default: "bottom" },
    duration: { type: Number, default: 0.8 },
    start: { type: String, default: "top 80%" },
    once: { type: Boolean, default: true }
  }

  connect() {
    this.children = Array.from(this.element.children)

    if (this.children.length === 0) return

    // Set initial state
    this.setInitialState()

    // Create stagger animation
    this.createStaggerAnimation()
  }

  disconnect() {
    if (this.scrollTrigger) {
      this.scrollTrigger.kill()
    }
  }

  setInitialState() {
    const initialStates = {
      bottom: { y: 30, opacity: 0 },
      top: { y: -30, opacity: 0 },
      left: { x: -30, opacity: 0 },
      right: { x: 30, opacity: 0 },
      scale: { scale: 0.8, opacity: 0 }
    }

    const state = initialStates[this.fromValue] || initialStates.bottom

    this.children.forEach(child => {
      gsap.set(child, state)
    })
  }

  createStaggerAnimation() {
    const toStates = {
      bottom: { y: 0, opacity: 1 },
      top: { y: 0, opacity: 1 },
      left: { x: 0, opacity: 1 },
      right: { x: 0, opacity: 1 },
      scale: { scale: 1, opacity: 1 }
    }

    const toState = toStates[this.fromValue] || toStates.bottom

    this.scrollTrigger = ScrollTrigger.create({
      trigger: this.element,
      start: this.startValue,
      once: this.onceValue,
      onEnter: () => {
        gsap.to(this.children, {
          ...toState,
          duration: this.durationValue,
          stagger: this.amountValue,
          ease: "power2.out"
        })
      },
      onLeaveBack: () => {
        if (!this.onceValue) {
          this.setInitialState()
        }
      }
    })
  }
}
