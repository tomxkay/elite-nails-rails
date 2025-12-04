import { Controller } from "@hotwired/stimulus"
import { gsap } from "gsap"

// Connects to data-controller="service-image-hover"
export default class extends Controller {
  static targets = ["imageContainer", "image", "imageGlow", "overlay", "content"]

  static values = {
    imageUrl: String,
    duration: { type: Number, default: 0.35 },
    enableMobile: { type: Boolean, default: false }
  }

  connect() {
    this.isHovering = false
    this.imageLoaded = false
    this.isMobile = window.innerWidth < 768

    if (this.isMobile && !this.enableMobileValue) {
      return
    }

    this.loadImage()
    this.createTimeline()
    this.setPerformanceHints()
  }

  disconnect() {
    if (this.timeline) {
      this.timeline.kill()
    }
  }

  loadImage() {
    if (!this.hasImageTarget || !this.imageUrlValue) return

    const img = this.imageTarget
    const src = img.dataset.src

    const loader = new Image()
    loader.onload = () => {
      img.src = src
      gsap.to(img, {
        opacity: 1,
        duration: 0.4,
        ease: "power2.out"
      })
      this.imageLoaded = true
    }
    loader.src = src
  }

  setPerformanceHints() {
    gsap.set([this.imageContainerTarget, this.element], {
      force3D: true
    })
  }

  createTimeline() {
    this.timeline = gsap.timeline({ paused: true })

    // Image emergence
    this.timeline.to(this.imageContainerTarget, {
      opacity: 1,
      scale: 1.08,
      y: 0,
      duration: this.durationValue,
      ease: "power2.out"
    }, 0)

    // Card elevation
    this.timeline.to(this.element, {
      scale: 1.03,
      y: -8,
      duration: this.durationValue,
      ease: "power2.out"
    }, 0.05)

    // Glow effect
    if (this.hasImageGlowTarget) {
      this.timeline.to(this.imageGlowTarget, {
        opacity: 0.6,
        scale: 1.15,
        duration: 0.45,
        ease: "power1.out"
      }, 0.15)
    }

    // Content shift
    if (this.hasContentTarget) {
      this.timeline.to(this.contentTarget, {
        y: -4,
        duration: this.durationValue,
        ease: "power2.out"
      }, 0.1)
    }

    // Overlay fade
    if (this.hasOverlayTarget) {
      this.timeline.to(this.overlayTarget, {
        opacity: 0.15,
        duration: 0.4,
        ease: "power2.out"
      }, 0.1)
    }
  }

  mouseEnter() {
    if (this.isHovering || (this.isMobile && !this.enableMobileValue)) return
    this.isHovering = true
    this.timeline.play()
  }

  mouseLeave() {
    if (!this.isHovering) return
    this.isHovering = false
    this.timeline.reverse()
  }
}
