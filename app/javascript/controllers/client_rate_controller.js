import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="client-rate"
export default class extends Controller {
  static targets = ["clientSelect", "rateField"]

  connect() {
    console.log("Client rate controller connected")
  }

  fetchClientRate() {
    const clientId = this.clientSelectTarget.value

    if (!clientId) {
      this.rateFieldTarget.value = "£0.00"
      return
    }

    fetch(`/clients/${clientId}/current_rate.json`, {
      headers: {
        "Accept": "application/json"
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error("Network response was not ok")
      }
      return response.json()
    })
    .then(data => {
      // Format the rate as currency
      const formattedRate = new Intl.NumberFormat('en-GB', {
        style: 'currency',
        currency: 'GBP'
      }).format(data.current_rate)

      this.rateFieldTarget.value = formattedRate
    })
    .catch(error => {
      console.error("Error fetching client rate:", error)
      this.rateFieldTarget.value = "Error fetching rate"
    })
  }
}
