import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  open(event) {
    const id = event.currentTarget.getAttribute('data-id');
    const name = event.currentTarget.getAttribute('data-name');

    // Dispatch custom event to be handled by send_modal_controller
    const sendEvent = new CustomEvent(`send-invoice`, {
      bubbles: true,
      detail: {
        id: id,
        name: name
      }
    });

    document.dispatchEvent(sendEvent);
  }
}
