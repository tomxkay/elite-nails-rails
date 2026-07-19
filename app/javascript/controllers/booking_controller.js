import { Controller } from "@hotwired/stimulus"
import { trackEvent } from "../analytics"

// Drives the native booking wizard (/book): loads open slots for the chosen
// service/tech/day from the server (which proxies Square), then submits the
// booking. Server endpoints live in BookingsController.
export default class extends Controller {
  static targets = [
    "service", "staff", "date", "slots", "slotsHint",
    "form", "name", "phone", "email", "note", "honeypot",
    "summary", "error", "submitBtn", "wizard", "confirmation",
    "confirmationHeading", "confirmationService", "confirmationDate",
    "confirmationTechnicianRow", "confirmationTechnician"
  ]

  static values = {
    availabilityUrl: String,
    createUrl: String
  }

  connect() {
    this.selectedSlot = null
    this.selectedSlotKey = null
    this.idempotencyKey = this.newIdempotencyKey()

    if (this.selectedService) this.loadSlots()
  }

  serviceChanged() {
    trackEvent("service_selected", { service: this.selectedService?.name })
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
    const slotKey = slot ? [slot.start_at, slot.team_member_id, slot.service_variation_version].join("|") : null
    if (slotKey !== this.selectedSlotKey) {
      this.idempotencyKey = this.newIdempotencyKey()
      this.selectedSlotKey = slotKey
      if (slot) trackEvent("slot_selected", { service: this.selectedService?.name })
    }
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
          idempotency_key: this.idempotencyKey,
          name: this.nameTarget.value,
          phone: this.phoneTarget.value,
          email: this.emailTarget.value,
          note: this.noteTarget.value,
          website: this.hasHoneypotTarget ? this.honeypotTarget.value : ""
        })
      })
      const data = await response.json()
      if (!response.ok || !data.ok) throw new Error(data.error || "Something went wrong")
      if (!data.booking?.start_at) throw new Error("Your booking may have been created, but confirmation details are unavailable. Please call us before trying again.")

      this.confirmationServiceTarget.textContent = service.name
      this.confirmationDateTarget.textContent =
        `${this.formatDay(data.booking.start_at)} at ${this.formatTime(data.booking.start_at)}`

      const technician = this.technicianNameFor(this.selectedSlot)
      this.confirmationTechnicianTarget.textContent = technician
      this.confirmationTechnicianRowTarget.classList.toggle("hidden", !technician)

      this.formTarget.reset()
      this.serviceTargets.forEach((radio) => (radio.checked = false))
      this.selectedSlot = null
      this.selectedSlotKey = null
      this.idempotencyKey = this.newIdempotencyKey()
      this.wizardTarget.classList.add("hidden")
      this.wizardTarget.setAttribute("aria-hidden", "true")
      this.confirmationTarget.classList.remove("hidden")
      this.confirmationTarget.removeAttribute("aria-hidden")
      this.confirmationTarget.scrollIntoView({ behavior: "smooth", block: "center" })
      window.requestAnimationFrame(() => this.confirmationHeadingTarget.focus({ preventScroll: true }))
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

  technicianNameFor(slot) {
    if (!slot?.team_member_id) return ""

    const option = Array.from(this.staffTarget.options).find((candidate) => candidate.value === slot.team_member_id)
    return option?.textContent.trim() || ""
  }

  newIdempotencyKey() {
    if (window.crypto?.randomUUID) return window.crypto.randomUUID()
    return `${Date.now()}-${Math.random().toString(16).slice(2)}`
  }

  formatTime(iso) {
    return new Date(iso).toLocaleTimeString([], { hour: "numeric", minute: "2-digit" })
  }

  formatDay(iso) {
    return new Date(iso).toLocaleDateString([], { weekday: "long", month: "long", day: "numeric" })
  }
}
