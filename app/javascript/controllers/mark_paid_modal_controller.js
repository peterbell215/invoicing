import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "name"]

  connect() {
    this.boundHandler = this.handleMarkPaidRequest.bind(this);
    document.addEventListener('mark-paid-invoice', this.boundHandler);
  }

  disconnect() {
    document.removeEventListener('mark-paid-invoice', this.boundHandler);
  }

  handleMarkPaidRequest(event) {
    const { id, name } = event.detail;

    // Set the invoice name in the dialog
    this.nameTarget.textContent = name;

    // Set the form action to the invoice path for PUT request
    this.formTarget.action = `/invoices/${id}`;

    // Show the dialog
    this.dialogTarget.showModal();
  }

  close() {
    this.dialogTarget.close();
  }

  clickOutside(event) {
    if (event.target === this.dialogTarget) {
      this.dialogTarget.close();
    }
  }
}
