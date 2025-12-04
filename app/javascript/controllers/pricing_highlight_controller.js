import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"

// Connects to data-controller="pricing-highlight"
export default class extends Controller {
  static values = {
    category: String
  }

  // Public method that can be called by other controllers
  highlight() {
    // Flash glow animation
    gsap.fromTo(this.element,
      {
        boxShadow: '0 4px 6px -1px rgba(212, 154, 138, 0.15), 0 2px 4px -2px rgba(212, 154, 138, 0.1)',
        scale: 1
      },
      {
        boxShadow: '0 0 40px 8px rgba(212, 154, 138, 0.5), 0 0 20px 4px rgba(212, 154, 138, 0.3)',
        scale: 1.03,
        duration: 1.0,
        ease: "power2.out",
        yoyo: true,
        repeat: 1,
        onComplete: () => {
          // Reset to hover state shadow
          gsap.to(this.element, {
            boxShadow: '0 10px 15px -3px rgba(212, 154, 138, 0.15), 0 4px 6px -4px rgba(212, 154, 138, 0.1)',
            scale: 1,
            duration: 0.6,
            ease: "power2.inOut"
          })
        }
      }
    )
  }
}
