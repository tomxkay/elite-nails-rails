import { Controller } from "@hotwired/stimulus"

// Hides the logo label once scrolling starts to shrink the navbar height and tightens nav padding
export default class extends Controller {
  static targets = ["label", "navRow"]

  connect() {
    this.toggleLabel()
  }

  toggleLabel() {
    const scrolled = window.scrollY > 4

    this.labelTargets.forEach((label) => {
      label.classList.toggle("hidden", scrolled)
      label.classList.toggle("max-h-0", scrolled)
      label.classList.toggle("scale-95", scrolled)
      label.classList.toggle("max-h-10", !scrolled)
    })

    this.navRowTargets.forEach((row) => {
      row.classList.toggle("py-2", scrolled)
      row.classList.toggle("py-4", !scrolled)
    })
  }
}
