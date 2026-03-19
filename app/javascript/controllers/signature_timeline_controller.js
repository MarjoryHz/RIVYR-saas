import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popup"]

  show() {
    if (!this.hasPopupTarget) return

    const popup = this.popupTarget
    popup.classList.remove("hidden", "left-0", "right-0", "top-full", "bottom-full", "mt-2", "mb-2")
    popup.classList.add("left-0", "top-full", "mt-2")

    const popupRect = popup.getBoundingClientRect()
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight

    popup.classList.remove("left-0", "right-0")
    if (popupRect.right > viewportWidth - 16) {
      popup.classList.add("right-0")
    } else {
      popup.classList.add("left-0")
    }

    popup.classList.remove("top-full", "bottom-full", "mt-2", "mb-2")
    if (popupRect.bottom > viewportHeight - 16 && popupRect.top > popupRect.height + 16) {
      popup.classList.add("bottom-full", "mb-2")
    } else {
      popup.classList.add("top-full", "mt-2")
    }
  }

  hide() {
    if (!this.hasPopupTarget) return

    this.popupTarget.classList.add("hidden")
  }
}
