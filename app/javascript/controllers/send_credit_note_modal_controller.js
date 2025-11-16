import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "name"]

  connect() {
    this.boundHandler = this.handleSendRequest.bind(this);
    document.addEventListener('send-credit-note', this.boundHandler);
  }

  disconnect() {
    document.removeEventListener('send-credit-note', this.boundHandler);
  }

  handleSendRequest(event) {
    const { id, name } = event.detail;

    // Set the credit note name in the dialog
    this.nameTarget.textContent = name;

    // Set the form action to the send_credit_note path
    this.formTarget.action = `/credit_notes/${id}/send_credit_note`;

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

