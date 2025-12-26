import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="set-client-rate"
export default class extends Controller {
  static targets = ["clientSelect", "rateField"]

  connect() {
  }

  setRate() {
    const selectedOption = this.clientSelectTarget.options[this.clientSelectTarget.selectedIndex]
    const rateCents = selectedOption.dataset.rate

    if (!rateCents) {
      this.rateFieldTarget.value = "60.00"
      return
    }

    // Convert cents to pounds and format as currency
    this.rateFieldTarget.value = (parseInt(rateCents) / 100.0).toFixed(2)
  }
}

