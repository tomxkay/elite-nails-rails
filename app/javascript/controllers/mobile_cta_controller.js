import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.update = this.update.bind(this)
    window.addEventListener("scroll", this.update, { passive: true })
    window.addEventListener("resize", this.update)
    this.update()
  }

  disconnect() {
    window.removeEventListener("scroll", this.update)
    window.removeEventListener("resize", this.update)
  }

  update() {
    const hero = document.getElementById("home")
    const team = document.getElementById("team")
    const finalCta = document.getElementById("final-cta")
    const isMobile = window.matchMedia("(max-width: 1023px)").matches
    const threshold = hero ? hero.offsetTop + hero.offsetHeight - 80 : window.innerHeight
    const beforeFinalCta = finalCta ? window.scrollY < finalCta.offsetTop - window.innerHeight + 160 : true
    const beforeTeam = team ? window.scrollY < team.offsetTop - window.innerHeight + 160 : true
    const afterTeam = team ? window.scrollY > team.offsetTop + team.offsetHeight - 80 : true
    const awayFromTeam = beforeTeam || afterTeam
    const visible = isMobile && beforeFinalCta && awayFromTeam && window.scrollY >= threshold

    this.element.classList.toggle("opacity-0", !visible)
    this.element.classList.toggle("opacity-100", visible)
    this.element.classList.toggle("translate-y-4", !visible)
    this.element.classList.toggle("translate-y-0", visible)
    this.element.classList.toggle("pointer-events-none", !visible)
    this.element.classList.toggle("pointer-events-auto", visible)
  }
}
