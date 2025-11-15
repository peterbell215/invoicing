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
      this.rateFieldTarget.value = "£0.00"
      return
    }

    // Convert cents to pounds and format as currency
    const ratePounds = parseInt(rateCents) / 100
    const formattedRate = new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'GBP'
    }).format(ratePounds)

    this.rateFieldTarget.value = formattedRate
  }
}

