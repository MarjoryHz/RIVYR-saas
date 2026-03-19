import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    acknowledgeUrl: String,
    applicationIds: Array
  }

  connect() {
    const modal = this.element.querySelector("#dashboard_admin_updates_modal")
    if (modal && !modal.open) {
      requestAnimationFrame(() => modal.showModal())
    }

    this.acknowledge()
  }

  acknowledge() {
    if (!this.hasAcknowledgeUrlValue || this.applicationIdsValue.length === 0) return

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    if (!token) return

    fetch(this.acknowledgeUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        "Accept": "application/json"
      },
      credentials: "same-origin",
      body: JSON.stringify({ application_ids: this.applicationIdsValue })
    })
  }
}
