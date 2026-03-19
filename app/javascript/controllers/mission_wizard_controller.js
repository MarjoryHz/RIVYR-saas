import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "step",
    "indicator",
    "indicatorBadge",
    "previousButton",
    "nextButton",
    "publishButton",
    "error",
    "companySearch",
    "contactSearch",
    "companyResult",
    "contactResult",
    "clientId",
    "contactId",
    "advantagesGroup",
    "customAdvantageCheckbox",
    "customAdvantageInput"
  ]

  connect() {
    this.currentStep = 0
    this.filterCompanies()
    this.filterContacts()
    this.toggleCustomAdvantage()
    this.render()
  }

  refresh() {
    this.toggleCustomAdvantage()
    this.render()
  }

  goToStep(event) {
    const targetStep = Number(event.currentTarget.dataset.stepIndex)
    if (Number.isNaN(targetStep)) return
    if (targetStep > this.currentStep && !this.validateStep(this.currentStep)) return

    this.currentStep = targetStep
    this.clearError()
    this.render()
  }

  next() {
    if (!this.validateStep(this.currentStep)) return

    this.currentStep += 1
    this.clearError()
    this.render()
  }

  previous() {
    if (this.currentStep === 0) return

    this.currentStep -= 1
    this.clearError()
    this.render()
  }

  handleSubmit(event) {
    const submitter = event.submitter
    if (!submitter || submitter.value === "draft") return

    if (!this.validateAllSteps()) {
      event.preventDefault()
    }
  }

  clearError() {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = ""
    this.errorTarget.classList.add("hidden")
  }

  filterCompanies() {
    const query = this.normalize(this.companySearchTarget?.value)

    this.companyResultTargets.forEach((item) => {
      const haystack = this.normalize(item.dataset.searchText || item.dataset.clientName || "")
      item.classList.toggle("hidden", query.length > 0 && !haystack.includes(query))
    })
  }

  selectCompany(event) {
    const button = event.currentTarget
    if (!button) return

    this.clientIdTarget.value = button.dataset.clientId || ""
    this.companySearchTarget.value = button.dataset.clientName || ""
    this.contactIdTarget.value = ""
    this.contactSearchTarget.value = ""
    this.contactSearchTarget.disabled = false
    this.contactSearchTarget.placeholder = "Commence à écrire le nom du contact..."
    this.filterCompanies()
    this.filterContacts()
    this.clearError()
  }

  filterContacts() {
    if (!this.hasContactSearchTarget || !this.hasClientIdTarget) return

    const clientId = this.clientIdTarget.value
    const query = this.normalize(this.contactSearchTarget.value)

    this.contactResultTargets.forEach((item) => {
      const sameClient = item.dataset.clientId === clientId
      const haystack = this.normalize(item.dataset.contactName || "")
      item.classList.toggle("hidden", !(sameClient && (query.length === 0 || haystack.includes(query))))
    })
  }

  selectContact(event) {
    const button = event.currentTarget
    if (!button) return

    this.contactIdTarget.value = button.dataset.contactId || ""
    this.contactSearchTarget.value = button.dataset.contactName || ""
    this.filterContacts()
    this.clearError()
  }

  toggleCustomAdvantage() {
    if (!this.hasCustomAdvantageInputTarget || !this.hasCustomAdvantageCheckboxTarget) return

    const checked = this.customAdvantageCheckboxTarget.checked
    this.customAdvantageInputTarget.classList.toggle("hidden", !checked)
    if (!checked) this.customAdvantageInputTarget.value = ""
  }

  validateAllSteps() {
    for (let index = 0; index < this.stepTargets.length; index += 1) {
      if (!this.validateStep(index)) {
        this.currentStep = index
        this.render()
        return false
      }
    }

    return true
  }

  validateStep(index) {
    const step = this.stepTargets[index]
    if (!step) return true

    const requiredFields = Array.from(step.querySelectorAll("[data-required='true']"))
    const missing = requiredFields.filter((field) => field.value.toString().trim() === "")

    if (index === 0) {
      if (!this.clientIdTarget.value || !this.contactIdTarget.value) {
        missing.push(this.clientIdTarget)
      }
    }

    if (index === 2) {
      const checkedAdvantages = this.advantagesGroupTarget.querySelectorAll("input[type='checkbox']:checked")
      if (checkedAdvantages.length === 0) {
        missing.push(this.advantagesGroupTarget)
      }

      if (this.hasCustomAdvantageCheckboxTarget && this.customAdvantageCheckboxTarget.checked && this.customAdvantageInputTarget.value.toString().trim() === "") {
        missing.push(this.customAdvantageInputTarget)
      }
    }

    if (missing.length === 0) {
      this.clearError()
      return true
    }

    this.showError(index)
    const firstInvalid = missing[0]
    if (firstInvalid?.focus) firstInvalid.focus()
    return false
  }

  showError(index) {
    if (!this.hasErrorTarget) return

    const messages = [
      "Complète l’entreprise et le contact client avant de continuer.",
      "Complète les informations de mission avant de continuer.",
      "Complète le package, le contenu du poste et sélectionne au moins un avantage."
    ]

    this.errorTarget.textContent = messages[index] || "Complète les champs obligatoires."
    this.errorTarget.classList.remove("hidden")
  }

  render() {
    this.stepTargets.forEach((step, index) => {
      step.classList.toggle("hidden", index !== this.currentStep)
    })

    this.indicatorTargets.forEach((indicator, index) => {
      const active = index === this.currentStep
      const done = this.stepCompleted(index)
      const badge = this.indicatorBadgeTargets[index]

      indicator.classList.toggle("bg-white/10", !active && !done)
      indicator.classList.toggle("border-[#f1d7df]", !active && !done)
      indicator.classList.toggle("bg-white", active)
      indicator.classList.toggle("border-[#ff8ee5]", active)
      indicator.classList.toggle("bg-[#fff1f6]", done && !active)
      indicator.classList.toggle("border-[#f3b6ca]", done)

      if (badge) {
        badge.classList.toggle("border-[#ead2dc]", !done)
        badge.classList.toggle("bg-white", !done)
        badge.classList.toggle("text-[#8b4452]", !done)
        badge.classList.toggle("border-[#f3b6ca]", done)
        badge.classList.toggle("bg-[#fff1f6]", done)
        badge.classList.toggle("text-[#ed0e64]", done)
        badge.innerHTML = done ? '<i class="fa-solid fa-check"></i>' : String(index + 1)
      }
    })

    this.previousButtonTarget.classList.toggle("hidden", this.currentStep === 0)
    this.nextButtonTarget.classList.toggle("hidden", this.currentStep === this.stepTargets.length - 1)
    this.publishButtonTarget.classList.toggle("hidden", this.currentStep !== this.stepTargets.length - 1)
    this.publishButtonTarget.classList.toggle("inline-flex", this.currentStep === this.stepTargets.length - 1)
  }

  normalize(value) {
    return (value || "")
      .toString()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .toLowerCase()
      .trim()
  }

  stepCompleted(index) {
    const step = this.stepTargets[index]
    if (!step) return false

    if (index === 0) {
      return Boolean(this.clientIdTarget.value && this.contactIdTarget.value)
    }

    const requiredFields = Array.from(step.querySelectorAll("[data-required='true']"))
    const fieldsCompleted = requiredFields.every((field) => field.value.toString().trim() !== "")
    if (!fieldsCompleted) return false

    if (index === 2) {
      const checkedAdvantages = this.advantagesGroupTarget.querySelectorAll("input[type='checkbox']:checked")
      if (checkedAdvantages.length === 0) return false
      if (this.hasCustomAdvantageCheckboxTarget && this.customAdvantageCheckboxTarget.checked) {
        return this.customAdvantageInputTarget.value.toString().trim() !== ""
      }
      return true
    }

    return true
  }
}
