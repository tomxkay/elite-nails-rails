import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"
import { ScrollToPlugin } from "gsap/ScrollToPlugin"

gsap.registerPlugin(ScrollToPlugin)

// Connects to data-controller="smooth-scroll"
export default class extends Controller {
  static values = {
    target: String,
    offset: Number,
    duration: { type: Number, default: 1 }
  }

  scroll(event) {
    // Get target from data attribute or href
    const target = this.targetValue || this.element.getAttribute("href")
    const linkUrl = this.linkUrl

    if (!target) {
      console.warn("No scroll target specified")
      return
    }

    if (!this.canScrollOnCurrentPage(linkUrl)) return

    const targetSelector = this.targetSelector(target, linkUrl)

    // Find the target element
    const targetElement = document.querySelector(targetSelector)

    if (!targetElement) return

    event.preventDefault()

    // Get pricing category if specified
    const pricingCategory = this.element.getAttribute("data-pricing-category")

    // Close mobile menu if open (emit custom event for mobile menu controller)
    this.dispatch("scrolling", { detail: { target: targetSelector } })

    // Calculate scroll position with offset - use getBoundingClientRect for accurate positioning
    const rect = targetElement.getBoundingClientRect()
    const targetPosition = rect.top + window.pageYOffset - this.scrollOffset

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
        if (targetSelector.startsWith("#")) {
          history.pushState(null, null, targetSelector)
        }

        // Trigger highlight on matching pricing card
        if (pricingCategory && targetSelector === "#pricing") {
          // Small delay to ensure scroll is fully settled
          setTimeout(() => {
            const pricingCard = document.querySelector(
              `[data-pricing-highlight-category-value="${pricingCategory}"]`
            )

            if (pricingCard) {
              // Get the Stimulus controller instance and call highlight method
              const controller = this.application.getControllerForElementAndIdentifier(
                pricingCard,
                "pricing-highlight"
              )

              if (controller && typeof controller.highlight === 'function') {
                controller.highlight()
              }
            }
          }, 100)
        }
      }
    })
  }

  get scrollOffset() {
    if (this.hasOffsetValue) return this.offsetValue

    const header = document.getElementById("navbar")
    if (!header) return 0

    return Math.ceil(header.getBoundingClientRect().height) + 24
  }

  get linkUrl() {
    const href = this.element.getAttribute("href")
    if (!href) return null

    try {
      return new URL(href, window.location.href)
    } catch {
      return null
    }
  }

  canScrollOnCurrentPage(linkUrl) {
    if (!linkUrl) return true
    if (linkUrl.origin !== window.location.origin) return false

    return linkUrl.pathname === window.location.pathname
  }

  targetSelector(target, linkUrl) {
    if (target.startsWith("#")) return target
    if (linkUrl?.hash) return linkUrl.hash

    return target
  }
}
