import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "backdrop", "dialog", "heading", "service", "date", "loading",
    "message", "error", "results", "fallback", "fallbackLink", "retry"
  ]

  static values = {
    optionsUrl: String,
    nextUrl: String,
    bookingUrl: String,
    fallbackUrl: String
  }

  connect() {
    this.optionsLoaded = false
    this.requestNumber = 0
    this.bodyWasLocked = false
    this.dismiss()
    this.fallbackLinkTarget.href = this.fallbackUrlValue
  }

  async open(event) {
    event.preventDefault()
    this.trigger = event.currentTarget
    this.trigger.setAttribute("aria-expanded", "true")
    this.bodyWasLocked = document.body.classList.contains("overflow-hidden")
    document.body.classList.add("overflow-hidden")
    this.backdropTarget.classList.remove("hidden")
    this.backdropTarget.classList.add("flex")
    this.backdropTarget.setAttribute("aria-hidden", "false")

    window.requestAnimationFrame(() => this.headingTarget.focus({ preventScroll: true }))
    if (!this.optionsLoaded) await this.loadOptions()
  }

  dismiss() {
    if (!this.hasBackdropTarget) return

    this.backdropTarget.classList.add("hidden")
    this.backdropTarget.classList.remove("flex")
    this.backdropTarget.setAttribute("aria-hidden", "true")
    if (!this.bodyWasLocked) document.body.classList.remove("overflow-hidden")
    this.trigger?.setAttribute("aria-expanded", "false")
  }

  closeOnBackdrop(event) {
    if (event.target === this.backdropTarget) this.dismiss()
  }

  keydown(event) {
    if (this.backdropTarget.classList.contains("hidden")) return
    if (event.key === "Escape") {
      this.dismiss()
      return
    }
    if (event.key !== "Tab") return

    const focusable = Array.from(this.dialogTarget.querySelectorAll(
      'button:not([disabled]), a[href], select:not([disabled]), input:not([disabled]), [tabindex]:not([tabindex="-1"])'
    ))
    if (focusable.length === 0) return

    const first = focusable[0]
    const last = focusable[focusable.length - 1]
    if (event.shiftKey && document.activeElement === first) {
      event.preventDefault()
      last.focus()
    } else if (!event.shiftKey && document.activeElement === last) {
      event.preventDefault()
      first.focus()
    }
  }

  async loadOptions() {
    this.setBusy(true)
    this.hideError()
    this.retryTarget.classList.add("hidden")
    this.messageTarget.textContent = "Loading services..."

    try {
      const response = await fetch(this.optionsUrlValue, { headers: { Accept: "application/json" } })
      const data = await response.json()
      if (!response.ok) throw new Error(data.error || "Online availability is unavailable right now.")

      this.renderServices(data.services || [])
      this.optionsLoaded = true
      this.messageTarget.textContent = data.services?.length
        ? "Choose a service to see the next openings."
        : "Online booking is being set up."
      this.fallbackTarget.classList.toggle("hidden", Boolean(data.services?.length))
    } catch (error) {
      this.showError(error.message)
    } finally {
      this.setBusy(false)
    }
  }

  renderServices(services) {
    this.serviceTarget.replaceChildren()
    const placeholder = document.createElement("option")
    placeholder.value = ""
    placeholder.textContent = "Choose a service"
    this.serviceTarget.appendChild(placeholder)

    services.forEach((service) => {
      const option = document.createElement("option")
      option.value = service.id
      option.textContent = [service.name, service.price].filter(Boolean).join(" · ")
      option.dataset.version = service.version || ""
      option.dataset.name = service.name || ""
      this.serviceTarget.appendChild(option)
    })
  }

  serviceChanged() {
    this.loadNextAvailability()
  }

  dateChanged() {
    if (this.selectedService) this.loadNextAvailability()
  }

  async loadNextAvailability() {
    const service = this.selectedService
    if (!service) {
      this.resultsTarget.classList.add("hidden")
      this.messageTarget.textContent = "Choose a service to see the next openings."
      return
    }

    const requestNumber = ++this.requestNumber
    this.setBusy(true)
    this.hideError()
    this.resultsTarget.classList.add("hidden")
    this.messageTarget.textContent = ""

    const params = new URLSearchParams({ service_id: service.id, date: this.dateTarget.value, days: "14" })
    try {
      const response = await fetch(`${this.nextUrlValue}?${params}`, { headers: { Accept: "application/json" } })
      const data = await response.json()
      if (requestNumber !== this.requestNumber) return
      if (!response.ok) throw new Error(data.error || "Couldn't load availability.")
      this.renderResults(data, service)
    } catch (error) {
      if (requestNumber === this.requestNumber) this.showError(error.message)
    } finally {
      if (requestNumber === this.requestNumber) this.setBusy(false)
    }
  }

  renderResults(data, service) {
    this.resultsTarget.replaceChildren()
    const rows = data.technicians || []
    if (data.anyone_next_slot) rows.push({ name: "Anyone available", next_slot: data.anyone_next_slot })

    if (rows.length === 0 || !rows.some((row) => row.next_slot)) {
      this.messageTarget.textContent = "No openings found in the next 14 days. Try another service, date, or call us."
      this.resultsTarget.classList.add("hidden")
      return
    }

    rows.forEach((technician) => this.resultsTarget.appendChild(this.resultRow(technician, service)))
    this.resultsTarget.classList.remove("hidden")
  }

  resultRow(technician, service) {
    const row = document.createElement("div")
    row.className = "flex flex-col gap-3 rounded-2xl border border-cream-200 bg-white/80 p-4 sm:flex-row sm:items-center sm:justify-between"

    const details = document.createElement("div")
    const name = document.createElement("p")
    name.className = "font-medium text-warm-gray-800"
    name.textContent = technician.name
    details.appendChild(name)

    const availability = document.createElement("p")
    availability.className = "mt-1 text-sm text-warm-gray-600"
    availability.textContent = technician.next_slot
      ? `Next opening: ${this.formatSlot(technician.next_slot.start_at)}`
      : "No opening in the next 14 days"
    details.appendChild(availability)
    row.appendChild(details)

    if (technician.next_slot) {
      const link = document.createElement("a")
      link.className = "inline-flex shrink-0 items-center justify-center gap-2 rounded-full bg-terracotta-700 px-4 py-2 text-sm font-medium text-cream-50 transition-colors hover:bg-terracotta-800"
      link.href = this.bookingHref(service, technician)
      link.textContent = "See times"
      row.appendChild(link)
    }

    return row
  }

  bookingHref(service, technician) {
    const url = new URL(this.bookingUrlValue, window.location.origin)
    url.searchParams.set("service_id", service.id)
    url.searchParams.set("service_version", service.version || "")
    url.searchParams.set("date", this.dateTarget.value)
    if (technician.id) url.searchParams.set("team_member_id", technician.id)
    return url.toString()
  }

  get selectedService() {
    const option = this.serviceTarget.selectedOptions[0]
    if (!option?.value) return null
    return { id: option.value, version: option.dataset.version, name: option.dataset.name }
  }

  formatSlot(iso) {
    return new Date(iso).toLocaleString([], {
      weekday: "short", month: "short", day: "numeric", hour: "numeric", minute: "2-digit"
    })
  }

  setBusy(busy) {
    this.loadingTarget.classList.toggle("hidden", !busy)
    if (busy) this.resultsTarget.classList.add("hidden")
  }

  showError(message) {
    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
    this.fallbackTarget.classList.remove("hidden")
    this.retryTarget.classList.remove("hidden")
  }

  hideError() {
    this.errorTarget.classList.add("hidden")
  }
}
