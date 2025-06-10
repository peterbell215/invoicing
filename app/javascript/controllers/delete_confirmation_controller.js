import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "form", "payeeName", "cancelButton"]

  connect() {
    // Optional: Add any initialization code here if needed
  }

  open(event) {
    const payeeId = event.currentTarget.getAttribute('data-payee-id');
    const payeeName = event.currentTarget.getAttribute('data-payee-name');

    // Dispatch custom event to be handled by delete_modal_controller
    const deleteEvent = new CustomEvent('delete-payee', {
      bubbles: true,
      detail: {
        payeeId: payeeId,
        payeeName: payeeName
      }
    });

    document.dispatchEvent(deleteEvent);
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
