import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"
import { ScrollToPlugin } from "gsap/ScrollToPlugin"

// Connects to data-controller="smooth-scroll"
export default class extends Controller {
  static values = {
    target: String,
    offset: { type: Number, default: 80 }, // Offset for fixed header
    duration: { type: Number, default: 1 }
  }

  scroll(event) {
    event.preventDefault()

    // Get target from data attribute or href
    const target = this.targetValue || this.element.getAttribute("href")

    if (!target) {
      console.warn("No scroll target specified")
      return
    }

    // Find the target element
    const targetElement = document.querySelector(target)

    if (!targetElement) {
      console.warn(`Target element not found: ${target}`)
      return
    }

    // Close mobile menu if open (emit custom event for mobile menu controller)
    this.dispatch("scrolling", { detail: { target } })

    // Calculate scroll position with offset
    const targetPosition = targetElement.offsetTop - this.offsetValue

    // Smooth scroll with GSAP
    gsap.to(window, {
      scrollTo: {
        y: targetPosition,
        autoKill: true
      },
      duration: this.durationValue,
      ease: "power2.inOut",
      onComplete: () => {
        // Update URL hash without jumping
        if (target.startsWith("#")) {
          history.pushState(null, null, target)
        }
      }
    })
  }
}
