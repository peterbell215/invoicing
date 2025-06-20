import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "total", "selectAll", "amountField"]

  connect() {
    // Set initial state to checked since all checkboxes start checked
    this.selectAllTarget.checked = true
    this.updateSelectAllState()
    this.updateTotal()
  }

  updateSelectAllState() {
    this.selectAllTarget.checked = this.checkboxTargets.every(cb => cb.checked)
  }

  toggleSelectAll() {
    const isChecked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
    })
    this.updateTotal()
  }

  toggleCheckbox() {
    // Update "select all" checkbox state
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    this.selectAllTarget.checked = allChecked
    
    this.updateTotal()
  }

  updateTotal() {
    let total = 0
    this.checkboxTargets.forEach(checkbox => {
      if (checkbox.checked) {
        // Get the fee from the corresponding row's last cell
        const row = checkbox.closest("tr")
        const feeCell = row.querySelector("td:last-child")
        // Extract numeric value from formatted money string (£xx.xx)
        const feeText = feeCell.textContent.trim()
        const feeValue = parseFloat(feeText.replace(/[^0-9.-]+/g, ""))
        total += feeValue
      }
    })
    
    // Format total as currency for display
    const formatter = new Intl.NumberFormat('en-GB', {
      style: 'currency',
      currency: 'GBP'
    })
    
    this.totalTarget.textContent = formatter.format(total)
    
    // Update the hidden field with the raw numeric value
    if (this.hasAmountFieldTarget) {
      this.amountFieldTarget.value = total.toFixed(2)
    }
  }
}
