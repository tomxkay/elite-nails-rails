import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "overlay", "panel"]

  connect() {
    this.close()
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.panelTarget.classList.remove("translate-x-full")
    this.buttonTarget.setAttribute("aria-expanded", "true")
    document.body.classList.add("overflow-hidden")

    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
    })
  }

  close() {
    if (!this.hasOverlayTarget || !this.hasPanelTarget || !this.hasButtonTarget) return

    this.overlayTarget.classList.add("opacity-0")
    this.panelTarget.classList.add("translate-x-full")
    this.buttonTarget.setAttribute("aria-expanded", "false")
    document.body.classList.remove("overflow-hidden")

    window.setTimeout(() => {
      if (this.panelTarget.classList.contains("translate-x-full")) {
        this.overlayTarget.classList.add("hidden")
      }
    }, 300)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }

  closeForDesktop() {
    if (window.innerWidth >= 1280) this.close()
  }
}
