import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator", "tooltip"]
  static values = { rowId: String, changedRecently: Boolean }

  connect() {
    this.applyIndicatorState()
  }

  reveal() {
    if (!this.changedRecentlyValue || !this.hasIndicatorTarget || !this.hasTooltipTarget) return

    const tooltip = this.tooltipTarget
    tooltip.classList.remove("hidden", "left-0", "right-0", "top-full", "bottom-full", "mt-2", "mb-2")
    tooltip.classList.add("left-0", "top-full", "mt-2")

    const tooltipRect = tooltip.getBoundingClientRect()
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight

    tooltip.classList.remove("left-0", "right-0")
    if (tooltipRect.right > viewportWidth - 16) {
      tooltip.classList.add("right-0")
    } else {
      tooltip.classList.add("left-0")
    }

    tooltip.classList.remove("top-full", "bottom-full", "mt-2", "mb-2")
    if (tooltipRect.bottom > viewportHeight - 16 && tooltipRect.top > tooltipRect.height + 16) {
      tooltip.classList.add("bottom-full", "mb-2")
    } else {
      tooltip.classList.add("top-full", "mt-2")
    }

    window.sessionStorage.setItem(this.storageKey(), "1")
    this.applyIndicatorState()
  }

  hide() {
    this.tooltipTarget?.classList.add("hidden")
  }

  markSeen() {
    if (!this.changedRecentlyValue || !this.rowIdValue) return

    window.sessionStorage.setItem(this.storageKey(), "1")
    this.applyIndicatorState()
  }

  seen() {
    if (!this.changedRecentlyValue || !this.rowIdValue) return false

    return window.sessionStorage.getItem(this.storageKey()) === "1"
  }

  applyIndicatorState() {
    if (!this.hasIndicatorTarget) return

    const indicator = this.indicatorTarget
    indicator.classList.remove(
      "border-[#dec4cd]",
      "border-transparent",
      "bg-white",
      "bg-[#ff8a1f]",
      "shadow-[0_0_0_5px_rgba(255,138,31,0.18)]",
      "bg-[#ead6dd]"
    )

    if (!this.changedRecentlyValue) {
      indicator.classList.add("border-[#dec4cd]", "bg-white")
    } else if (this.seen()) {
      indicator.classList.add("border-transparent", "bg-[#ead6dd]")
    } else {
      indicator.classList.add("border-transparent", "bg-[#ff8a1f]", "shadow-[0_0_0_5px_rgba(255,138,31,0.18)]")
    }
  }

  storageKey() {
    if (!this.rowIdValue) return "signature-change-seen:unknown"

    return `signature-change-seen:${this.rowIdValue}`
  }
}
