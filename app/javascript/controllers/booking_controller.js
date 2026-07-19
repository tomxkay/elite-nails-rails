import { Controller } from "@hotwired/stimulus"

// Drives the native booking wizard (/book): loads open slots for the chosen
// service/tech/day from the server (which proxies Square), then submits the
// booking. Server endpoints live in BookingsController.
export default class extends Controller {
  static targets = [
    "service", "staff", "date", "slots", "slotsHint",
    "form", "name", "phone", "email", "note",
    "summary", "error", "submitBtn", "confirmation", "confirmationDetails"
  ]

  static values = {
    availabilityUrl: String,
    createUrl: String
  }

  connect() {
    this.selectedSlot = null
  }

  serviceChanged() {
    this.loadSlots()
  }

  get selectedService() {
    const radio = this.serviceTargets.find((el) => el.checked)
    if (!radio) return null
    return { id: radio.value, version: radio.dataset.version, name: radio.dataset.name }
  }

  async loadSlots() {
    const service = this.selectedService
    this.selectSlot(null)
    if (!service) {
      this.slotsHintTarget.textContent = "Select a service above to see open times."
      this.slotsTarget.innerHTML = ""
      return
    }

    this.slotsHintTarget.textContent = "Checking open times…"
    this.slotsTarget.innerHTML = ""

    const params = new URLSearchParams({
      service_id: service.id,
      service_version: service.version || "",
      date: this.dateTarget.value
    })
    if (this.staffTarget.value) params.set("team_member_id", this.staffTarget.value)

    try {
      const response = await fetch(`${this.availabilityUrlValue}?${params}`, {
        headers: { Accept: "application/json" }
      })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Couldn't load times")
      this.renderSlots(data.slots)
    } catch (error) {
      this.slotsHintTarget.textContent = `${error.message}. Please try another day or call us.`
    }
  }

  renderSlots(slots) {
    this.slotsTarget.innerHTML = ""
    if (!slots || slots.length === 0) {
      this.slotsHintTarget.textContent = "No open times that day — try another day or technician."
      return
    }

    this.slotsHintTarget.textContent = "Pick a time:"
    slots.forEach((slot) => {
      const button = document.createElement("button")
      button.type = "button"
      button.className = "rounded-full border border-cream-200 px-4 py-2 text-sm text-warm-gray-700 transition-colors hover:border-terracotta-400 data-selected:bg-terracotta-500 data-selected:text-cream-50 data-selected:border-terracotta-500"
      button.textContent = this.formatTime(slot.start_at)
      button.addEventListener("click", () => this.selectSlot(slot, button))
      this.slotsTarget.appendChild(button)
    })
  }

  selectSlot(slot, button = null) {
    this.selectedSlot = slot
    this.slotsTarget.querySelectorAll("button").forEach((el) => delete el.dataset.selected)
    if (button) button.dataset.selected = "true"
    this.updateSummary()
  }

  updateSummary() {
    const service = this.selectedService
    if (service && this.selectedSlot) {
      this.summaryTarget.textContent =
        `Booking: ${service.name} · ${this.formatDay(this.selectedSlot.start_at)} at ${this.formatTime(this.selectedSlot.start_at)}`
      this.submitBtnTarget.disabled = false
    } else {
      this.summaryTarget.textContent = ""
      this.submitBtnTarget.disabled = true
    }
  }

  async submit(event) {
    event.preventDefault()
    const service = this.selectedService
    if (!service || !this.selectedSlot) return

    this.hideError()
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = "Booking…"

    try {
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({
          service_id: service.id,
          service_version: service.version,
          start_at: this.selectedSlot.start_at,
          team_member_id: this.selectedSlot.team_member_id,
          name: this.nameTarget.value,
          phone: this.phoneTarget.value,
          email: this.emailTarget.value,
          note: this.noteTarget.value
        })
      })
      const data = await response.json()
      if (!response.ok || !data.ok) throw new Error(data.error || "Something went wrong")

      this.confirmationDetailsTarget.textContent =
        `${service.name} on ${this.formatDay(data.booking.start_at)} at ${this.formatTime(data.booking.start_at)}`
      this.confirmationTarget.classList.remove("hidden")
      this.confirmationTarget.scrollIntoView({ behavior: "smooth", block: "center" })
      this.formTarget.querySelectorAll("input, textarea, button, select").forEach((el) => (el.disabled = true))
    } catch (error) {
      this.showError(`${error.message}. The time may have just been taken — refresh the times and try again, or call us.`)
      this.submitBtnTarget.disabled = false
    } finally {
      this.submitBtnTarget.textContent = "Confirm booking"
    }
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }

  formatTime(iso) {
    return new Date(iso).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
  }

  formatDay(iso) {
    return new Date(iso).toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" })
  }
}
