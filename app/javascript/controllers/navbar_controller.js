import { Controller } from "@hotwired/stimulus"

// Hides the logo label once scrolling starts to shrink the navbar height and tightens nav padding
export default class extends Controller {
  static targets = ["label", "navRow"]

  connect() {
    this.toggleLabel()
    this.updateHeaderOffset()
    this.correctInitialHashOffset()
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

    this.updateHeaderOffset()
  }

  updateHeaderOffset() {
    const headerHeight = Math.ceil(this.element.getBoundingClientRect().height)
    const offset = headerHeight + 24

    document.documentElement.style.setProperty("--fixed-header-height", `${headerHeight}px`)
    document.documentElement.style.setProperty("--fixed-header-offset", `${offset}px`)
  }

  correctInitialHashOffset() {
    if (!window.location.hash) return

    const correctionDelays = [0, 100, 350]

    correctionDelays.forEach((delay) => {
      window.setTimeout(() => this.scrollCurrentHashIntoView(), delay)
    })
  }

  scrollCurrentHashIntoView() {
    const target = document.getElementById(decodeURIComponent(window.location.hash.slice(1)))
    if (!target) return

    window.scrollTo({
      top: Math.max(0, target.getBoundingClientRect().top + window.pageYOffset - this.currentHeaderOffset()),
      behavior: "auto"
    })
  }

  currentHeaderOffset() {
    return Math.ceil(this.element.getBoundingClientRect().height) + 24
  }
}
