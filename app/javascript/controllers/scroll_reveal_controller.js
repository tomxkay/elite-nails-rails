import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"

// Connects to data-controller="scroll-reveal"
export default class extends Controller {
  static values = {
    animation: { type: String, default: "fadeInUp" },
    delay: { type: Number, default: 0 },
    duration: { type: Number, default: 0.8 },
    start: { type: String, default: "top 80%" },
    once: { type: Boolean, default: true }
  }

  connect() {
    // Set initial state based on animation type
    this.setInitialState()

    // Create the animation
    this.createAnimation()
  }

  disconnect() {
    // Clean up ScrollTrigger instance
    if (this.scrollTrigger) {
      this.scrollTrigger.kill()
    }
  }

  setInitialState() {
    const animations = {
      fadeIn: { opacity: 0 },
      fadeInUp: { opacity: 0, y: 30 },
      fadeInDown: { opacity: 0, y: -30 },
      fadeInLeft: { opacity: 0, x: -30 },
      fadeInRight: { opacity: 0, x: 30 },
      scaleUp: { opacity: 0, scale: 0.8 },
      slideUp: { y: 50, opacity: 0 },
      slideDown: { y: -50, opacity: 0 }
    }

    const initialState = animations[this.animationValue] || animations.fadeInUp
    gsap.set(this.element, initialState)
  }

  createAnimation() {
    const animations = {
      fadeIn: { opacity: 1 },
      fadeInUp: { opacity: 1, y: 0 },
      fadeInDown: { opacity: 1, y: 0 },
      fadeInLeft: { opacity: 1, x: 0 },
      fadeInRight: { opacity: 1, x: 0 },
      scaleUp: { opacity: 1, scale: 1 },
      slideUp: { y: 0, opacity: 1 },
      slideDown: { y: 0, opacity: 1 }
    }

    const toState = animations[this.animationValue] || animations.fadeInUp

    this.scrollTrigger = ScrollTrigger.create({
      trigger: this.element,
      start: this.startValue,
      once: this.onceValue,
      onEnter: () => {
        gsap.to(this.element, {
          ...toState,
          duration: this.durationValue,
          delay: this.delayValue,
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
