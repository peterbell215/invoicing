import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "name"]
  static values = { entity: String }

  connect() {
    // Listen for the custom event from delete_confirmation_controller
    document.addEventListener('delete-payee', this.handleDeleteRequest.bind(this));
  }

  disconnect() {
    // Clean up event listener when controller is disconnected
    document.removeEventListener('delete-payee', this.handleDeleteRequest.bind(this));
  }

  handleDeleteRequest(event) {
    const { id, name } = event.detail;

    // Set the payee name in the dialog
    this.nameTarget.textContent = name;

    // Set the form action
    this.formTarget.action = `/${this.entityValue}s/${id}`;

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
