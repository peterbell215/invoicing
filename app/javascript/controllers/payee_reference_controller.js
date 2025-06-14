import { Controller } from "@hotwired/stimulus"

// Handles showing/hiding the payee reference field based on payee selection
export default class extends Controller {
  static targets = ["payeeSelect", "referenceField", "referenceInput", "form"]

  connect() {
    this.toggleReferenceField();
  }

  // Called when the payee select changes
  payeeChanged() {
    this.toggleReferenceField()
  }

  // Shows or hides the reference field based on payee selection
  toggleReferenceField() {
    const hasPayee = this.payeeSelectTarget.value !== ""

    if (hasPayee) {
      this.referenceFieldTarget.classList.remove("hidden")
    } else {
      this.referenceFieldTarget.classList.add("hidden")
    }
  }

  // Handle form submission
  handleSubmit(event) {
    // If no payee is selected (Self Paying), clear the reference field value
    if (this.payeeSelectTarget.value === "") {
      this.referenceInputTarget.value = ""
    }
  }
}
