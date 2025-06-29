import { Controller } from "@hotwired/stimulus"

// Manages the client selection checkboxes based on the "Apply to All" checkbox
export default class extends Controller {
  static targets = ["applyToAll", "clientCheckbox", "clientSelection"]

  connect() {
    // Initially set the state based on the "Apply to All" checkbox
    this.toggleClientSelection()
  }

  toggleClientSelection() {
    const applyToAll = this.applyToAllTarget.checked

    // Show/hide the client selection area
    this.clientSelectionTarget.style.display = applyToAll ? 'none' : 'block'

    // If "Apply to All" is checked, uncheck all client checkboxes
    if (applyToAll) {
      this.clientCheckboxTargets.forEach(checkbox => {
        checkbox.checked = false
      })
    }
  }
}
