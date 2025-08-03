import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const id = event.currentTarget.getAttribute('data-id');
    const name = event.currentTarget.getAttribute('data-name');

    // Dispatch custom event to be handled by mark_paid_modal_controller
    const markPaidEvent = new CustomEvent(`mark-paid-invoice`, {
      bubbles: true,
      detail: {
        id: id,
        name: name
      }
    });

    document.dispatchEvent(markPaidEvent);
  }
}
