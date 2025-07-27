import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "name"]

  connect() {
    this.boundHandler = this.handleSendRequest.bind(this);
    document.addEventListener('send-invoice', this.boundHandler);
  }

  disconnect() {
    document.removeEventListener('send-invoice', this.boundHandler);
  }

  handleSendRequest(event) {
    const { id, name } = event.detail;

    // Set the invoice name in the dialog
    this.nameTarget.textContent = name;

    // Set the form action to the send_invoice path
    this.formTarget.action = `/invoices/${id}/send_invoice`;

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
