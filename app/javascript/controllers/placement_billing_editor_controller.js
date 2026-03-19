import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fieldLabel", "fileInput", "remoteInput"]

  connect() {
    this.activeDocumentKey = null
  }

  toggleField(event) {
    const field = event.currentTarget.closest("[data-editable-field]")
    if (!field) return

    field.querySelector("[data-field-display]")?.classList.add("hidden")
    field.querySelector("[data-field-editor]")?.classList.remove("hidden")
    field.querySelector("input, textarea")?.focus()
  }

  saveField(event) {
    const field = event.currentTarget.closest("[data-editable-field]")
    if (!field) return

    const input = field.querySelector("input, textarea")
    const value = input?.value?.trim()
    field.querySelector("[data-field-value]").textContent = value || "Non renseigné"
    field.querySelector("[data-field-display]")?.classList.remove("hidden")
    field.querySelector("[data-field-editor]")?.classList.add("hidden")
  }

  cancelField(event) {
    const field = event.currentTarget.closest("[data-editable-field]")
    if (!field) return

    const valueNode = field.querySelector("[data-field-value]")
    const input = field.querySelector("input, textarea")
    if (input && valueNode) input.value = valueNode.textContent.trim()
    field.querySelector("[data-field-display]")?.classList.remove("hidden")
    field.querySelector("[data-field-editor]")?.classList.add("hidden")
  }

  openDocumentModal(event) {
    this.activeDocumentKey = event.currentTarget.dataset.documentKey
    const label = event.currentTarget.dataset.documentLabel || "Document"
    this.fieldLabelTarget.textContent = label
    this.fileInputTarget.value = ""
    this.remoteInputTarget.value = ""
    this.element.querySelector("#placement-document-modal")?.showModal()
  }

  saveDocument() {
    if (!this.activeDocumentKey) return

    const fileName = this.fileInputTarget.files[0]?.name
    const remoteValue = this.remoteInputTarget.value.trim()
    const remoteName = remoteValue ? remoteValue.split("/").pop() : ""
    const chosenName = fileName || remoteName || "Aucun document sélectionné"
    const documentNode = this.element.querySelector(`[data-document-name="${this.activeDocumentKey}"]`)
    const badgeNode = this.element.querySelector(`[data-document-badge="${this.activeDocumentKey}"]`)

    if (documentNode) documentNode.textContent = chosenName
    if (badgeNode) {
      badgeNode.textContent = chosenName == "Aucun document sélectionné" ? "À charger" : "Chargé"
      badgeNode.className = chosenName == "Aucun document sélectionné" ? badgeNode.dataset.idleClass : badgeNode.dataset.loadedClass
    }

    this.element.querySelector("#placement-document-modal")?.close()
  }
}
