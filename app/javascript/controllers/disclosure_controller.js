import { Controller } from "@hotwired/stimulus"

// Expands a description panel in place beneath its row.
//
// The open/closed state lives in `data-open` on the panel, not in JS-toggled
// classes: the height animation is a pure CSS `grid-template-rows: 0fr -> 1fr`
// transition (see .disclosure-panel in application.tailwind.css), so nothing
// here has to measure heights or fight layout. Reduced motion is handled in the
// stylesheet too.
export default class extends Controller {
  static targets = ["panel", "button"]

  toggle() {
    const open = this.panelTarget.dataset.open === "true"
    this.panelTarget.dataset.open = String(!open)
    this.buttonTarget.setAttribute("aria-expanded", String(!open))
  }
}
