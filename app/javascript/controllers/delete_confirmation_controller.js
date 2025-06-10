import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "payeeName", "cancelButton"]

  connect() {
    // Optional: Add any initialization code here if needed
  }

  open(event) {
    const id = event.currentTarget.getAttribute('data-id');
    const name = event.currentTarget.getAttribute('data-name');

    // Dispatch custom event to be handled by delete_modal_controller
    const deleteEvent = new CustomEvent('delete-payee', {
      bubbles: true,
      detail: {
        id: id,
        name: name
      }
    });

    document.dispatchEvent(deleteEvent);
  }
}
